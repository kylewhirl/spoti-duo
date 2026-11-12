// 9.1.94 objc metadata proves SideDrawerPresentationController and its presentation
// lifecycle. Native disassembly inserts its dimmingView into containerView separately.
// Own only the presented drawer content, never that container or the presenting page.
#import "Core/SGCore.h"
#import "SGRDrawerAppearance.h"
#import "SGRSheetAppearance.h"
static char kDrawerRoot;
static BOOL active(void) {return SGRedesignedUI() && NSThread.isMainThread;}
BOOL SGRDrawerOwnsView(UIView *view) {
    if (!active()) return NO;
    for (UIView *parent=view; parent; parent=parent.superview)
        if (objc_getAssociatedObject(parent,&kDrawerRoot)) return YES;
    return NO;
}
BOOL SGRDrawerPreservesView(UIView *view) {
    if(!active() || !view) return NO;
    NSString *name=NSStringFromClass(view.class);
    BOOL avatar=[name isEqualToString:@"_TtCE14Encore_FaceKitO16EncoreFoundation6Encore10AvatarView"] ||
        [name isEqualToString:@"Encore.AvatarView"] || [name isEqualToString:@"EncoreFoundation.Encore.AvatarView"] ||
        [name isEqualToString:@"_TtC29ListeningActivity_ElementsKit24ActiveListenerAvatarView"] ||
        [name isEqualToString:@"ListeningActivity_ElementsKit.ActiveListenerAvatarView"] ||
        [name isEqualToString:@"_TtC29ListeningActivity_ElementsKit21AdaptiveFaceContainer"] ||
        [name isEqualToString:@"ListeningActivity_ElementsKit.AdaptiveFaceContainer"];
    if(!avatar) return NO;
    for(UIView *parent=view.superview;parent;parent=parent.superview)
        if(objc_getAssociatedObject(parent,&kDrawerRoot)) return YES;
    return NO;
}
void SGRApplyDrawerAppearance(UIPresentationController *presentation) {
    if(!active() || !presentation) return;
    Class owner=NSClassFromString(@"_TtC23SideDrawer_PlatformImpl32SideDrawerPresentationController");
    if(!owner || ![presentation isKindOfClass:owner]) return;
    UIViewController *controller=presentation.presentedViewController;
    UIView *root=controller.viewIfLoaded;
    if(!root || [root isKindOfClass:UIWindow.class] || root==presentation.containerView || root==presentation.presentingViewController.viewIfLoaded) return;
    objc_setAssociatedObject(root,&kDrawerRoot,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // Same explicit modal-owner policy as sheets: preserve exact native Dark base,
    // adapt neutral chrome in Light and keep forced-Dark native assignments coherent.
    SGRApplyNativeSheetAppearance(controller);
}
%group SGRDrawerAppearanceHooks
%hook _TtC23SideDrawer_PlatformImpl32SideDrawerPresentationController
- (void)presentationTransitionWillBegin {
    %orig;
    SGRApplyDrawerAppearance((id)self);
}
- (void)containerViewWillLayoutSubviews {
    %orig;
    // Covers content first loaded after presentation begins; registration is idempotent.
    SGRApplyDrawerAppearance((id)self);
}
%end
%end
%ctor {if(!SGRedesignedUI()) return; %init(SGRDrawerAppearanceHooks);}
