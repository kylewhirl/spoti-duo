#import "Redesigned/Kit/SGRDrawerAppearance.h"
@interface _TtCE14Encore_FaceKitO16EncoreFoundation6Encore10AvatarView : UIView
@end
@implementation _TtCE14Encore_FaceKitO16EncoreFoundation6Encore10AvatarView
@end
@interface _TtC23SideDrawer_PlatformImpl32SideDrawerPresentationController : UIPresentationController
@property(nonatomic,strong)UIView *fixtureContainer;
@end
@implementation _TtC23SideDrawer_PlatformImpl32SideDrawerPresentationController
- (UIView *)containerView {return self.fixtureContainer;}
@end
static void drawerSnapshot(UIView *root,NSString *name) {
    [root layoutIfNeeded];
    UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc]initWithSize:root.bounds.size];
    UIImage *image=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){[root.layer renderInContext:context.CGContext];}];
    NSString *folder=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
    [UIImagePNGRepresentation(image) writeToFile:[folder stringByAppendingPathComponent:name] atomically:YES];
}
// Screenshot C9383CB3: native base #1F, card #29, Basic Family badge #F5/black.
// Main binary proves UIKit drawer root/collection/profile and native Encore labels.
static void drawerAppearanceChecks(void) {
    NSInteger saved=SGInt(SGRKeyAppearance,SGRAppearanceSystem);
    expect(SGRAppearanceApplyMode(SGRAppearanceLight,NO),@"drawer selects Light native provider");
    UIViewController *presenter=[UIViewController new],*drawer=[UIViewController new];
    presenter.view=[UIView new];presenter.view.backgroundColor=UIColor.magentaColor;
    drawer.view=[[UIView alloc]initWithFrame:CGRectMake(0,0,390,600)];
    UIColor *nativeBase=[UIColor colorWithWhite:31./255 alpha:1],*nativeCard=[UIColor colorWithWhite:42./255 alpha:1];
    drawer.view.backgroundColor=nativeBase;drawer.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    UIView *card=[[UIView alloc]initWithFrame:CGRectMake(16,30,358,140)];card.backgroundColor=nativeCard;card.layer.cornerRadius=16;[drawer.view addSubview:card];
    UIView *divider=[[UIView alloc]initWithFrame:CGRectMake(16,70,326,1)];
    UIColor *nativeDivider=[UIColor colorWithWhite:71./255 alpha:1];
    divider.backgroundColor=nativeDivider;[card addSubview:divider];
    UILabel *profile=[[UILabel alloc]initWithFrame:CGRectMake(22,14,320,42)];profile.text=@"Profile";profile.font=[UIFont boldSystemFontOfSize:26];profile.textColor=UIColor.blackColor;[card addSubview:profile];
    UILabel *menu=[[UILabel alloc]initWithFrame:CGRectMake(22,205,345,48)];menu.text=@"Settings and privacy";menu.font=[UIFont systemFontOfSize:24];menu.textColor=UIColor.blackColor;[drawer.view addSubview:menu];
    UILabel *messages=[[UILabel alloc]initWithFrame:CGRectMake(22,390,345,48)];messages.text=@"Messages";messages.font=[UIFont boldSystemFontOfSize:28];messages.textColor=UIColor.whiteColor;[drawer.view addSubview:messages];
    Class avatarClass=NSClassFromString(@"_TtCE14Encore_FaceKitO16EncoreFoundation6Encore10AvatarView");
    if(!avatarClass) {avatarClass=objc_allocateClassPair(UIView.class,"_TtCE14Encore_FaceKitO16EncoreFoundation6Encore10AvatarView",0);objc_registerClassPair(avatarClass);}
    UIView *avatar=[[avatarClass alloc]initWithFrame:CGRectMake(22,280,72,72)];avatar.backgroundColor=UIColor.purpleColor;avatar.layer.cornerRadius=36;
    UILabel *initial=[[UILabel alloc]initWithFrame:avatar.bounds];initial.text=@"F";initial.textAlignment=NSTextAlignmentCenter;initial.font=[UIFont boldSystemFontOfSize:28];initial.textColor=UIColor.blackColor;[avatar addSubview:initial];[drawer.view addSubview:avatar];
    UIBlurEffect *avatarEffect=[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *avatarGlass=[[UIVisualEffectView alloc]initWithEffect:avatarEffect];avatarGlass.frame=CGRectMake(0,55,72,17);avatarGlass.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;[avatar addSubview:avatarGlass];
    UILabel *friend=[[UILabel alloc]initWithFrame:CGRectMake(112,290,230,45)];friend.text=@"Friend activity";friend.textColor=UIColor.whiteColor;[drawer.view addSubview:friend];
    UIImage *bitmap=[[[UIGraphicsImageRenderer alloc]initWithSize:CGSizeMake(24,24)] imageWithActions:^(UIGraphicsImageRendererContext *c){[UIColor.blueColor setFill];UIRectFill(CGRectMake(0,0,24,24));[UIColor.orangeColor setFill];UIRectFill(CGRectMake(12,0,12,24));}];UIImageView *art=[[UIImageView alloc]initWithImage:bitmap];art.frame=CGRectMake(285,280,72,72);[drawer.view addSubview:art];
    UIView *badge=[[UIView alloc]initWithFrame:CGRectMake(220,450,145,44)];UIColor *badgePaint=[UIColor colorWithWhite:245./255 alpha:1];badge.backgroundColor=badgePaint;UILabel *badgeText=[[UILabel alloc]initWithFrame:badge.bounds];badgeText.text=@"Basic Family";badgeText.textAlignment=NSTextAlignmentCenter;badgeText.textColor=UIColor.blackColor;[badge addSubview:badgeText];[drawer.view addSubview:badge];
    CGRect frame=drawer.view.frame;UIView *container=[[UIView alloc]initWithFrame:drawer.view.bounds];UIView *scrim=[UIView new];scrim.backgroundColor=[UIColor colorWithWhite:0 alpha:.4];[container addSubview:scrim];[container addSubview:drawer.view];
    UIColor *scrimColor=scrim.backgroundColor;
    _TtC23SideDrawer_PlatformImpl32SideDrawerPresentationController *owner=[[_TtC23SideDrawer_PlatformImpl32SideDrawerPresentationController alloc]initWithPresentedViewController:drawer presentingViewController:presenter];owner.fixtureContainer=container;
    expect(!SGRNativeSurfaceManaged(menu) && contrast(menu.textColor,nativeBase)<2,@"missing drawer owner reproduces black ink on native dark base");
    drawerSnapshot(drawer.view,@"drawer-before.png");
    [owner presentationTransitionWillBegin];
    [owner containerViewWillLayoutSubviews];
    expect(SGRNativeSurfaceManaged(menu) && !SGRNativeSurfaceManaged(container) && !SGRNativeSurfaceManaged(scrim),@"only explicit presented drawer subtree becomes managed");
    expect(drawer.overrideUserInterfaceStyle==UIUserInterfaceStyleLight && drawer.view.overrideUserInterfaceStyle==UIUserInterfaceStyleLight,@"drawer controller and content override native forced Dark coherently");
    expect(contrast(menu.textColor,drawer.view.backgroundColor)>=7 && contrast(messages.textColor,drawer.view.backgroundColor)>=7 && contrast(profile.textColor,card.backgroundColor)>=7,@"mixed Light-provider menu and hardcoded white messaging become readable together");
    expect(!SGRNativeSurfaceManaged(initial) && same(initial.textColor,UIColor.blackColor) && same(avatar.backgroundColor,UIColor.purpleColor),@"drawer avatar initials and accent are native payload, not menu ink");
    drawerSnapshot(drawer.view,@"drawer-light.png");
    // Late wrapper insertion must identify avatar boundary before the first managed pass.
    UIView *wrapper=[UIView new],*lateAvatar=[avatarClass new];UILabel *lateInitial=[UILabel new];lateInitial.text=@"S";lateInitial.textColor=UIColor.blackColor;[lateAvatar addSubview:lateInitial];[wrapper addSubview:lateAvatar];[drawer.view addSubview:wrapper];
    expect(!SGRNativeSurfaceManaged(lateInitial) && same(lateInitial.textColor,UIColor.blackColor),@"late nested avatar insertion remains preserved without a separate sweep");
    for(NSUInteger i=0;i<12;i++) {
        BOOL light=i%2;expect(SGRAppearanceApplyMode(light?SGRAppearanceLight:SGRAppearanceDark,NO),@"retained drawer appearance changes live");
        expect(contrast(menu.textColor,drawer.view.backgroundColor)>=7 && contrast(messages.textColor,drawer.view.backgroundColor)>=7 && contrast(friend.textColor,drawer.view.backgroundColor)>=7,@"retained drawer all neutral text stays readable both ways");
        expect(light || (same(drawer.view.backgroundColor,nativeBase) && same(card.backgroundColor,nativeCard)),@"Dark restores exact native drawer/card bases");
        expect(same(divider.backgroundColor,light?[UIColor colorWithWhite:.78 alpha:1]:nativeDivider),@"drawer divider is light gray in Light and exact original in Dark");
        expect(avatarGlass.effect==avatarEffect && avatarGlass.overrideUserInterfaceStyle==UIUserInterfaceStyleDark,@"avatar visual effect retains exact native blur object and explicit style");
        expect(same(initial.textColor,UIColor.blackColor) && same(lateInitial.textColor,UIColor.blackColor) && art.image==bitmap && same(avatar.backgroundColor,UIColor.purpleColor),@"avatar initials, accent and media bitmap unchanged across repeated switches");
        expect(same(badge.backgroundColor,badgePaint) && same(badgeText.textColor,UIColor.blackColor),@"screenshot #F5F5F5 plan badge keeps exact backing and black text even without UIControl boundary");
        expect(CGRectEqualToRect(drawer.view.frame,frame) && CGColorEqualToColor(scrim.backgroundColor.CGColor,scrimColor.CGColor) && same(presenter.view.backgroundColor,UIColor.magentaColor),@"native geometry, dimming scrim and presenting page untouched");
        if(!light && i==0) drawerSnapshot(drawer.view,@"drawer-dark.png");
    }
    for(NSUInteger mode=0;mode<2;mode++) {
        BOOL light=mode==1;SGRAppearanceApplyMode(light?SGRAppearanceLight:SGRAppearanceDark,NO);
        UIViewController *fresh=[UIViewController new];fresh.view=[[UIView alloc]initWithFrame:frame];fresh.view.backgroundColor=nativeBase;
        UILabel *row=[UILabel new];row.text=@"Fresh native menu";row.textColor=light?UIColor.blackColor:UIColor.whiteColor;[fresh.view addSubview:row];
        UILabel *heading=[UILabel new];heading.text=@"Messages";heading.textColor=UIColor.whiteColor;[fresh.view addSubview:heading];
        _TtC23SideDrawer_PlatformImpl32SideDrawerPresentationController *freshOwner=[[_TtC23SideDrawer_PlatformImpl32SideDrawerPresentationController alloc]initWithPresentedViewController:fresh presentingViewController:presenter];
        freshOwner.fixtureContainer=[[UIView alloc]initWithFrame:frame];[freshOwner.fixtureContainer addSubview:fresh.view];[freshOwner presentationTransitionWillBegin];
        expect(contrast(row.textColor,fresh.view.backgroundColor)>=7 && contrast(heading.textColor,fresh.view.backgroundColor)>=7,@"drawer created fresh under each selected native provider has coherent menu and messaging ink");
        row.textColor=light?UIColor.blackColor:UIColor.whiteColor;heading.textColor=UIColor.whiteColor;fresh.view.backgroundColor=nativeBase;
        expect(contrast(row.textColor,fresh.view.backgroundColor)>=7 && contrast(heading.textColor,fresh.view.backgroundColor)>=7,@"native drawer color reassignment remains coherent in each selected mode");
    }
    UIViewController *unrelated=[UIViewController new];unrelated.view=[UIView new];UIPresentationController *other=[[UIPresentationController alloc]initWithPresentedViewController:unrelated presentingViewController:presenter];SGRApplyDrawerAppearance(other);
    expect(!SGRNativeSurfaceManaged(unrelated.view),@"unrelated presentation owner is rejected");
    [NSUserDefaults.standardUserDefaults setInteger:saved forKey:SGRKeyAppearance];SGRAppearanceApplyMode(saved,NO);
}
