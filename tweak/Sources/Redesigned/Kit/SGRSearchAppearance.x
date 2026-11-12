// Spotify 9.1.94: Search_FeatureImpl.HeaderViewController owns Search_ECMKit's
// SearchBarContainer (UITextFieldDelegate, textField ivar) and FilterChipView.
// FilterChipView inherits EncoreConsumerMobile_BaseKit.ChipView, whose containerView
// and backgroundEffectView are proven in objc-9.1.94.txt. Reprise's SearchBarView is
// a UIVisualEffectView. Header loadView/viewDidLoad/viewWillAppear:/traitCollectionDidChange:
// are present in the binary. All remaining hooks below are public UIKit selectors.
// Scope is the header only: no results/artwork scan, replacement input or guessed colors.
#import "Core/SGCore.h"
#import "SGRSearchAppearance.h"
#import "SGRNativeSurface.h"
#import "SGRTokens.h"

static char kHeader, kRoot, kEffect, kInput, kButton;
static NSUInteger applying;
static BOOL active(void) { return NSThread.isMainThread && SGRedesignedUI(); }
static BOOL withinHeader(UIView *view) {
    for (UIView *v=view;v;v=v.superview) {
        if ([v isKindOfClass:UIImageView.class] || [v.accessibilityIdentifier isEqualToString:@"Encore.ImageView"]) return NO;
        if (objc_getAssociatedObject(v,&kRoot)) return YES;
    }
    return NO;
}
BOOL SGRSearchOwnsEffect(UIView *view) {
    return active() && [view isKindOfClass:UIVisualEffectView.class] && withinHeader(view);
}
static id value(id object) { return object==NSNull.null?nil:object; }
static NSMutableDictionary *record(UIView *view, const void *key) { return objc_getAssociatedObject(view,key); }
static void refreshEffect(UIVisualEffectView *view) {
    NSMutableDictionary *saved=record(view,&kEffect);
    if (!SGRSearchOwnsEffect(view)) {
        if (!saved) return;
        objc_setAssociatedObject(view,&kEffect,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGUnregisterAppearanceView(view);SGUnregisterAppearanceRefresh(view);
        applying++;view.effect=value(saved[@"source"]);view.overrideUserInterfaceStyle=[saved[@"style"] integerValue];applying--;
        return;
    }
    if (!saved) {
        saved=[@{@"source":view.effect?:NSNull.null,@"style":@(view.overrideUserInterfaceStyle),
                 @"adaptive":[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]} mutableCopy];
        objc_setAssociatedObject(view,&kEffect,saved,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGRegisterAppearanceRefresh(view,^(id owner) { refreshEffect(owner); });
    }
    UIVisualEffect *source=value(saved[@"source"]);
    // Explicit dark/light legacy blurs cannot adapt from traits alone. Dark restores the
    // exact latest native object; Liquid Glass keeps its native material in either mode.
    UIVisualEffect *target=SGRedesignLightAppearance() && [source isKindOfClass:UIBlurEffect.class] ? saved[@"adaptive"] : source;
    applying++;
    view.overrideUserInterfaceStyle=SGRedesignAppearanceStyle();
    if (view.effect!=target) view.effect=target;
    if (@available(iOS 17.0,*)) [view updateTraitsIfNeeded];
    applying--;
}
static void refreshInput(UITextField *field) {
    NSMutableDictionary *saved=record(field,&kInput);
    if (!withinHeader(field)) {
        if (!saved) return;
        objc_setAssociatedObject(field,&kInput,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGUnregisterAppearanceRefresh(field);
        applying++;field.textColor=value(saved[@"ink"]);field.keyboardAppearance=[saved[@"keyboard"] integerValue];applying--;
        return;
    }
    if (!saved) {
        saved=[@{@"ink":field.textColor?:NSNull.null,@"keyboard":@(field.keyboardAppearance)} mutableCopy];
        objc_setAssociatedObject(field,&kInput,saved,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGRegisterAppearanceRefresh(field,^(id owner) { refreshInput(owner); });
    }
    // This is the native search input's explicit primary-ink role. Do not replace its
    // attributedText, placeholder, selection, delegate, clear button or keyboard session.
    applying++;field.textColor=[SGRPrimary() resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:SGRedesignAppearanceStyle()]];
    field.keyboardAppearance=SGRedesignLightAppearance()?UIKeyboardAppearanceLight:UIKeyboardAppearanceDark;
    applying--;
}
void SGRRefreshSearchNode(UIView *view) {
    if (!active() || applying) return;
    if ([view isKindOfClass:UIVisualEffectView.class]) refreshEffect((id)view);
    if ([view isKindOfClass:UITextField.class]) refreshInput((id)view);
    if ([view isKindOfClass:UIButton.class]) {
        if (!withinHeader(view)) objc_setAssociatedObject(view,&kButton,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        else if (!objc_getAssociatedObject(view,&kButton)) {
            // Cancel may have its native normal-state color before the header is registered.
            // Bind that current state through the existing adapter, so the first live Dark
            // transition cannot have UIKit repaint an old black title after the label pass.
            objc_setAssociatedObject(view,&kButton,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UIButton *button=(id)view;UIColor *ink=[button titleColorForState:UIControlStateNormal];
            if (ink) [button setTitleColor:ink forState:UIControlStateNormal];
        }
    }
}
void SGRApplySearchAppearance(UIViewController *header) {
    if (!active() || !header.viewIfLoaded) return;
    objc_setAssociatedObject(header,&kHeader,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(header.view,&kRoot,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    SGRegisterAppearanceController(header);
    // The search header is an explicit base surface, including an AMOLED-black
    // header retained from Dark. The adapter's insertion/transition walk
    // calls SGRRefreshSearchNode before processing ink inside each scoped effect.
    SGRApplyNativeLightSurface(header.view,YES);
}

%group SGRSearchAppearanceHooks
%hook _TtC18Search_FeatureImpl20HeaderViewController
- (void)viewDidLoad { %orig;SGRApplySearchAppearance((id)self); }
- (void)viewWillAppear:(BOOL)animated { %orig;SGRApplySearchAppearance((id)self); }
%end
%hook UIViewController
- (void)setOverrideUserInterfaceStyle:(UIUserInterfaceStyle)style {
    %orig(active() && objc_getAssociatedObject(self,&kHeader)?SGRedesignAppearanceStyle():style);
}
%end
%hook UIView
- (void)setOverrideUserInterfaceStyle:(UIUserInterfaceStyle)style {
    if (!applying && active()) {
        NSMutableDictionary *saved=record(self,&kEffect);
        if (saved && SGRSearchOwnsEffect(self)) saved[@"style"]=@(style);
        if (objc_getAssociatedObject(self,&kRoot) || (saved && SGRSearchOwnsEffect(self))) style=SGRedesignAppearanceStyle();
    }
    %orig(style);
}
%end
%hook UIVisualEffectView
- (void)setEffect:(UIVisualEffect *)effect {
    if (!active() || applying || !record(self,&kEffect)) { %orig;return; }
    if (!SGRSearchOwnsEffect(self)) { refreshEffect(self);%orig;return; }
    NSMutableDictionary *saved=record(self,&kEffect);saved[@"source"]=effect?:NSNull.null;
    %orig(SGRedesignLightAppearance() && [effect isKindOfClass:UIBlurEffect.class]?saved[@"adaptive"]:effect);
}
- (void)didMoveToSuperview {
    %orig;if (!active() || applying) return;
    refreshEffect(self);SGRRefreshNativeSurfaceSubtree(self);
}
%end
%hook UITextField
- (void)setTextColor:(UIColor *)color {
    if (!active() || applying || !record(self,&kInput)) { %orig;return; }
    if (!withinHeader(self)) { refreshInput(self);%orig;return; }
    record(self,&kInput)[@"ink"]=color?:NSNull.null;%orig([SGRPrimary() resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:SGRedesignAppearanceStyle()]]);
}
- (void)setKeyboardAppearance:(UIKeyboardAppearance)appearance {
    if (!active() || applying || !record(self,&kInput)) { %orig;return; }
    if (!withinHeader(self)) { refreshInput(self);%orig;return; }
    record(self,&kInput)[@"keyboard"]=@(appearance);
    %orig(SGRedesignLightAppearance()?UIKeyboardAppearanceLight:UIKeyboardAppearanceDark);
}
%end
%end
%ctor { if (!SGRedesignedUI()) return;%init(SGRSearchAppearanceHooks); }
