#import "SGAppearance.h"
#import <stdatomic.h>
#import <objc/runtime.h>

// Dark is the safe fallback until the bridge has verified Spotify's semantic theme provider.
static _Atomic(UIUserInterfaceStyle) appearance = UIUserInterfaceStyleDark;
static NSMapTable *refreshOwners;
static NSHashTable<UIView *> *appearanceViews;
static NSHashTable<UIViewController *> *appearanceControllers;

// UIKit propagates this private-to-the-tweak PUBLIC custom trait through the local
// view hierarchy. A zero value deliberately keeps all existing global semantics.
API_AVAILABLE(ios(17.0))
@interface SGRLocalAppearanceTrait : NSObject <UINSIntegerTraitDefinition> @end
@implementation SGRLocalAppearanceTrait
+ (NSInteger)defaultValue { return 0; }
+ (NSString *)identifier { return @"com.spotipw.appearance.local-style"; }
+ (BOOL)affectsColorAppearance { return YES; }
@end
API_AVAILABLE(ios(17.0))
@interface SGRPaletteRevisionTrait : NSObject <UINSIntegerTraitDefinition> @end
@implementation SGRPaletteRevisionTrait
+ (NSInteger)defaultValue { return 0; }
+ (NSString *)identifier { return @"com.spotipw.appearance.palette-revision"; }
+ (BOOL)affectsColorAppearance { return YES; }
@end
static NSInteger paletteRevision;
static char kLocalAppearanceScope;
static UIView *ownerView(id owner) {
    if ([owner isKindOfClass:UIView.class]) return owner;
    if ([owner isKindOfClass:UIViewController.class]) return [(UIViewController *)owner viewIfLoaded];
    if ([owner isKindOfClass:CALayer.class]) {
        for (CALayer *layer=owner;layer;layer=layer.superlayer)
            if ([layer.delegate isKindOfClass:UIView.class]) return (UIView *)layer.delegate;
    }
    return nil;
}
UIUserInterfaceStyle SGAppearanceStyleForTraits(UITraitCollection *traits) {
    if (@available(iOS 17.0, *)) {
        // Explicit dependency lets UIKit redraw retained token colors when hue changes
        // but the selected Light/Dark appearance does not.
        (void)[traits valueForNSIntegerTrait:SGRPaletteRevisionTrait.class];
        NSInteger value=[traits valueForNSIntegerTrait:SGRLocalAppearanceTrait.class];
        if (value==UIUserInterfaceStyleLight || value==UIUserInterfaceStyleDark) return value;
    }
    return appearance;
}
UIUserInterfaceStyle SGAppearanceStyleForView(UIView *view) {
    for (UIView *node=view;node;node=node.superview) {
        NSNumber *scope=objc_getAssociatedObject(node,&kLocalAppearanceScope);
        if (scope) return scope.integerValue==UIUserInterfaceStyleUnspecified ? appearance : scope.integerValue;
    }
    return appearance;
}
UIUserInterfaceStyle SGAppearanceStyleForOwner(id owner) {
    return SGAppearanceStyleForView(ownerView(owner));
}
static BOOL belongsToSubtree(UIView *view, UIView *root) {
    for (UIView *node=view;node;node=node.superview) {
        if (node==root) return YES;
        // Independent nested roots remain independent during a parent's local refresh.
        if (objc_getAssociatedObject(node,&kLocalAppearanceScope)) return NO;
    }
    return NO;
}
static void applyViewStyle(UIView *view) {
    UIUserInterfaceStyle style=SGAppearanceStyleForView(view);
    if (@available(iOS 17.0,*)) [view.traitOverrides setNSIntegerValue:paletteRevision forTrait:SGRPaletteRevisionTrait.class];
    if (view.overrideUserInterfaceStyle!=style) view.overrideUserInterfaceStyle=style;
    [view setNeedsDisplay];
}
void SGRefreshAppearanceSubtree(UIView *root) {
    NSCAssert(NSThread.isMainThread, @"Local appearance refresh is main-thread only");
    if (!root) return;
    applyViewStyle(root);
    for (UIViewController *controller in appearanceControllers.allObjects) {
        if (!belongsToSubtree(controller.viewIfLoaded,root)) continue;
        UIUserInterfaceStyle style=SGAppearanceStyleForOwner(controller);
        if (controller.overrideUserInterfaceStyle!=style) controller.overrideUserInterfaceStyle=style;
    }
    for (UIView *view in appearanceViews.allObjects)
        if (belongsToSubtree(view,root)) applyViewStyle(view);
    for (id owner in refreshOwners.keyEnumerator.allObjects) {
        if (!belongsToSubtree(ownerView(owner),root)) continue;
        void (^refresh)(id)=[refreshOwners objectForKey:owner];
        if (refresh) refresh(owner);
    }
}
void SGSetAppearanceScope(UIView *root, UIUserInterfaceStyle style) {
    NSCAssert(NSThread.isMainThread, @"Local appearance scopes are main-thread only");
    if (!root || [root isKindOfClass:UIWindow.class]) return;
    if (style!=UIUserInterfaceStyleLight && style!=UIUserInterfaceStyleDark) style=UIUserInterfaceStyleUnspecified;
    NSNumber *old=objc_getAssociatedObject(root,&kLocalAppearanceScope);
    if (old && old.integerValue==style) return;
    objc_setAssociatedObject(root,&kLocalAppearanceScope,@(style),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 17.0, *)) [root.traitOverrides setNSIntegerValue:style forTrait:SGRLocalAppearanceTrait.class];
    SGRefreshAppearanceSubtree(root);
}
void SGClearAppearanceScope(UIView *root) {
    NSCAssert(NSThread.isMainThread, @"Local appearance scopes are main-thread only");
    if (!root || !objc_getAssociatedObject(root,&kLocalAppearanceScope)) return;
    objc_setAssociatedObject(root,&kLocalAppearanceScope,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 17.0, *)) [root.traitOverrides removeTrait:SGRLocalAppearanceTrait.class];
    SGRefreshAppearanceSubtree(root);
}

