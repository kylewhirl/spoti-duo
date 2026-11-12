// Spotify 9.1.94 LimitedExperienceIndicatorBar is the native Slow connection/offline
// band. Binary proves updateConstraints/safeAreaInsetsDidChange/traitCollectionDidChange:.
// Cached final-upgrade-preserved/library-initial.json proves BackgroundContainer is its
// direct child, pinned by leading/trailing constraints, and both native message labels
// are pinned inside that container. Narrow those constraints, not the outer bar or its
// height/bottom safe-area reservation. No status text, timer, action or model is replaced.
#import "Core/SGCore.h"
#import "SGRConnectionBar.h"
#import "SGRBarGeometry.h"
#import "Core/SGAppearance.h"
#import "SGRTokens.h"

@interface SGRConnectionBarState : NSObject
@property(nonatomic,weak) UIView *container;
@property(nonatomic,weak) NSLayoutConstraint *leading;
@property(nonatomic,weak) NSLayoutConstraint *trailing;
@property(nonatomic) CGFloat nativeLeading, nativeTrailing, emittedLeading, emittedTrailing;
@property(nonatomic,strong) UIColor *nativeBackground;
@property(nonatomic) CGRect lane;
@property(nonatomic,strong) NSMapTable<UIView *, NSDictionary *> *paints;
@end
@implementation SGRConnectionBarState
@end
static char kConnectionBar;
static NSUInteger applying;
static BOOL enabled(void) { return NSThread.isMainThread && SGRedesignedUI(); }
static BOOL finiteRect(CGRect rect) {
    return isfinite(rect.origin.x) && isfinite(rect.origin.y) &&
        isfinite(rect.size.width) && isfinite(rect.size.height);
}
CGRect SGRConnectionBarContentLane(CGRect bounds, CGRect rail) {
    if (!finiteRect(bounds) || !finiteRect(rail) || CGRectIsEmpty(bounds) || CGRectIsNull(rail) || CGRectIsEmpty(rail) ||
        CGRectGetMinX(rail)>=CGRectGetMaxX(bounds) || CGRectGetMaxX(rail)<=CGRectGetMinX(bounds)) return bounds;
    CGFloat left=CGRectGetMinX(bounds)+8, right=CGRectGetMaxX(bounds)-8;
    if (CGRectGetMidX(rail)<CGRectGetMidX(bounds)) left=MAX(left,CGRectGetMaxX(rail)+8);
    else right=MIN(right,CGRectGetMinX(rail)-8);
    // Transient/tiny layout regions can leave no usable content lane. Preserve
    // the native layout rather than producing contradictory edge constraints.
    if (right-left<1) return bounds;
    return CGRectMake(left,CGRectGetMinY(bounds),right-left,CGRectGetHeight(bounds));
}
static void captureNativeConstants(SGRConnectionBarState *saved) {
    if (saved.leading.constant!=saved.emittedLeading) saved.nativeLeading=saved.leading.constant;
    if (saved.trailing.constant!=saved.emittedTrailing) saved.nativeTrailing=saved.trailing.constant;
}
// Only native connection-message descendants are touched. Keep original colors so
// a removed/reused band can leave the scope without carrying our palette with it.
static void paintNode(UIView *node, SGRConnectionBarState *saved) {
    NSDictionary *old=[saved.paints objectForKey:node];
    UIColor *background=node.backgroundColor;
    UIColor *ink=[node isKindOfClass:UILabel.class]?((UILabel *)node).textColor:nil;
    UIColor *nativeBackground=old && [background isEqual:old[@"emittedBackground"]]?old[@"background"]:background;
    UIColor *nativeInk=old && [ink isEqual:old[@"emittedInk"]]?old[@"ink"]:ink;
    BOOL light=SGRedesignLightAppearance();
    UIColor *fill=light?SGRNeutralField():nativeBackground, *text=light?SGRPrimary():nativeInk;
    NSMutableDictionary *record=[NSMutableDictionary new];
    if(nativeBackground)record[@"background"]=nativeBackground;
    if(nativeInk)record[@"ink"]=nativeInk;
    // Wrapper labels keep transparency; only the known background container is opaque.
    if(node==saved.container) { if(![node.backgroundColor isEqual:fill])node.backgroundColor=fill;if(fill)record[@"emittedBackground"]=fill; }
    if([node isKindOfClass:UILabel.class]) {
        UILabel *label=(UILabel *)node;
        NSAttributedString *source=label.attributedText;
        if(old && [source isEqual:old[@"emittedText"]])source=old[@"text"];
        if(source) {
            record[@"text"]=source;
            NSMutableAttributedString *painted=[source mutableCopy];
            if(light && painted.length)[painted addAttribute:NSForegroundColorAttributeName value:text range:NSMakeRange(0,painted.length)];
            if(![label.attributedText isEqual:painted])label.attributedText=painted;record[@"emittedText"]=painted;
        }
        if(![label.textColor isEqual:text])label.textColor=text;if(text)record[@"emittedInk"]=text;
    }
    [saved.paints setObject:record forKey:node];
    SGRegisterAppearanceView(node);
    for(UIView *child in node.subviews)paintNode(child,saved);
}
static void paintBar(UIView *bar) {
    SGRConnectionBarState *saved=objc_getAssociatedObject(bar,&kConnectionBar);
    if(!saved || applying || !enabled())return;
    applying++;
    UIColor *fill=SGRedesignLightAppearance()?SGRNeutralField():UIColor.clearColor;
    if(![bar.backgroundColor isEqual:fill])bar.backgroundColor=fill;
    paintNode(saved.container,saved);
    applying--;
}
static void restore(UIView *bar) {
    SGRConnectionBarState *saved=objc_getAssociatedObject(bar,&kConnectionBar);if(!saved)return;
    captureNativeConstants(saved);
    objc_setAssociatedObject(bar,&kConnectionBar,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    applying++;
    saved.leading.constant=saved.nativeLeading;saved.trailing.constant=saved.nativeTrailing;
    bar.backgroundColor=saved.nativeBackground;
    SGUnregisterAppearanceRefresh(bar);SGUnregisterAppearanceView(bar);
    for(UIView *node in saved.paints) {
        NSDictionary *paint=[saved.paints objectForKey:node];
        if([node.backgroundColor isEqual:paint[@"emittedBackground"]])node.backgroundColor=paint[@"background"];
        if([node isKindOfClass:UILabel.class] && [((UILabel *)node).textColor isEqual:paint[@"emittedInk"]])((UILabel *)node).textColor=paint[@"ink"];
        if([node isKindOfClass:UILabel.class] && [((UILabel *)node).attributedText isEqual:paint[@"emittedText"]])((UILabel *)node).attributedText=paint[@"text"];
        SGUnregisterAppearanceView(node);
    }
    applying--;
}
void SGRLayoutConnectionBarInRail(UIView *bar, CGRect rail) {
    if (!enabled() || applying || !bar) return;
    SGRConnectionBarState *saved=objc_getAssociatedObject(bar,&kConnectionBar);
    CGRect lane=SGRConnectionBarContentLane(bar.bounds,rail);
    if (!finiteRect(lane) || CGRectIsEmpty(lane) || CGRectEqualToRect(lane,bar.bounds) || !bar.superview) { restore(bar);return; }
    UIView *container=nil;
    for (UIView *child in bar.subviews)
        if ([child.accessibilityIdentifier isEqualToString:@"LimitedExperienceIndicatorBar.BackgroundContainer"]) { container=child;break; }
    if (saved && (saved.container!=container || saved.leading.firstItem!=container || saved.trailing.firstItem!=container || !saved.leading.active || !saved.trailing.active)) {
        restore(bar);saved=nil;
    }
    if (!saved) {
        NSLayoutConstraint *leading=nil,*trailing=nil;
        for (NSLayoutConstraint *constraint in bar.constraints) {
            if (!constraint.active || constraint.firstItem!=container || constraint.secondItem!=bar ||
                constraint.relation!=NSLayoutRelationEqual || constraint.multiplier!=1 || constraint.firstAttribute!=constraint.secondAttribute) continue;
            if (constraint.firstAttribute==NSLayoutAttributeLeading) leading=constraint;
            if (constraint.firstAttribute==NSLayoutAttributeTrailing) trailing=constraint;
        }
        if (!container || !leading || !trailing) return; // Unknown native layout fails closed.
        saved=[SGRConnectionBarState new];saved.paints=[NSMapTable weakToStrongObjectsMapTable];saved.container=container;saved.leading=leading;saved.trailing=trailing;
        saved.nativeLeading=saved.emittedLeading=leading.constant;saved.nativeTrailing=saved.emittedTrailing=trailing.constant;
        saved.nativeBackground=bar.backgroundColor;
        objc_setAssociatedObject(bar,&kConnectionBar,saved,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGRegisterAppearanceView(bar);
        SGRegisterAppearanceRefresh(bar,^(id owner){paintBar(owner);});
    }
    captureNativeConstants(saved);saved.lane=lane;
    CGFloat left=CGRectGetMinX(lane)-CGRectGetMinX(bar.bounds),right=CGRectGetMaxX(bar.bounds)-CGRectGetMaxX(lane);
    BOOL rtl=bar.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft;
    // Existing native horizontal padding may be larger; never remove it. UIKit's
    // directional anchor constants stay positive leading / negative trailing in RTL.
    CGFloat leading=MAX(saved.nativeLeading,rtl?right:left);
    CGFloat trailing=MIN(saved.nativeTrailing,-(rtl?left:right));
    if (!isfinite(leading) || !isfinite(trailing) || CGRectGetWidth(bar.bounds)-leading+trailing<1) {
        restore(bar);return;
    }
    saved.emittedLeading=leading;saved.emittedTrailing=trailing;
    applying++;
    if (saved.leading.constant!=saved.emittedLeading) saved.leading.constant=saved.emittedLeading;
    if (saved.trailing.constant!=saved.emittedTrailing) saved.trailing.constant=saved.emittedTrailing;
    
    applying--;
    paintBar(bar);
}
void SGRLayoutConnectionBar(UIView *bar) {
    SGRLayoutConnectionBarInRail(bar,SGRVerticalBarFrameIn(bar,SGRVerticalBarExtent));
}
%group SGRConnectionBarHooks
%hook _TtC44LimitedExperienceIndicator_MessageBarRuntime29LimitedExperienceIndicatorBar
- (void)updateConstraints { %orig;SGRLayoutConnectionBar((id)self); }
- (void)layoutSubviews { SGRLayoutConnectionBar((id)self);%orig;paintBar((id)self); }
- (void)safeAreaInsetsDidChange { %orig;SGRLayoutConnectionBar((id)self); }
- (void)traitCollectionDidChange:(UITraitCollection *)previous { %orig;SGRLayoutConnectionBar((id)self); }
- (void)didMoveToSuperview { %orig;SGRLayoutConnectionBar((id)self); }
- (void)setBackgroundColor:(UIColor *)color {
    SGRConnectionBarState *saved=objc_getAssociatedObject(self,&kConnectionBar);
    if (!applying && enabled() && saved) { saved.nativeBackground=color;color=SGRedesignLightAppearance()?SGRNeutralField():UIColor.clearColor; }
    %orig(color);
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    SGRConnectionBarState *saved=objc_getAssociatedObject(self,&kConnectionBar);
    if (saved && !CGRectContainsPoint(saved.lane,point)) return NO;
    return %orig;
}
%end
%end
%ctor { if (!SGRedesignedUI()) return;%init(SGRConnectionBarHooks); }
