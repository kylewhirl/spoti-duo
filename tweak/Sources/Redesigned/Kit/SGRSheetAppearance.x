// 9.1.94 objc-9.1.94.txt proves these presentation owners and Share_ECMKit preview classes.
// The menu/share sheets are presented outside the page roots. Their native forced-dark
// presentation previously mixed with Light-provider black ink. Register the actual owners;
// preserve the share payload and all artwork rather than sweeping the presenting window.
#import "Core/SGCore.h"
#import "SGRSheetAppearance.h"
#import "SGRNativeSurface.h"
#import "SGRDrawerAppearance.h"

static char kSheetOwner, kSheetRoot, kSheetPrepared, kSheetEffect, kContextRoot, kLibraryFilterRoot;
static BOOL updatingEffect;
static BOOL active(void) { return SGRedesignedUI() && NSThread.isMainThread; }
BOOL SGRNativeSheetPreservesView(UIView *view) {
    if (SGRDrawerPreservesView(view)) return YES;
    // NSStringFromClass may present a Swift class in either runtime spelling. Both
    // spellings identify the same binary-proven classes, not a broad name substring.
    static NSSet<NSString *> *names;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ names=[NSSet setWithArray:@[
        @"_TtC12Share_ECMKit24SharePreviewScaffoldView", @"Share_ECMKit.SharePreviewScaffoldView",
        @"_TtC12Share_ECMKit29BackgroundWithStickerCardView", @"Share_ECMKit.BackgroundWithStickerCardView",
        @"_TtC12Share_ECMKit25ShareFormatForegroundView", @"Share_ECMKit.ShareFormatForegroundView",
        @"_TtC12Share_ECMKit19TraitsShareCardView", @"Share_ECMKit.TraitsShareCardView",
        @"_TtC12Share_ECMKit20PodcastAudioCardView", @"Share_ECMKit.PodcastAudioCardView",
        @"_TtC12Share_ECMKit25PodcastTranscriptCardView", @"Share_ECMKit.PodcastTranscriptCardView",
        @"_TtC12Share_ECMKit27ShareCardVideoContainerView", @"Share_ECMKit.ShareCardVideoContainerView"]]; });
    return [names containsObject:NSStringFromClass(view.class)];
}
// ContextMenu_ECMKit caches main.base in swift_once (9.1.94: 0x102fbcf48).
// Its normal row factory reads cached base.text.base, even after a provider transition.
// Only native Encore labels in actual context-menu cells below the registered owner opt in. Share
// previews, headers, arbitrary modal labels and any reparented cell do not acquire this role.
BOOL SGRNativeContextMenuUsesBaseText(UIView *view) {
    if (!active() || ![view isKindOfClass:UILabel.class]) return NO;
    Class labelClass=NSClassFromString(@"SPTEncoreLabel");
    if (!labelClass) return NO;
    BOOL row=NO, nativeText=NO;
    for (UIView *parent=view; parent; parent=parent.superview) {
        if (SGRNativeSheetPreservesView(parent)) return NO;
        if ([parent isKindOfClass:labelClass]) nativeText=YES;
        NSString *name=NSStringFromClass(parent.class);
        if ([name isEqual:@"_TtC24ContextMenu_InternalImpl24ContextMenuTableViewCell"] ||
            [name isEqual:@"ContextMenu_InternalImpl.ContextMenuTableViewCell"]) row=YES;
        if (objc_getAssociatedObject(parent,&kContextRoot)) return row && nativeText;
    }
    return NO;
}
BOOL SGRNativeLibraryFilterOwnsView(UIView *view) {
    if(!active())return NO;
    for(UIView *node=view;node;node=node.superview) {
        if(SGRNativeSheetPreservesView(node) || [node isKindOfClass:UIImageView.class])return NO;
        if(objc_getAssociatedObject(node,&kLibraryFilterRoot))return YES;
        if(objc_getAssociatedObject(node,&kSheetRoot))return NO;
    }
    return NO;
}
static BOOL shareWrapper(UIViewController *controller) {
    NSString *name=NSStringFromClass(controller.class);
    return [name isEqualToString:@"_TtC14Share_MenuImpl32LegacyShareMenuNavigationWrapper"] ||
        [name isEqualToString:@"Share_MenuImpl.LegacyShareMenuNavigationWrapper"] ||
        [name isEqualToString:@"_TtC14Share_MenuImpl32NativeShareMenuNavigationWrapper"] ||
        [name isEqualToString:@"Share_MenuImpl.NativeShareMenuNavigationWrapper"];
}
BOOL SGRNativeSheetOwnsEffect(UIView *view) {
    if (!active() || ![view isKindOfClass:UIVisualEffectView.class]) return NO;
    for (UIView *parent=view.superview;parent;parent=parent.superview) {
        if (SGRNativeSheetPreservesView(parent) || [parent isKindOfClass:UIImageView.class]) return NO;
        if (objc_getAssociatedObject(parent,&kSheetRoot)) return YES;
    }
    return NO;
}
static void releaseEffect(UIVisualEffectView *view) {
    NSDictionary *record=objc_getAssociatedObject(view,&kSheetEffect);
    if (!record) return;
    UIVisualEffect *source=record[@"source"]==NSNull.null?nil:record[@"source"];
    UIUserInterfaceStyle style=[record[@"style"] integerValue];
    objc_setAssociatedObject(view,&kSheetEffect,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    SGUnregisterAppearanceView(view);
    SGUnregisterAppearanceRefresh(view);
    updatingEffect=YES;view.effect=source;updatingEffect=NO;
    view.overrideUserInterfaceStyle=style;
}
void SGRRefreshNativeSheetNode(UIView *view) {
    if ([view isKindOfClass:UIVisualEffectView.class] && objc_getAssociatedObject(view,&kSheetEffect) && !SGRNativeSheetOwnsEffect(view))
        releaseEffect((id)view);
}
static void refreshEffect(UIVisualEffectView *view) {
    if (!SGRNativeSheetOwnsEffect(view)) { releaseEffect(view); return; }
    NSDictionary *record=objc_getAssociatedObject(view,&kSheetEffect);
    UIVisualEffect *source=record[@"source"]==NSNull.null?nil:record[@"source"];
    UIVisualEffect *wanted=SGRedesignLightAppearance() && [source isKindOfClass:UIBlurEffect.class] ? record[@"light"] : source;
    if(view.effect!=wanted) { updatingEffect=YES;view.effect=wanted;updatingEffect=NO; }
}
static void saveEffect(UIVisualEffectView *view, UIVisualEffect *effect) {
    NSDictionary *old=objc_getAssociatedObject(view,&kSheetEffect);
    objc_setAssociatedObject(view,&kSheetEffect,@{@"source":effect?:NSNull.null,
        @"style":old[@"style"]?:@(view.overrideUserInterfaceStyle),
        @"light":[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]},OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static void registerSheetContent(UIView *view) {
    if (SGRNativeSheetPreservesView(view) || [view isKindOfClass:UIImageView.class]) return;
    if ([view isKindOfClass:UIVisualEffectView.class] && SGRNativeSheetOwnsEffect(view)) {
        // A sheet effect is a temporary boundary exception, NOT an independent native
        // root. Reparenting out or into a preview immediately relinquishes ownership.
        if (!objc_getAssociatedObject(view,&kSheetEffect)) saveEffect((id)view,((UIVisualEffectView *)view).effect);
        SGRegisterAppearanceView(view);
        SGRegisterAppearanceRefresh(view,^(id owner) { refreshEffect(owner); });
        refreshEffect((id)view);
    }
    for (UIView *child in view.subviews) registerSheetContent(child);
}
static void registerOwner(UIViewController *controller) {
    if (!controller) return;
    objc_setAssociatedObject(controller,&kSheetOwner,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIView *root=controller.viewIfLoaded;
    if (root) {
        objc_setAssociatedObject(root,&kSheetRoot,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSString *name=NSStringFromClass(controller.class);
        if([name isEqual:@"_TtC28YourLibrary_YourLibraryXImpl25BottomSheetViewController"] ||
           [name isEqual:@"YourLibrary_YourLibraryXImpl.BottomSheetViewController"] ||
           [name isEqual:@"SPTSortingFilteringPickerViewController"])
            objc_setAssociatedObject(root,&kLibraryFilterRoot,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        if ([name isEqual:@"_TtC24ContextMenu_InternalImpl25ContextMenuViewController"] ||
            [name isEqual:@"ContextMenu_InternalImpl.ContextMenuViewController"])
            objc_setAssociatedObject(root,&kContextRoot,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // A modal opened over artwork-colored Now Playing follows the app, not its presenter.
    if (root) SGSetAppearanceScope(root, UIUserInterfaceStyleUnspecified);
    SGRegisterAppearanceController(controller);
    if (root && !objc_getAssociatedObject(root,&kSheetPrepared)) {
        objc_setAssociatedObject(root,&kSheetPrepared,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        registerSheetContent(root);
    }
    // The sheet's base is app chrome; provider-independent dark paint must not remain
    // underneath light-origin black labels. Subsequent assignments retain the base role.
    SGRApplyNativeSheetSurface(root);
}
void SGRApplyNativeSheetAppearance(UIViewController *controller) {
    if (!active() || !controller.viewIfLoaded) return;
    registerOwner(controller);
    // Only Spotify's proven share wrapper, never the presenting navigation stack.
    if (shareWrapper(controller.parentViewController)) registerOwner(controller.parentViewController);
}

%group SGRSheetAppearanceHooks
%hook UIViewController
- (void)setOverrideUserInterfaceStyle:(UIUserInterfaceStyle)style {
    %orig(active() && objc_getAssociatedObject(self,&kSheetOwner) ? SGRedesignAppearanceStyle() : style);
}
%end
%hook UIView
- (void)setOverrideUserInterfaceStyle:(UIUserInterfaceStyle)style {
    %orig(active() && (objc_getAssociatedObject(self,&kSheetRoot) || (objc_getAssociatedObject(self,&kSheetEffect) && SGRNativeSheetOwnsEffect(self))) ? SGRedesignAppearanceStyle() : style);
}
%end
%hook UIVisualEffectView
- (void)setEffect:(UIVisualEffect *)effect {
    if (!active() || updatingEffect || !objc_getAssociatedObject(self,&kSheetEffect)) { %orig; return; }
    if (!SGRNativeSheetOwnsEffect(self)) { releaseEffect(self); %orig; return; }
    saveEffect(self,effect);
    UIVisualEffect *wanted=SGRedesignLightAppearance() && [effect isKindOfClass:UIBlurEffect.class] ?
        [objc_getAssociatedObject(self,&kSheetEffect) objectForKey:@"light"] : effect;
    %orig(wanted);
}
- (void)didMoveToSuperview {
    %orig;
    if (!active()) return;
    if (SGRNativeSheetOwnsEffect(self)) registerSheetContent(self);
    else releaseEffect(self);
    SGRRefreshNativeSurfaceSubtree(self);
}
%end
%hook _TtC24ContextMenu_InternalImpl25ContextMenuViewController
- (void)viewDidLoad { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewWillAppear:(BOOL)animated { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewDidLayoutSubviews { %orig; SGRApplyNativeSheetAppearance((id)self); }
%end
%hook _TtC14Share_MenuImpl29LegacyShareMenuViewController
- (void)viewDidLoad { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewWillAppear:(BOOL)animated { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewDidLayoutSubviews { %orig; SGRApplyNativeSheetAppearance((id)self); }
%end
%hook _TtC14Share_MenuImpl29NativeShareMenuViewController
- (void)viewDidLoad { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewWillAppear:(BOOL)animated { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewDidLayoutSubviews { %orig; SGRApplyNativeSheetAppearance((id)self); }
%end
// These native modal owners are binary-proven in Spotify 9.1.94. They live
// outside registered entity pages, just like Share; reuse the scoped surface
// adapter without altering selection, playback, artwork or presentation geometry.
%hook _TtC34PlaylistCuration_AddToPlaylistImpl26ATPContainerViewController
- (void)viewDidLoad { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewWillAppear:(BOOL)animated { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewDidLayoutSubviews { %orig; SGRApplyNativeSheetAppearance((id)self); }
%end
%hook _TtC34PlaylistCuration_AddToPlaylistImpl17ATPViewController
- (void)viewDidLoad { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewWillAppear:(BOOL)animated { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewDidLayoutSubviews { %orig; SGRApplyNativeSheetAppearance((id)self); }
%end
%hook _TtC14Queue_ViewImpl19QueueViewController
- (void)viewDidLoad { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewWillAppear:(BOOL)animated { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewDidLayoutSubviews { %orig; SGRApplyNativeSheetAppearance((id)self); }
%end
// Your Library filters: the CommonKit similarly named controller is an NSObject
// delegate, not a presentation owner. Only these binary-proven UIViewControllers opt in.
%hook _TtC28YourLibrary_YourLibraryXImpl25BottomSheetViewController
- (void)viewWillAppear:(BOOL)animated { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewDidLayoutSubviews { %orig; SGRApplyNativeSheetAppearance((id)self); }
%end
%hook SPTSortingFilteringPickerViewController
- (void)viewDidLoad { %orig; SGRApplyNativeSheetAppearance((id)self); }
- (void)viewDidLayoutSubviews { %orig; SGRApplyNativeSheetAppearance((id)self); }
%end
%end
%ctor { if (!SGRedesignedUI()) return; %init(SGRSheetAppearanceHooks); }
