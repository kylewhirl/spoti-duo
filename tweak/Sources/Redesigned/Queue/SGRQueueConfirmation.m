#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRGlass.h"
#import "Redesigned/Kit/SGRTokens.h"
#import "SGRQueueConfirmation.h"
#import <objc/message.h>
#import <dlfcn.h>

static char kPill, kGlass;
static id readObject(id object, NSString *name) {
    SEL selector = NSSelectorFromString(name);
    return [object respondsToSelector:selector] ? ((id (*)(id, SEL))objc_msgSend)(object, selector) : nil;
}

// Use native localized queue success strings, never a substring such as "queue"
// which could turn a failure/restriction message into a success-looking pill.
// ___sptloc_localized's C boundary takes NSStrings and returns an autoreleased
// NSString (SpotifyShared 9.1.94, 0x1ef8b0); resolve the symbol, never an address.
static BOOL queueSuccess(NSString *text) {
    if (![text isKindOfClass:NSString.class] || !text.length) return NO;
    typedef NSString *(*Localize)(NSString *, NSString *);
    static NSSet<NSString *> *successes;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // The native function asserts when its bundled localization assets are absent.
        if (![NSBundle.mainBundle URLForResource:@"SPTStrings" withExtension:@"bundle"]) return;
        Localize localize = (Localize)dlsym(RTLD_DEFAULT, "__sptloc_localized");
        if (!localize) return;
        NSMutableSet *values = [NSMutableSet set];
        // Native localized(_:in:) joins its namespace and key with a colon before
        // entering the C lookup. Both actual strings are verified in the fixture.
        for (NSString *key in @[@"Queue:sSongAddedToUpNext", @"Queue:sSongAddedToPlayNext"]) {
            NSString *value = localize(key, nil);
            if (value.length && ![value isEqualToString:key]) [values addObject:value];
        }
        successes = [values copy];
    });
    return [successes containsObject:text];
}

@interface SGRQueueConfirmationPill : UIView
@property(nonatomic, strong) UILabel *label;
@property(nonatomic, strong) UIImageView *glyph;
@property(nonatomic, strong) UIButton *openButton;
@property(nonatomic, weak) UIControl *nativeButton;
@property(nonatomic, weak) UIView *nativeContainer;
@property(nonatomic) CGFloat nativeAlpha;
@property(nonatomic) BOOL nativeAccessibilityHidden;
@property(nonatomic) BOOL forwarded;
@end

@implementation SGRQueueConfirmationPill
- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.accessibilityIdentifier = @"SGRQueueConfirmation";
    _label = [UILabel new];
    _label.numberOfLines = 1;
    _glyph = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"text.line.first.and.arrowtriangle.forward"]];
    _glyph.contentMode = UIViewContentModeCenter;
    _glyph.isAccessibilityElement = NO;
    _glyph.accessibilityElementsHidden = YES;
    _openButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_openButton addTarget:self action:@selector(openQueue) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_glyph];
    [self addSubview:_label];
    [self addSubview:_openButton];
    SGRegisterAppearanceView(self);
    // The owner, rather than a whole-window hook, responds to a committed appearance change.
    SGRegisterAppearanceRefresh(self, ^(id owner) { [[owner superview] setNeedsLayout]; });
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(accessibilityChanged:)
        name:UIAccessibilityReduceTransparencyStatusDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(accessibilityChanged:)
        name:UIContentSizeCategoryDidChangeNotification object:nil];
    return self;
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)accessibilityChanged:(NSNotification *)note { [self.superview setNeedsLayout]; }
- (void)openQueue {
    UIControl *button = self.nativeButton;
    if (self.forwarded || !button || !button.enabled || !self.window) return;
    // Keep the original target/action and view model: that path opens the actual
    // queue and tells Spotify's presenter to dismiss. One activation per snackbar.
    self.forwarded = YES;
    self.openButton.enabled = NO;
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
}
@end

