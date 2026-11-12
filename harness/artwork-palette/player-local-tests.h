#import "Redesigned/Player/Player.h"
static SGRArtworkField *testPlayerField;
SGRArtworkField *SGRPlayerField(void) { return testPlayerField; }
static UIImage *solidArt(UIColor *color) {
 UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc]initWithSize:CGSizeMake(64,64)];
 return [renderer imageWithActions:^(UIGraphicsImageRendererContext *c) { [color setFill];UIRectFill(CGRectMake(0,0,64,64)); }];
}
static void playerLocalChecks(UIView *host) {
 UIUserInterfaceStyle prior=SGRedesignAppearanceStyle();
 NSInteger pref=SGInt(SGRKeyPlayerArtworkAppearance,0);
 SGConfigureRedesignAppearance(UIUserInterfaceStyleLight);SGSetInt(SGRKeyPlayerArtworkAppearance,0);
 UIViewController *owner=[UIViewController new];owner.view=[[UIView alloc]initWithFrame:CGRectMake(0,0,380,500)];[host addSubview:owner.view];
 testPlayerField=[[SGRArtworkField alloc]initWithFrame:owner.view.bounds];testPlayerField.flows=YES;[owner.view addSubview:testPlayerField];
 __block NSUInteger paletteCount=0;testPlayerField.artworkLuminanceChanged=^(CGFloat value){paletteCount++;SGRPlayerSetArtworkLuminance(value);};
 UILabel *title=[[UILabel alloc]initWithFrame:CGRectMake(20,330,340,44)];title.text=@"Now Playing";title.font=[UIFont boldSystemFontOfSize:26];title.textColor=SGRPrimary();[owner.view addSubview:title];SGRegisterAppearanceView(title);
 UIImageView *art=[[UIImageView alloc]initWithFrame:CGRectMake(70,30,240,240)];[owner.view addSubview:art];
 UILabel *controls=[[UILabel alloc]initWithFrame:CGRectMake(20,390,340,44)];controls.text=@"◀     ▶     ▶▶";controls.textColor=SGRPrimary();controls.textAlignment=NSTextAlignmentCenter;[owner.view addSubview:controls];SGRegisterAppearanceView(controls);
 SGRPlayerRegisterArtworkAppearance(owner);SGRApplyNativeLightSurface(owner.view,NO);
 SGRPlayerSetArtworkLuminance(0);
 expect(SGAppearanceStyleForView(title)==UIUserInterfaceStyleLight,@"default Follow app preserves Light with dark artwork");
 SGSetInt(SGRKeyPlayerArtworkAppearance,1);SGRPlayerApplyAppearancePreference();
 for (NSNumber *light in @[@NO,@YES,@NO]) {
  UIImage *image=solidArt(light.boolValue?[UIColor colorWithRed:1 green:.9 blue:.8 alpha:1]:[UIColor colorWithRed:.06 green:.12 blue:.08 alpha:1]);art.image=image;
  NSUInteger previous=paletteCount;[testPlayerField setArtwork:image identity:NSUUID.UUID.UUIDString animated:NO];
  NSDate *until=[NSDate dateWithTimeIntervalSinceNow:3];while(paletteCount==previous && until.timeIntervalSinceNow>0)[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
  [owner.view updateTraitsIfNeeded];[title updateTraitsIfNeeded];[controls updateTraitsIfNeeded];[owner.view layoutIfNeeded];
  expect(paletteCount==previous+1,@"artwork classification completes once for current generation");
  expect(SGAppearanceStyleForView(title)==(light.boolValue?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark),@"raw artwork changes local appearance without global mutation");
  expect(SGRedesignAppearanceStyle()==UIUserInterfaceStyleLight,@"artwork never changes app appearance");
  UIColor *ink=[title.textColor resolvedColorWithTraitCollection:title.traitCollection];expect(contrast(ink,testPlayerField.fieldColor)>=7,@"player artwork field and semantic ink retain contrast");
  NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"player-local-%@.png",light.boolValue?@"light":@"dark"]];[UIImagePNGRepresentation(controlRender(owner.view))writeToFile:path atomically:YES];
 }
 [testPlayerField setArtwork:solidArt(UIColor.blackColor) identity:@"stale-black" animated:NO];[testPlayerField setArtwork:solidArt(UIColor.whiteColor) identity:@"latest-white" animated:NO];
 NSDate *until=[NSDate dateWithTimeIntervalSinceNow:1];while(until.timeIntervalSinceNow>0)[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
 expect(SGAppearanceStyleForView(owner.view)==UIUserInterfaceStyleLight,@"rapid queued palette results retain latest artwork style");
 SGConfigureRedesignAppearance(UIUserInterfaceStyleDark);SGRefreshAppearanceOwners();SGRRefreshNativeSurfaces();
 expect(SGAppearanceStyleForView(title)==UIUserInterfaceStyleLight,@"app Dark change leaves adaptive light artwork local");
 SGSetInt(SGRKeyPlayerArtworkAppearance,0);SGRPlayerApplyAppearancePreference();expect(SGAppearanceStyleForView(title)==UIUserInterfaceStyleDark,@"manual Follow app restores current app Dark immediately");
 [owner.view removeFromSuperview];testPlayerField=nil;SGSetInt(SGRKeyPlayerArtworkAppearance,pref);SGConfigureRedesignAppearance(prior);SGRefreshAppearanceOwners();SGRRefreshNativeSurfaces();
}
