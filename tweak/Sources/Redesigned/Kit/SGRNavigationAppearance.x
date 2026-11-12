// Spotify 9.1.94 evidence: SPNavigationController is a UINavigationController and
// SPNavigationBar is a UINavigationBar (objc-9.1.94.txt). Cached final-upgrade-preserved/
// player.json places UIKit's Back _UIButtonBarButton inside SPNavigationBar, beside
// the page subtree. In -[SPNavigationController viewDidLoad], 0x1090448c0 fetches its
// navigationBar and 0x1090448d4 sends setOverrideUserInterfaceStyle: with 2 (Dark).
// The native willShow/didShow selectors are at 0x109044cb0 / 0x109044b08. Layout and
// bar setters below are inherited public UIKit selectors. No private UIKit views,
// item/action/gesture replacements, appearance-object rewrites, or window sweeps.
#import "Core/SGCore.h"
#import "SGRNativeSurface.h"
#import "SGRNavigationAppearance.h"
#import "SGRTokens.h"

@interface SGRNavigationAppearanceState : NSObject
@property(nonatomic,weak) UINavigationController *navigation;
@property(nonatomic) UIUserInterfaceStyle nativeStyle;
@property(nonatomic) UIBarStyle nativeBarStyle;
@property(nonatomic,strong) UIColor *nativeTint;
@end
@implementation SGRNavigationAppearanceState
@end

static char kNavigationAppearance, kNativeTint;
static NSUInteger applying;
static BOOL enabled(void) { return NSThread.isMainThread && SGRedesignedUI(); }
static BOOL nativeClass(id object, NSString *name) {
    Class cls=NSClassFromString(name);
    return cls && [object isKindOfClass:cls];
}
static SGRNavigationAppearanceState *state(UINavigationBar *bar) {
    return objc_getAssociatedObject(bar,&kNavigationAppearance);
}
static UIColor *tint(SGRNavigationAppearanceState *saved) {
    // Dark keeps Spotify's source tint exactly, including inherited nil. Light's
    // primary color belongs only to this native chrome, never the page's media.
    return SGRedesignLightAppearance()?SGRPrimary():saved.nativeTint;
}
static UIBarStyle barStyle(SGRNavigationAppearanceState *saved) {
    return SGRedesignLightAppearance()?UIBarStyleDefault:saved.nativeBarStyle;
}
static void restore(UINavigationBar *bar) {
    SGRNavigationAppearanceState *saved=state(bar);
    if (!saved) return;
    SGUnregisterAppearanceRefresh(saved);
    objc_setAssociatedObject(bar,&kNavigationAppearance,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    applying++;
    bar.overrideUserInterfaceStyle=saved.nativeStyle;
    bar.barStyle=saved.nativeBarStyle;
    bar.tintColor=saved.nativeTint;
    if (@available(iOS 17.0,*)) [bar updateTraitsIfNeeded];
    [bar setNeedsLayout];
    applying--;
}
void SGRRefreshNativeNavigationAppearance(UINavigationController *navigation) {
    if (!enabled() || applying || !nativeClass(navigation,@"SPNavigationController") || !navigation.isViewLoaded) return;
    UINavigationBar *bar=navigation.navigationBar;
    if (!nativeClass(bar,@"SPNavigationBar")) return;
    UIViewController *page=navigation.topViewController;
    // Top-only ownership is essential: a managed page retained lower in the stack
    // must not theme an auth/media/OS page pushed above it. Never force a view load.
    if (!page || !SGRNativeSurfaceHasRootWithin(page.viewIfLoaded)) {
        restore(bar);
        return;
    }
    SGRNavigationAppearanceState *saved=state(bar);
    if (!saved) {
        saved=[SGRNavigationAppearanceState new];
        saved.navigation=navigation;
        saved.nativeStyle=bar.overrideUserInterfaceStyle;
        saved.nativeBarStyle=bar.barStyle;
        id requested=objc_getAssociatedObject(bar,&kNativeTint);
        saved.nativeTint=requested==NSNull.null?nil:(requested?:bar.tintColor);
        objc_setAssociatedObject(bar,&kNavigationAppearance,saved,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGRegisterAppearanceRefresh(saved,^(SGRNavigationAppearanceState *owner) {
            SGRRefreshNativeNavigationAppearance(owner.navigation);
        });
    }
    applying++;
    UIUserInterfaceStyle style=SGRedesignAppearanceStyle();
    BOOL traitsChanged=bar.overrideUserInterfaceStyle!=style;
    if (traitsChanged) bar.overrideUserInterfaceStyle=style;
    UIBarStyle targetStyle=barStyle(saved);
    if (bar.barStyle!=targetStyle) bar.barStyle=targetStyle;
    UIColor *targetTint=tint(saved);
    if (bar.tintColor!=targetTint && ![bar.tintColor isEqual:targetTint]) bar.tintColor=targetTint;
    // UIKit can defer inherited trait propagation on retained/detached bars. Settle
    // only this owner before its native platter draws or the appearance fade starts.
    if (@available(iOS 17.0,*)) [bar updateTraitsIfNeeded];
    if (traitsChanged) { [bar setNeedsLayout];[bar layoutIfNeeded]; }
    applying--;
}
static void refreshFromBar(UINavigationBar *bar) {
    if (!enabled() || applying) return;
    for (UIResponder *responder=bar.nextResponder;responder;responder=responder.nextResponder) {
        if (!nativeClass(responder,@"SPNavigationController")) continue;
        SGRRefreshNativeNavigationAppearance((id)responder);
        return;
    }
    // A bar moved outside its navigation owner relinquishes its scoped styling.
    restore(bar);
}

%group SGRNavigationAppearanceHooks
%hook SPNavigationController
- (void)viewDidLayoutSubviews {
    %orig;
    SGRRefreshNativeNavigationAppearance((id)self);
}
- (void)navigationController:(UINavigationController *)navigation willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    %orig;
    SGRRefreshNativeNavigationAppearance((id)self);
}
- (void)navigationController:(UINavigationController *)navigation didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    %orig;
    SGRRefreshNativeNavigationAppearance((id)self);
}
%end
%hook SPNavigationBar
- (void)layoutSubviews {
    // Run before UIKit lays out the Back platter, not by repainting its children.
    refreshFromBar((id)self);
    %orig;
}
- (void)didMoveToSuperview {
    %orig;
    refreshFromBar((id)self);
}
- (void)setOverrideUserInterfaceStyle:(UIUserInterfaceStyle)value {
    SGRNavigationAppearanceState *saved=state((id)self);
    if (!applying && enabled() && saved) { saved.nativeStyle=value;value=SGRedesignAppearanceStyle(); }
    %orig(value);
}
- (void)setBarStyle:(UIBarStyle)value {
    SGRNavigationAppearanceState *saved=state((id)self);
    if (!applying && enabled() && saved) { saved.nativeBarStyle=value;value=barStyle(saved); }
    %orig(value);
}
- (void)setTintColor:(UIColor *)value {
    if (!applying && enabled()) {
        objc_setAssociatedObject(self,&kNativeTint,value?:NSNull.null,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGRNavigationAppearanceState *saved=state((id)self);
        if (saved) { saved.nativeTint=value;value=tint(saved); }
    }
    %orig(value);
}
%end
%end
%ctor { if (!SGRedesignedUI()) return; %init(SGRNavigationAppearanceHooks); }