static void restore(UIView *snackbar, SGRQueueConfirmationPill *pill) {
    if (!pill) return;
    pill.nativeContainer.alpha = pill.nativeAlpha;
    pill.nativeContainer.accessibilityElementsHidden = pill.nativeAccessibilityHidden;
    [pill removeFromSuperview];
    objc_setAssociatedObject(snackbar, &kPill, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void SGRReleaseQueueConfirmation(UIView *snackbar) {
    if (!NSThread.isMainThread) return;
    restore(snackbar, objc_getAssociatedObject(snackbar, &kPill));
}

void SGRRefreshQueueConfirmation(UIView *snackbar) {
    if (!NSThread.isMainThread) return;
    SGRQueueConfirmationPill *pill = objc_getAssociatedObject(snackbar, &kPill);
    UIView *content = readObject(snackbar, @"contentView");
    UIView *container = readObject(snackbar, @"containerView");
    NSString *text = readObject(content, @"text");
    UIControl *nativeButton = readObject(content, @"actionButton");
    NSString *buttonTitle = [nativeButton isKindOfClass:UIButton.class] ? ((UIButton *)nativeButton).currentTitle : nil;
    // Fail closed to native UI if a future Spotify version changes the view model
    // or the Open control. Errors, other messages, curation and undo stay untouched.
    BOOL known = SGRedesignedUI() && snackbar.window && [NSStringFromClass(content.class) isEqualToString:@"SPTSnackbarWithActionView"] &&
        [container isKindOfClass:UIView.class] && container != snackbar && [content isDescendantOfView:container] &&
        [nativeButton isKindOfClass:UIButton.class] && buttonTitle.length && queueSuccess(text);
    if (!known) { restore(snackbar, pill); return; }

    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline compatibleWithTraitCollection:snackbar.traitCollection];
    font = [UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold];
    CGFloat width = CGRectGetWidth(snackbar.bounds), height = CGRectGetHeight(snackbar.bounds);
    CGFloat labelWidth = ceil([text sizeWithAttributes:@{NSFontAttributeName:font}].width);
    CGFloat buttonWidth = MAX(44, ceil([buttonTitle sizeWithAttributes:@{NSFontAttributeName:font}].width) + 16);
    CGFloat glyphWidth = 21, gap = 10, padding = 16;
    CGFloat desired = padding * 2 + glyphWidth + gap + labelWidth + gap + buttonWidth;
    CGFloat pillHeight = MAX(48, ceil(font.lineHeight + 24));
    // Long translations and accessibility sizes fall back to Spotify's fully
    // laid-out original. Never truncate the message, shrink type or clip Open.
    if (width < desired || height < pillHeight - 4) { restore(snackbar, pill); return; }
    if (!pill || pill.nativeContainer != container || pill.nativeButton != nativeButton) {
        restore(snackbar, pill);
        pill = [[SGRQueueConfirmationPill alloc] initWithFrame:CGRectZero];
        pill.nativeContainer = container;
        pill.nativeButton = nativeButton;
        pill.nativeAlpha = container.alpha;
        pill.nativeAccessibilityHidden = container.accessibilityElementsHidden;
        objc_setAssociatedObject(snackbar, &kPill, pill, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [snackbar addSubview:pill];
    }
    pill.frame = CGRectMake((width - desired) / 2, (height - pillHeight) / 2, desired, pillHeight);
    pill.label.text = text;
    pill.label.font = font;
    pill.label.textColor = SGRPrimary();
    pill.glyph.tintColor = SGRPrimary();
    pill.glyph.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold];
    [pill.openButton setTitle:buttonTitle forState:UIControlStateNormal];
    pill.openButton.titleLabel.font = font;
    [pill.openButton setTitleColor:SGRPrimary() forState:UIControlStateNormal];
    pill.openButton.accessibilityLabel = nativeButton.accessibilityLabel ?: buttonTitle;
    pill.openButton.accessibilityHint = nativeButton.accessibilityHint;
    pill.openButton.enabled = nativeButton.enabled && !pill.forwarded;
    BOOL rtl = snackbar.effectiveUserInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
    CGFloat glyphX = padding, labelX = padding + glyphWidth + gap, buttonX = desired - padding - buttonWidth;
    if (rtl) { glyphX = desired - padding - glyphWidth; labelX = desired - labelX - labelWidth; buttonX = padding; }
    pill.glyph.frame = CGRectMake(glyphX, 0, glyphWidth, pillHeight);
    pill.label.frame = CGRectMake(labelX, 0, labelWidth, pillHeight);
    pill.openButton.frame = CGRectMake(buttonX, 0, buttonWidth, pillHeight);
    SGRGlassCapsuleInside(pill, &kGlass, pill.bounds.size, NO);
    // Only the proven native content is concealed, never an Encore stack member.
    // Keep it bound and alive so its original action/lifetime remain authoritative.
    container.alpha = 0;
    container.accessibilityElementsHidden = YES;
    [snackbar bringSubviewToFront:pill];
}