UIUserInterfaceStyle SGRedesignAppearanceStyle(void) { return appearance; }
void SGConfigureRedesignAppearance(UIUserInterfaceStyle style) {
    appearance = style == UIUserInterfaceStyleLight ? UIUserInterfaceStyleLight : UIUserInterfaceStyleDark;
}
BOOL SGRedesignLightAppearance(void) { return appearance == UIUserInterfaceStyleLight; }
UIColor *SGAppearanceColor(UIColor *light, UIColor *dark) {
    // Retained labels, attributed strings and control-state colors stay semantic. Registered roots
    // change traits when the selected mode changes; no view/window traversal is necessary.
    static NSCache *colors;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ colors = [NSCache new]; colors.countLimit = 256; });
    NSArray *key = @[light, dark];
    UIColor *color = [colors objectForKey:key];
    if (!color) {
        color = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
            return [(SGAppearanceStyleForTraits(traits)==UIUserInterfaceStyleLight ? light : dark) resolvedColorWithTraitCollection:traits];
        }];
        [colors setObject:color forKey:key];
    }
    return color;
}
void SGRegisterAppearanceRefresh(id owner, void (^refresh)(id)) {
    NSCAssert(NSThread.isMainThread, @"Appearance owners are main-thread only");
    if (!owner || !refresh) return;
    if (!refreshOwners) refreshOwners = [NSMapTable weakToStrongObjectsMapTable];
    [refreshOwners setObject:[refresh copy] forKey:owner];
}
void SGRegisterAppearanceView(UIView *view) {
    NSCAssert(NSThread.isMainThread, @"Appearance views are main-thread only");
    if (!view) return;
    if (!appearanceViews) appearanceViews = [NSHashTable weakObjectsHashTable];
    [appearanceViews addObject:view];
    applyViewStyle(view);
}
void SGRegisterAppearanceController(UIViewController *controller) {
    NSCAssert(NSThread.isMainThread, @"Appearance controllers are main-thread only");
    if (!controller) return;
    if (!appearanceControllers) appearanceControllers = [NSHashTable weakObjectsHashTable];
    [appearanceControllers addObject:controller];
    UIUserInterfaceStyle style=SGAppearanceStyleForOwner(controller);
    if (controller.overrideUserInterfaceStyle != style) controller.overrideUserInterfaceStyle = style;
    SGRegisterAppearanceView(controller.viewIfLoaded);
}
void SGInvalidateAppearanceColors(void) {
    NSCAssert(NSThread.isMainThread, @"Palette refresh is main-thread only");
    paletteRevision = paletteRevision == NSIntegerMax ? 1 : paletteRevision + 1;
    for (UIView *view in appearanceViews.allObjects) applyViewStyle(view);
}

void SGRefreshAppearanceOwners(void) {
    NSCAssert(NSThread.isMainThread, @"Appearance refresh is main-thread only");
    for (UIViewController *controller in appearanceControllers.allObjects) {
        UIUserInterfaceStyle style=SGAppearanceStyleForOwner(controller);
        if (controller.overrideUserInterfaceStyle != style) controller.overrideUserInterfaceStyle = style;
    }
    for (UIView *view in appearanceViews.allObjects) {
        applyViewStyle(view);
    }
    // Snapshot owners: callbacks may register newly constructed owned controls.
    for (id owner in refreshOwners.keyEnumerator.allObjects) {
        void (^refresh)(id) = [refreshOwners objectForKey:owner];
        if (refresh) refresh(owner);
    }
}

void SGUnregisterAppearanceView(UIView *view) {
    NSCAssert(NSThread.isMainThread, @"Appearance views are main-thread only");
    [appearanceViews removeObject:view];
}
void SGUnregisterAppearanceRefresh(id owner) {
    NSCAssert(NSThread.isMainThread, @"Appearance owners are main-thread only");
    [refreshOwners removeObjectForKey:owner];
}
