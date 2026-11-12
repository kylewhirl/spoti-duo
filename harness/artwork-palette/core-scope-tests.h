#import "Core/SGAppearance.h"
// Include after existing fixture expect/same helpers. Pass a real simulator scene host.
static void coreAppearanceScopeChecks(UIView *host) {
    UIUserInterfaceStyle prior=SGRedesignAppearanceStyle();
    SGConfigureRedesignAppearance(UIUserInterfaceStyleLight);
    UIView *root=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,400)];[host addSubview:root];
    UILabel *child=[[UILabel alloc]initWithFrame:CGRectMake(0,0,200,40)];[root addSubview:child];
    child.textColor=SGAppearanceColor(UIColor.blackColor,UIColor.whiteColor);
    SGRegisterAppearanceView(child);
    UIView *modal=[UIView new];[root addSubview:modal];
    UILabel *modalChild=[UILabel new];[modal addSubview:modalChild];SGRegisterAppearanceView(modalChild);
    SGSetAppearanceScope(modal,UIUserInterfaceStyleUnspecified);
    __block NSUInteger childRefresh=0,modalRefresh=0;
    SGRegisterAppearanceRefresh(child,^(id owner){childRefresh++;});
    SGRegisterAppearanceRefresh(modalChild,^(id owner){modalRefresh++;});
    SGSetAppearanceScope(root,UIUserInterfaceStyleDark);
    [root updateTraitsIfNeeded];[child updateTraitsIfNeeded];[modal updateTraitsIfNeeded];[modalChild updateTraitsIfNeeded];
    expect(SGRedesignAppearanceStyle()==UIUserInterfaceStyleLight && SGRedesignLightAppearance(),@"local scope does not mutate global appearance");
    expect(SGAppearanceStyleForView(child)==UIUserInterfaceStyleDark && child.overrideUserInterfaceStyle==UIUserInterfaceStyleDark,@"registered descendant follows explicit local dark root");
    expect(same([child.textColor resolvedColorWithTraitCollection:child.traitCollection],UIColor.whiteColor),@"retained semantic ink resolves local custom trait, not global");
    expect(SGAppearanceStyleForView(modalChild)==UIUserInterfaceStyleLight && SGAppearanceStyleForTraits(modalChild.traitCollection)==UIUserInterfaceStyleLight,@"explicit global modal boundary defeats inherited local style");
    expect(childRefresh>0 && modalRefresh==0,@"local refresh visits only owned descendants, not independent modal callbacks");
    SGSetAppearanceScope(root,UIUserInterfaceStyleLight);
    [root updateTraitsIfNeeded];[child updateTraitsIfNeeded];
    expect(same([child.textColor resolvedColorWithTraitCollection:child.traitCollection],UIColor.blackColor),@"same retained ink changes on local dark-to-light transition");
    SGSetAppearanceScope(root,UIUserInterfaceStyleDark);
    SGRefreshAppearanceOwners();
    expect(child.overrideUserInterfaceStyle==UIUserInterfaceStyleDark && modalChild.overrideUserInterfaceStyle==UIUserInterfaceStyleLight,@"global owner refresh preserves local scope and global boundary");
    [child removeFromSuperview];[host addSubview:child];SGRegisterAppearanceView(child);[child updateTraitsIfNeeded];
    expect(SGAppearanceStyleForView(child)==UIUserInterfaceStyleLight && child.overrideUserInterfaceStyle==UIUserInterfaceStyleLight && same([child.textColor resolvedColorWithTraitCollection:child.traitCollection],UIColor.blackColor),@"reparented view returns global style on ordinary registration refresh");
    SGClearAppearanceScope(root);[root updateTraitsIfNeeded];
    expect(SGAppearanceStyleForView(root)==UIUserInterfaceStyleLight && SGAppearanceStyleForTraits(root.traitCollection)==UIUserInterfaceStyleLight,@"clearing scope restores global behavior");
    SGUnregisterAppearanceRefresh(child);SGUnregisterAppearanceRefresh(modalChild);SGUnregisterAppearanceView(child);SGUnregisterAppearanceView(modalChild);
    [child removeFromSuperview];[root removeFromSuperview];SGConfigureRedesignAppearance(prior);SGRefreshAppearanceOwners();
}
