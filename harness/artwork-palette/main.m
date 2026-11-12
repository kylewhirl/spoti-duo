#import <UIKit/UIKit.h>
#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRKit.h"
#import "Redesigned/Kit/SGRAppearance.h"
#import "Redesigned/Kit/SGRNativeTheme.h"
#import "Redesigned/Kit/SGRAccent.h"
#import "Settings/SGModPage.h"
#import "Settings/SGPageStyle.h"
extern BOOL SGTestNativeIsLight(void);
extern void SGTestNativeSetDark(void);

@interface _TtC34PlaylistCuration_AddToPlaylistImpl26ATPContainerViewController : UIViewController @end
@implementation _TtC34PlaylistCuration_AddToPlaylistImpl26ATPContainerViewController @end
@interface _TtC34PlaylistCuration_AddToPlaylistImpl17ATPViewController : UIViewController @end
@implementation _TtC34PlaylistCuration_AddToPlaylistImpl17ATPViewController @end
@interface _TtC14Queue_ViewImpl19QueueViewController : UIViewController @end
@implementation _TtC14Queue_ViewImpl19QueueViewController @end

@interface _TtC28YourLibrary_YourLibraryXImpl25BottomSheetViewController:UIViewController @end
@implementation _TtC28YourLibrary_YourLibraryXImpl25BottomSheetViewController @end
@interface SPTSortingFilteringPickerViewController:UIViewController @end
@implementation SPTSortingFilteringPickerViewController @end

// Independent icon state for testing Swift-style direct property writes that bypass ObjC.
@interface SPTEncoreIconView : UIView
@property(nonatomic,strong) UIColor *foregroundColor;
@property(nonatomic,strong) UIColor *activeForegroundColor;
- (void)bypassForeground:(UIColor *)color active:(UIColor *)active;
@end
@implementation SPTEncoreIconView
- (void)bypassForeground:(UIColor *)color active:(UIColor *)active { _foregroundColor=color;_activeForegroundColor=active; }
@end

// Mock only the proven native semantic provider; bridge, colors, fields and glass are production code.
@interface SPTEncoreColorTheme : NSObject
+ (id)main; + (void)setMain:(id)value; + (id)light; + (id)dark;
@end
static BOOL envOn(const char *key) { const char *value = getenv(key); return value && value[0] == '1'; }
static id objcMain;
static BOOL rejectObjCWrites;
@implementation SPTEncoreColorTheme
+ (id)light { if (envOn("SG_TEST_NIL_THEME")) return nil; static id value; if (!value) value=[self new]; return value; }
+ (id)dark { static id value; if (!value) value=[self new]; return value; }
+ (id)main { return objcMain ?: [self dark]; }
+ (void)setMain:(id)value { if (rejectObjCWrites) return; objcMain = envOn("SG_TEST_REJECT_THEME") ? [self dark] : value; }
@end

__attribute__((constructor(101))) static void defaults(void) {
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"spotifyglass.redesign"];
    const char *mode=getenv("SG_TEST_APPEARANCE");
    if (mode && strcmp(mode,"unset")) [NSUserDefaults.standardUserDefaults setInteger:atoi(mode) forKey:SGRKeyAppearance];
    else [NSUserDefaults.standardUserDefaults removeObjectForKey:SGRKeyAppearance];
}
__attribute__((constructor)) static void resetIndependentFixtureKey(void) {[NSUserDefaults.standardUserDefaults removeObjectForKey:@"spotifyglass.redesign.palette.artwork"];}
static UIColor *chosenAccent;

static int checks, failures;
static void expect(BOOL success, NSString *message) { checks++; if (!success) { failures++; NSLog(@"FAIL: %@", message); } }
static double linear(double c) { return c <= .04045 ? c/12.92 : pow((c+.055)/1.055, 2.4); }
static double luminance(UIColor *color, UIColor *background) {
    CGFloat r=0,g=0,b=0,a=1,br=0,bg=0,bb=0,ba=1;
    [color getRed:&r green:&g blue:&b alpha:&a]; [background getRed:&br green:&bg blue:&bb alpha:&ba];
    return .2126*linear(r*a+br*(1-a))+.7152*linear(g*a+bg*(1-a))+.0722*linear(b*a+bb*(1-a));
}
static double contrast(UIColor *ink, UIColor *background) {
    double a=luminance(ink,background),b=luminance(background,background); return (MAX(a,b)+.05)/(MIN(a,b)+.05);
}
#include "native-surface-tests.h"
#include "owned-live-tests.h"
#import "ambient-palette-tests.h"
#include "native-glyph-tests.h"
#include "live-theme-tests.h"
#include "native-chrome-tests.h"
#include "sheet-appearance-tests.h"
#include "drawer-appearance-tests.h"
#include "status-bar-tests.h"
#include "control-render-tests.h"

static void playlistQueueChecks(void) {
 for (NSString *name in @[@"_TtC34PlaylistCuration_AddToPlaylistImpl26ATPContainerViewController",@"_TtC34PlaylistCuration_AddToPlaylistImpl17ATPViewController",@"_TtC14Queue_ViewImpl19QueueViewController"]) {
  UIViewController *page=[NSClassFromString(name) new]; page.view=[UIView new];page.view.frame=CGRectMake(0,0,380,420);
  page.view.backgroundColor=[UIColor colorWithWhite:.07 alpha:1];
  UILabel *title=[[UILabel alloc]initWithFrame:CGRectMake(20,20,340,44)];title.text=[name containsString:@"Queue"]?@"Queue":@"Saved in";title.font=[UIFont boldSystemFontOfSize:24];title.textColor=UIColor.whiteColor;[page.view addSubview:title];
  UILabel *row=[[UILabel alloc]initWithFrame:CGRectMake(20,90,340,44)];row.text=@"Liked Songs";row.textColor=UIColor.whiteColor;[page.view addSubview:row];
  UIButton *action=[UIButton buttonWithType:UIButtonTypeSystem];action.frame=CGRectMake(20,160,340,44);[action setTitle:@"New playlist" forState:UIControlStateNormal];[page.view addSubview:action];
  action.tintColor=[UIColor colorWithRed:0 green:.4 blue:1 alpha:1];UIColor *accent=action.tintColor;CGRect frame=page.view.frame;
  for (NSNumber *mode in @[@1,@0,@1]) {
   SGRAppearanceApplyMode(mode.integerValue,NO);[page viewWillAppear:NO];[page viewDidLayoutSubviews];
   expect(page.overrideUserInterfaceStyle==(mode.boolValue?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark),@"playlist/queue lifecycle hook registers actual owner");
   expect(contrast(title.textColor,page.view.backgroundColor)>=7 && contrast(row.textColor,page.view.backgroundColor)>=7,@"playlist/queue title and row contrast follows appearance");
   expect(CGRectEqualToRect(frame,page.view.frame) && same(action.tintColor,accent),@"playlist/queue layout and action accent unchanged");
   NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"modal-%@-%@.png",[name containsString:@"Queue"]?@"queue":@"saved",mode.boolValue?@"light":@"dark"]];[UIImagePNGRepresentation(controlRender(page.view)) writeToFile:path atomically:YES];
  }
 }
}

#include "core-scope-tests.h"
#include "player-local-tests.h"
#include "navigation-appearance-tests.h"
#include "search-connection-tests.h"
#include "tonal-native-tests.h"
#include "independent-palette-tests.h"

@interface Delegate : UIResponder <UIApplicationDelegate, UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic) NSUInteger systemTransitions;
- (void)recordSystemAppearance;
@end
@implementation Delegate
- (void)recordSystemAppearance {
    NSDictionary *state=@{@"style":@(SGRedesignAppearanceStyle()),@"transitions":@(self.systemTransitions),
        @"nativeLight":@(SGTestNativeIsLight()),@"objcLight":@(objcMain==[SPTEncoreColorTheme light]),
        @"status":SGRAppearanceStatus()};
    NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"system-live.json"];
    [[NSJSONSerialization dataWithJSONObject:state options:NSJSONWritingPrettyPrinted error:nil] writeToFile:path atomically:YES];
}
- (UISceneConfiguration *)application:(UIApplication *)app configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *configuration=[[UISceneConfiguration alloc]initWithName:@"Tests" sessionRole:session.role];configuration.delegateClass=Delegate.class;return configuration;
}
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    BOOL broken=envOn("SG_TEST_NIL_THEME") || envOn("SG_TEST_REJECT_THEME") || envOn("SG_TEST_REJECT_NATIVE_THEME");
    NSInteger mode=SGInt(SGRKeyAppearance,SGRAppearanceSystem);
    BOOL wantLight=!broken && (mode==1 || (mode==2 && UIScreen.mainScreen.traitCollection.userInterfaceStyle==UIUserInterfaceStyleLight));
    expect(SGRedesignLightAppearance()==wantLight,@"resolved mode and fail-closed behavior");
    expect(SGTestNativeIsLight()==wantLight,@"independent native Swift main matches owned kit");
    expect([SPTEncoreColorTheme main]==(wantLight ? [SPTEncoreColorTheme light] : [SPTEncoreColorTheme dark]),@"native main matches kit");
    if (!broken) {
        id originalObjC = objcMain;
        objcMain = wantLight ? [SPTEncoreColorTheme dark] : [SPTEncoreColorTheme light];
        expect([SGRAppearanceStatus() containsString:@"Retry appearance"],@"direct ObjC-wrapper drift is visible in applied status");
        objcMain = originalObjC;
        expect(SGRNativeThemeMatches(wantLight),@"native ABI readback matches selected theme");
        for (NSInteger i=0;i<1000;i++) expect(SGRSetNativeTheme(wantLight,nil),@"repeated native transfers retain valid Swift objects");
        BOOL rolledBack = !SGRSetNativeTheme(!wantLight,^BOOL{ return NO; });
        expect(rolledBack && SGTestNativeIsLight()==wantLight,@"failed ObjC commit rolls native Swift main back");
        SGTestNativeSetDark();
        expect(!wantLight || [SGRAppearanceStatus() containsString:@"Retry appearance"],@"native-only drift is visible in applied status");
        expect(SGRSetNativeTheme(wantLight,nil),@"restore selected native theme after drift fixture");
        [SPTEncoreColorTheme setMain:wantLight ? [SPTEncoreColorTheme dark] : [SPTEncoreColorTheme light]];
        expect([SPTEncoreColorTheme main]==(wantLight ? [SPTEncoreColorTheme light] : [SPTEncoreColorTheme dark]),@"native writes cannot drift away from selected appearance");
    }
    if (envOn("SG_TEST_REJECT_THEME")) {
        unsetenv("SG_TEST_REJECT_THEME");
        expect(SGRAppearanceApplyMode(SGRAppearanceLight,NO),@"initial provider rejection can recover without relaunch");
        [SPTEncoreColorTheme setMain:[SPTEncoreColorTheme dark]];
        expect(objcMain==[SPTEncoreColorTheme light] && SGTestNativeIsLight(),@"recovered bridge hooks pin the eventual selected theme");
        expect(SGRAppearanceApplyMode(SGRAppearanceDark,NO),@"recovery fixture restores dark fallback visuals");
        setenv("SG_TEST_REJECT_THEME","1",1);
    }
    NSLog(@"FIXTURE stage nativeSurface"); nativeSurfaceChecks(wantLight);
    NSLog(@"FIXTURE stage owned"); ownedLiveChecks();
    NSLog(@"FIXTURE stage chrome"); nativeChromeChecks();
    if (!broken) { NSLog(@"FIXTURE stage live"); liveThemeChecks(); NSLog(@"FIXTURE stage sheet"); sheetAppearanceChecks(); playlistQueueChecks(); coreAppearanceScopeChecks(self.window.rootViewController.view); playerLocalChecks(self.window.rootViewController.view); NSLog(@"FIXTURE stage drawer"); drawerAppearanceChecks(); NSLog(@"FIXTURE stage status"); statusBarAppearanceChecks(); }
    NSLog(@"FIXTURE stage glyph"); nativeGlyphChecks(wantLight);
    ambientPaletteChecks();
    UIViewController *controller=[UIViewController new];
    controller.overrideUserInterfaceStyle=SGRedesignAppearanceStyle();
    self.window=[[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController=controller;
    [self.window makeKeyAndVisible];
    controller.view.backgroundColor=SGAppearanceColor(UIColor.whiteColor,UIColor.blackColor);
    CGFloat w=controller.view.bounds.size.width;
    SGRArtworkField *field=[[SGRArtworkField alloc] initWithFrame:controller.view.bounds];
    field.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    field.flows=YES;
    [controller.view addSubview:field];
    UIImage *art=[[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(300,300)] imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [[UIColor colorWithRed:.05 green:.35 blue:.8 alpha:1] setFill]; UIRectFill(CGRectMake(0,0,300,300));
        [[UIColor colorWithRed:.8 green:.1 blue:.35 alpha:1] setFill]; [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(75,-55,300,300)] fill];
    }];
    [field setArtwork:art identity:@"fixture" animated:NO];
    UIImageView *cover=[[UIImageView alloc] initWithImage:art];
    cover.frame=CGRectMake((w-220)/2,105,220,220); cover.layer.cornerRadius=12;cover.clipsToBounds=YES;
    [controller.view addSubview:cover];
    NSArray *texts=@[@"Appearance preview",@"Native theme • album artwork preserved",@"Live appearance, with scoped semantic roles"];
    NSArray *inks=@[SGRPrimary(),SGRSecondary(),SGRTertiary()];
    for (NSInteger i=0;i<3;i++) {
        UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake(20,350+i*36,w-40,32)];
        label.text=texts[i];label.textColor=inks[i];label.textAlignment=NSTextAlignmentCenter;
        label.font=[UIFont systemFontOfSize:i?14:26 weight:i?UIFontWeightRegular:UIFontWeightBold];
        [controller.view addSubview:label];
    }
    static char key;
    UIButton *control=[[UIButton alloc] initWithFrame:CGRectMake((w-180)/2,492,180,50)];
    [control setTitle:@"▶  Play" forState:UIControlStateNormal];
    [control setTitleColor:SGRAccent() forState:UIControlStateNormal];
    [controller.view addSubview:control];
    UIView *glass=SGRGlassCapsuleInside(control,&key,control.bounds.size,YES);
    expect(glass.overrideUserInterfaceStyle==SGRedesignAppearanceStyle(),@"glass style matches foreground");
    CALayer *grey=[CALayer layer];grey.backgroundColor=[UIColor colorWithWhite:.07 alpha:1].CGColor;
    CGFloat g=CGColorGetComponents(grey.backgroundColor)[0];
    expect(wantLight ? fabs(g-.07)<.001 : g<.001,@"AMOLED hook disabled in light");
    expect(SGRIsBaseSurface(UIColor.whiteColor.CGColor)==wantLight,@"white surface detection limited to light");
    expect(!SGRIsBaseSurface(UIColor.redColor.CGColor),@"artwork colors never guessed as surfaces");
    expect(cover.image==art,@"artwork image retained without recoloring");
    [controller.view layoutIfNeeded];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),dispatch_get_main_queue(),^{
        SGSetInt(SGRKeyAccent,0x8844CC);
        SGSetInt(SGRKeyAccentArtwork,1);
        UIColor *retained=SGRAccent();
        for (NSNumber *light in @[@NO,@YES]) {
            SGRAppearanceApplyMode(light.boolValue?SGRAppearanceLight:SGRAppearanceDark,NO);
            for(UIColor *c in @[UIColor.blackColor,UIColor.whiteColor,UIColor.redColor,UIColor.blueColor,UIColor.greenColor]) {
                SGRSetArtworkAccent(c,light.boolValue);
                expect(contrast(SGRAccentColor(),UIColor.blackColor)>=4.5,@"native fill supports black glyph");
                if(light.boolValue) expect(contrast(retained,UIColor.whiteColor)>=4.5,@"retained semantic light accent contrast");
            }
        }
        SGRSetArtworkAccent(UIColor.redColor,YES); UIColor *first=[retained resolvedColorWithTraitCollection:self.window.traitCollection];
        SGRSetArtworkAccent(UIColor.blueColor,YES); UIColor *second=[retained resolvedColorWithTraitCollection:self.window.traitCollection];
        expect(![first isEqual:second],@"same-theme retained semantic accent resolves new hue");
        expect(SGInt(SGRKeyAccent,0)==0x8844CC,@"manual accent preserved");
        SGRSetArtworkAccent(nil,YES);
        expect([SGRAccentColor() isEqual:[UIColor colorWithRed:0x88/255.0 green:0x44/255.0 blue:0xCC/255.0 alpha:1]],@"missing art manual fallback");
        SGSetInt(SGRKeyAccentArtwork,0); SGRSetArtworkAccent(UIColor.redColor,YES);
        expect([SGRAccentColor() isEqual:[UIColor colorWithRed:0x88/255.0 green:0x44/255.0 blue:0xCC/255.0 alpha:1]],@"independent accent disabled");
        SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
        expect(!SGRAppearanceNeedsRestart() || SGRedesignAppearanceStyle()!=UIUserInterfaceStyleUnspecified,@"artwork mode applies without bitmap");
        extern UIImage *fixtureArt; extern NSString *fixtureIdentity;
        fixtureArt=[UIImage systemImageNamed:@"music.note"]; fixtureIdentity=@"first";
        SGRAppearanceArtworkDidChange(); NSUInteger oldGeneration=SGRAppearanceArtworkGeneration();
        fixtureIdentity=@"second"; SGRAppearanceArtworkDidChange(); NSUInteger latest=SGRAppearanceArtworkGeneration();
        SGRPalette *dark=[SGRPalette new]; [dark setValue:@(.01) forKey:@"artworkLuminance"]; [dark setValue:UIColor.redColor forKey:@"edgeColor"];
        SGRPalette *bright=[SGRPalette new]; [bright setValue:@(.9) forKey:@"artworkLuminance"]; [bright setValue:UIColor.blueColor forKey:@"edgeColor"];
        SGRAppearanceAcceptArtworkPalette(bright,@"second",latest); SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
        expect(SGRedesignLightAppearance(),@"global artwork applies without player owner");
        SGRAppearanceAcceptArtworkPalette(dark,@"first",oldGeneration); SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
        expect(SGRedesignLightAppearance(),@"old palette generation ignored");
        SGRAppearanceAcceptArtworkPalette(dark,@"wrong",latest); SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
        expect(SGRedesignLightAppearance(),@"wrong identity ignored");
        SGRAppearanceAcceptArtworkPalette(dark,@"second",latest); SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
        expect(!SGRedesignLightAppearance(),@"current dark artwork updates globally");
        SGSetInt(SGRKeyAccentArtwork,1);SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);UIColor *priorPendingAccent=SGRAccentColor();
        extern BOOL fixturePending;
        fixturePending=YES;fixtureArt=nil;SGRAppearanceArtworkDidChange();SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
        expect(!SGRedesignLightAppearance(),@"pending next image retains prior dark instead of System flash");expect([priorPendingAccent isEqual:SGRAccentColor()],@"pending next image retains last accent");
        fixtureArt=[UIImage systemImageNamed:@"music.note"];fixtureIdentity=@"third-dark";SGRAppearanceArtworkDidChange();NSUInteger third=SGRAppearanceArtworkGeneration();SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
        expect(!SGRedesignLightAppearance(),@"pending palette retains prior dark without flash");
        SGRAppearanceAcceptArtworkPalette(dark,@"third-dark",third);SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);expect(!SGRedesignLightAppearance(),@"dark-to-dark remains dark");
        fixturePending=NO;
        SGRAppearanceApplyMode(SGRAppearanceLight,NO);
        expect(SGRedesignLightAppearance(),@"fixed light overrides dark artwork");
        fixtureArt=nil; SGRAppearanceArtworkDidChange(); SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
        UIUserInterfaceStyle system=self.window.windowScene.traitCollection.userInterfaceStyle;
        expect(SGRedesignLightAppearance()==(system==UIUserInterfaceStyleLight),@"missing artwork follows system");
        SGSetInt(SGRKeyAccentArtwork,1);
        for(NSNumber *light in @[@NO,@YES]) {
            SGRAppearanceApplyMode(light.boolValue?SGRAppearanceLight:SGRAppearanceDark,NO);
            SGRSetArtworkAccent([UIColor colorWithRed:.15 green:.3 blue:.8 alpha:1],light.boolValue);
            UIView *sample=[[UIView alloc]initWithFrame:CGRectMake(0,0,390,400)];
            sample.backgroundColor=SGRNeutralField(); SGRegisterAppearanceView(sample);
            UILabel *heading=[[UILabel alloc]initWithFrame:CGRectMake(24,32,340,48)];heading.text=@"Match artwork";heading.font=[UIFont boldSystemFontOfSize:28];heading.textColor=SGRPrimary();[sample addSubview:heading];
            UILabel *link=[[UILabel alloc]initWithFrame:CGRectMake(24,108,340,44)];link.text=@"Artwork accent · View album";link.textColor=SGRAccent();[sample addSubview:link];
            UIButton *play=[[UIButton alloc]initWithFrame:CGRectMake(24,180,170,54)];play.backgroundColor=SGRAccentColor();[play setTitle:@"▶ Play" forState:UIControlStateNormal];[play setTitleColor:UIColor.blackColor forState:UIControlStateNormal];play.layer.cornerRadius=27;[sample addSubview:play];
            NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:light.boolValue?@"global-artwork-light.png":@"global-artwork-dark.png"];
            [UIImagePNGRepresentation(controlRender(sample)) writeToFile:path atomically:YES];SGUnregisterAppearanceView(sample);
        }
        SGSetInt(SGRKeyAccentArtwork,1); SGRAppearanceApplyMode(SGRAppearanceLight,NO);
        UIView *retainedCanvas=[[UIView alloc]initWithFrame:CGRectMake(0,0,390,300)];retainedCanvas.backgroundColor=UIColor.whiteColor;
        UIColor *semantic=[UIColor colorWithRed:30/255.0 green:215/255.0 blue:96/255.0 alpha:1];
        UILabel *retainedLabel=[[UILabel alloc]initWithFrame:CGRectMake(20,20,350,40)];retainedLabel.text=@"Native retained accent";retainedLabel.textColor=[semantic colorWithAlphaComponent:.8];[retainedCanvas addSubview:retainedLabel];
        UIButton *retainedButton=[[UIButton alloc]initWithFrame:CGRectMake(20,70,350,44)];[retainedButton setTitle:@"Retained button" forState:0];[retainedButton setTitleColor:semantic forState:0];[retainedCanvas addSubview:retainedButton];
        UIImageView *retainedTint=[[UIImageView alloc]initWithImage:[[UIImage systemImageNamed:@"heart.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];retainedTint.frame=CGRectMake(20,130,40,40);retainedTint.tintColor=semantic;[retainedCanvas addSubview:retainedTint];
        UIView *retainedBG=[[UIView alloc]initWithFrame:CGRectMake(80,130,40,40)];retainedBG.backgroundColor=semantic;[retainedCanvas addSubview:retainedBG];
        CAShapeLayer *retainedShape=[CAShapeLayer layer];retainedShape.path=[UIBezierPath bezierPathWithRect:CGRectMake(140,130,50,40)].CGPath;
        CGFloat originalComponents[]={30/255.0,215/255.0,96/255.0,1};CGColorSpaceRef originalSpace=CGColorSpaceCreateDeviceRGB();CGColorRef originalGreen=CGColorCreate(originalSpace,originalComponents);
        retainedShape.fillColor=semantic.CGColor;retainedShape.strokeColor=originalGreen;retainedShape.lineWidth=4;[retainedCanvas.layer addSublayer:retainedShape];CGColorRelease(originalGreen);CGColorSpaceRelease(originalSpace);
        for(NSNumber *light in @[@YES,@NO]) {
            SGRAppearanceApplyMode(light.boolValue?SGRAppearanceLight:SGRAppearanceDark,NO);
            retainedCanvas.backgroundColor=light.boolValue?UIColor.whiteColor:UIColor.blackColor;
            SGRSetArtworkAccent(UIColor.redColor,light.boolValue); UIImage *before=controlRender(retainedCanvas);
            UIColor *labelBefore=retainedLabel.textColor,*buttonBefore=[retainedButton titleColorForState:0],*tintBefore=retainedTint.tintColor,*bgBefore=retainedBG.backgroundColor;id fillBefore=(__bridge id)retainedShape.fillColor,strokeBefore=(__bridge id)retainedShape.strokeColor;
            SGRSetArtworkAccent(UIColor.blueColor,light.boolValue); UIImage *after=controlRender(retainedCanvas);
            expect(![UIImagePNGRepresentation(before) isEqual:UIImagePNGRepresentation(after)],@"same retained native canvas rendered pixels change");
            for(NSValue *region in @[[NSValue valueWithCGRect:retainedLabel.frame],[NSValue valueWithCGRect:retainedButton.frame],[NSValue valueWithCGRect:retainedTint.frame],[NSValue valueWithCGRect:retainedBG.frame],[NSValue valueWithCGRect:CGRectMake(138,128,54,44)]]) {
                CGRect crop=region.CGRectValue;crop=CGRectApplyAffineTransform(crop,CGAffineTransformMakeScale(before.scale,before.scale));
                CGImageRef a=CGImageCreateWithImageInRect(before.CGImage,crop),b=CGImageCreateWithImageInRect(after.CGImage,crop);
                expect(![UIImagePNGRepresentation([UIImage imageWithCGImage:a]) isEqual:UIImagePNGRepresentation([UIImage imageWithCGImage:b])],@"individual retained control pixels change");CGImageRelease(a);CGImageRelease(b);
            }

            CGFloat ar,ag,ab,aa;[retainedLabel.textColor getRed:&ar green:&ag blue:&ab alpha:&aa];expect(fabs(aa-.8)<.001,@"derived source alpha preserved");expect(![labelBefore isEqual:retainedLabel.textColor],@"retained UILabel updated");expect(![buttonBefore isEqual:[retainedButton titleColorForState:0]],@"retained UIButton title updated");expect(![tintBefore isEqual:retainedTint.tintColor],@"retained UIView tint updated");expect(![bgBefore isEqual:retainedBG.backgroundColor],@"retained UIView background updated");expect(![fillBefore isEqual:(__bridge id)retainedShape.fillColor],@"retained shape fill updated");expect(![strokeBefore isEqual:(__bridge id)retainedShape.strokeColor],@"retained shape stroke updated");
            NSString *dir=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
            [UIImagePNGRepresentation(before) writeToFile:[dir stringByAppendingPathComponent:light.boolValue?@"retained-light-before.png":@"retained-dark-before.png"] atomically:YES];
            [UIImagePNGRepresentation(after) writeToFile:[dir stringByAppendingPathComponent:light.boolValue?@"retained-light-after.png":@"retained-dark-after.png"] atomically:YES];
        }
        SGSetInt(SGRKeyAccentArtwork,0); SGSetInt(SGRKeyAccent,0x8844CC); SGRSetArtworkAccent(nil,YES);
        UIColor *manual=[UIColor colorWithRed:0x88/255.0 green:0x44/255.0 blue:0xCC/255.0 alpha:1];
        CGFloat mr,mg,mb,ma;[retainedLabel.textColor getRed:&mr green:&mg blue:&mb alpha:&ma];expect(fabs(mr-0x88/255.0)<.001 && fabs(mg-0x44/255.0)<.001 && fabs(mb-0xCC/255.0)<.001,@"manual native RGB restored exactly");
        SGSetInt(SGRKeyAccentArtwork,1); SGRSetArtworkAccent(UIColor.blueColor,YES);
        retainedLabel.textColor=UIColor.magentaColor;retainedBG.backgroundColor=nil;retainedShape.fillColor=nil;
        SGRSetArtworkAccent(UIColor.greenColor,NO);
        expect([retainedLabel.textColor isEqual:UIColor.magentaColor],@"unrelated reassignment preserved");expect(!retainedBG.backgroundColor && !retainedShape.fillColor,@"nil assignment removes tracking");
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(16,16),NO,1);
        CGContextRef ctx=UIGraphicsGetCurrentContext();CGContextSetRGBFillColor(ctx,30/255.0,215/255.0,96/255.0,1);CGContextFillRect(ctx,CGRectMake(0,0,16,16));
        UIImage *greenBitmap=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();
        SGRPaletteRequest rawRequest={0};
        [SGRPalette paletteForImage:greenBitmap request:rawRequest completion:^(SGRPalette *palette) {
            CGFloat r,g,b,a;[palette.edgeColor getRed:&r green:&g blue:&b alpha:&a];
            expect(fabs(r-30/255.0)<.02 && fabs(g-215/255.0)<.02 && fabs(b-96/255.0)<.02,@"real green artwork palette remains raw under accent hooks");
            NSLog(@"FINAL ARTWORK CHECKS: %ld checks %ld failures -- %@",(long)checks,(long)failures,failures?@"FAIL":@"PASS");
        }];
        dispatch_group_t stress=dispatch_group_create();
        for(int worker=0;worker<4;worker++) dispatch_group_async(stress,dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            for(int n=0;n<1000;n++) { @autoreleasepool {
                UIColor *initialized=[[UIColor alloc]initWithRed:30/255.0 green:215/255.0 blue:96/255.0 alpha:1];
                UIColor *factory=[UIColor colorWithRed:30/255.0 green:215/255.0 blue:96/255.0 alpha:1];
                UIColor *derived=[factory colorWithAlphaComponent:.6];
                CGColorRef copy=CGColorCreateCopy(initialized.CGColor);CGColorRelease(copy);
                (void)derived.CGColor;
            } }
        });
        dispatch_group_wait(stress,DISPATCH_TIME_FOREVER);
        expect(YES,@"4000 multithread alloc-init factory alpha autorelease pools drained");
        SGRAppearanceApplyMode(SGRAppearanceLight,NO);
        UIView *lateScope=[[UIView alloc]initWithFrame:CGRectMake(0,0,300,300)];SGSetAppearanceScope(lateScope,UIUserInterfaceStyleDark);
        SGRArtworkField *lateField=[[SGRArtworkField alloc]initWithFrame:lateScope.bounds];
        [lateField setProvisionalColor:[UIColor colorWithRed:.15 green:.13 blue:.02 alpha:1]];
        CGFloat beforeAttachment=luminance(lateField.fieldColor,UIColor.blackColor);
        [lateScope addSubview:lateField];
        NSLog(@"ATTACHMENT MISMATCH style=%ld cachedL=%.3f beforeL=%.3f",(long)SGAppearanceStyleForView(lateField),luminance(lateField.fieldColor,UIColor.blackColor),beforeAttachment);
        [lateField refreshLocalAppearance];
        NSLog(@"ATTACHMENT REFRESH style=%ld cachedL=%.3f",(long)SGAppearanceStyleForView(lateField),luminance(lateField.fieldColor,UIColor.blackColor));
        SGSetInt(SGRKeyAppearance,SGRAppearanceLight);SGSetInt(SGRKeyPlayerArtworkAppearance,1);
        UIViewController *splitOwner=[UIViewController new];splitOwner.view=[[UIView alloc]initWithFrame:CGRectMake(0,0,300,300)];
        testPlayerField=[[SGRArtworkField alloc]initWithFrame:CGRectMake(0,0,300,300)];
        UIView *independentPlane=[[UIView alloc]initWithFrame:testPlayerField.bounds];[independentPlane addSubview:testPlayerField];
        [testPlayerField setProvisionalColor:[UIColor colorWithRed:.15 green:.13 blue:.02 alpha:1]];
        SGRPlayerRegisterArtworkAppearance(splitOwner);SGRPlayerSetArtworkLuminance(.01);SGRPlayerApplyAppearancePreference();
        NSLog(@"SPLIT PLAYER ownerStyle=%ld fieldStyle=%ld fieldL=%.3f",(long)SGAppearanceStyleForView(splitOwner.view),(long)SGAppearanceStyleForView(testPlayerField),luminance(testPlayerField.fieldColor,UIColor.blackColor));
        SGSetAppearanceScope(testPlayerField,UIUserInterfaceStyleDark);[testPlayerField refreshLocalAppearance];
        NSLog(@"SPLIT FIELD SCOPE ownerStyle=%ld fieldStyle=%ld fieldL=%.3f",(long)SGAppearanceStyleForView(splitOwner.view),(long)SGAppearanceStyleForView(testPlayerField),luminance(testPlayerField.fieldColor,UIColor.blackColor));
        SGClearAppearanceScope(testPlayerField);testPlayerField=nil;
        for(NSString *name in @[@"_TtC28YourLibrary_YourLibraryXImpl25BottomSheetViewController",@"SPTSortingFilteringPickerViewController"]) {
            UIViewController *sheet=[NSClassFromString(name) new];sheet.view=[[UIView alloc]initWithFrame:CGRectMake(0,0,390,420)];sheet.view.backgroundColor=[UIColor colorWithWhite:.07 alpha:1];
            UILabel *heading=[[UILabel alloc]initWithFrame:CGRectMake(20,20,340,44)];heading.text=@"Filter by";heading.font=[UIFont boldSystemFontOfSize:24];heading.textColor=UIColor.whiteColor;[sheet.view addSubview:heading];
            UIButton *chip=[UIButton buttonWithType:UIButtonTypeCustom];chip.frame=CGRectMake(20,90,170,44);[chip setTitle:@"Playlists" forState:UIControlStateNormal];[chip setTitle:@"Playlists ✓" forState:UIControlStateSelected];[chip setTitleColor:UIColor.blackColor forState:UIControlStateNormal];chip.backgroundColor=[UIColor colorWithWhite:16/255.0 alpha:1];[sheet.view addSubview:chip];
            UIButton *selected=[UIButton buttonWithType:UIButtonTypeCustom];selected.frame=CGRectMake(200,90,170,44);selected.selected=YES;[selected setTitle:@"Downloaded ✓" forState:UIControlStateSelected];selected.backgroundColor=[UIColor colorWithRed:.2 green:.5 blue:.9 alpha:1];[selected setTitleColor:UIColor.blackColor forState:UIControlStateSelected];[sheet.view addSubview:selected];UIColor *accent=selected.backgroundColor;CGRect geometry=chip.frame;
            [sheet viewDidLoad];
            for(NSNumber *light in @[@YES,@NO,@YES]) {
                SGRAppearanceApplyMode(light.boolValue?SGRAppearanceLight:SGRAppearanceDark,NO);[sheet viewWillAppear:NO];[sheet viewDidLayoutSubviews];
                expect(sheet.overrideUserInterfaceStyle==(light.boolValue?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark),@"library filter owner hooks follow appearance");
                expect(contrast(heading.textColor,sheet.view.backgroundColor)>=7,@"library filter heading readable");
                [sheet.view layoutIfNeeded];expect(contrast(chip.titleLabel.textColor,chip.backgroundColor)>=4.5,@"library filter rendered chip label readable");
                expect(selected.selected && same(selected.backgroundColor,accent),@"library filter selected chip accent/state preserved");
                expect(CGRectEqualToRect(chip.frame,geometry),@"library filter geometry preserved");
                UIView *unrelated=[UIView new];unrelated.backgroundColor=[UIColor colorWithWhite:16/255.0 alpha:1];SGRApplyNativeLightSurface(unrelated,NO);CGFloat ur,ug,ub,ua;[unrelated.backgroundColor getRed:&ur green:&ug blue:&ub alpha:&ua];if(light.boolValue)expect(fabs(ur-16/255.0)<.001,@"same chip RGB untouched outside library filter scope in Light");

                NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"library-filter-%@-%@.png",[name hasPrefix:@"SPT"]?@"picker":@"sheet",light.boolValue?@"light":@"dark"]];[UIImagePNGRepresentation(controlRender(sheet.view))writeToFile:path atomically:YES];
            }
        }
        SGRAppearanceApplyMode(SGRAppearanceLight,NO);
        UIView *tile=[[UIView alloc]initWithFrame:CGRectMake(20,100,280,60)];[self.window addSubview:tile];
        UIView *fill=[[UIView alloc]initWithFrame:tile.bounds];[tile addSubview:fill];
        UIView *row=[[UIView alloc]initWithFrame:tile.bounds];[tile addSubview:row];
        UIView *square=[[UIView alloc]initWithFrame:CGRectMake(0,0,60,60)];[row addSubview:square];
        UIView *holder=[[UIView alloc]initWithFrame:square.bounds];holder.accessibilityIdentifier=@"Encore.ImageView";[square addSubview:holder];
        UIImageView *cover=[[UIImageView alloc]initWithFrame:holder.bounds];cover.image=art;[holder addSubview:cover];
        extern void SGRHomeStyleTile(UIView *);
        SGRHomeStyleTile(tile);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{
            UIView *surface=tile.subviews[1];
            UIColor *light=surface.backgroundColor;
            SGRAppearanceApplyMode(SGRAppearanceDark,NO);
            UIColor *dark=surface.backgroundColor;
            expect(luminance(light,UIColor.whiteColor)>.5,@"home tile light tint");
            expect(luminance(dark,UIColor.blackColor)<.15,@"retained home tile dark tint");
            SGRAppearanceApplyMode(SGRAppearanceLight,NO);
            expect([surface.backgroundColor isEqual:light],@"retained home tile restores light tint");
            UIView *selection=[[UIView alloc]initWithFrame:CGRectMake(0,0,60,60)];SGRegisterAppearanceView(selection);[self.window addSubview:selection];
            selection.backgroundColor=SGAppearanceColor([UIColor colorWithWhite:1 alpha:.55],[UIColor colorWithWhite:0 alpha:.55]);
            SGRAppearanceApplyMode(SGRAppearanceLight,NO);[selection layoutIfNeeded];
            NSLog(@"NAVSELECTION light layer %@",[UIColor colorWithCGColor:selection.layer.backgroundColor]);
            SGRAppearanceApplyMode(SGRAppearanceDark,NO);[selection layoutIfNeeded];
            NSLog(@"NAVSELECTION dark layer %@",[UIColor colorWithCGColor:selection.layer.backgroundColor]);
            UIView *home=[UIView new];SGRAppearanceApplyMode(SGRAppearanceLight,NO);SGRApplyNativeLightSurface(home,YES);
            UILabel *secondary=[UILabel new];[home addSubview:secondary];secondary.textColor=[UIColor colorWithWhite:101/255.0 alpha:1];secondary.attributedText=[[NSAttributedString alloc]initWithString:@"Mix description" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:101/255.0 alpha:1]}];
            SGRAppearanceApplyMode(SGRAppearanceDark,NO);
            NSLog(@"HOME101 retained text %@ attr %@",secondary.textColor,[secondary.attributedText attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL]);
            secondary.textColor=[UIColor colorWithWhite:101/255.0 alpha:1];secondary.attributedText=[[NSAttributedString alloc]initWithString:@"Mix description" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:101/255.0 alpha:1]}];
            NSLog(@"HOME101 reassigned text %@ attr %@",secondary.textColor,[secondary.attributedText attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL]);
            UILabel *fresh=[UILabel new];[home addSubview:fresh];fresh.textColor=[UIColor colorWithWhite:101/255.0 alpha:1];
            NSLog(@"HOME101 fresh dark text %@",fresh.textColor);
            expect(luminance(fresh.textColor,UIColor.blackColor)<.15,@"fresh101 unchanged outside HomeCard");
            UIView *card=[UIView new];card.accessibilityIdentifier=@"Components.UI.HomeCard";[home addSubview:card];
            UILabel *desc=[UILabel new];[card addSubview:desc];desc.textColor=[UIColor colorWithWhite:101/255.0 alpha:1];desc.attributedText=[[NSAttributedString alloc]initWithString:@"Mix description" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:101/255.0 alpha:1]}];
            expect(luminance(desc.textColor,UIColor.blackColor)>.4,@"fresh HomeCard101 becomes dark secondary");
            expect(luminance([desc.attributedText attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL],UIColor.blackColor)>.4,@"fresh HomeCard attributed101 becomes dark secondary");
            SGRAppearanceApplyMode(SGRAppearanceLight,NO);expect(luminance(desc.textColor,UIColor.blackColor)<.15,@"HomeCard101 restores Light secondary");
            SGRAppearanceApplyMode(SGRAppearanceDark,NO);

            SGRegisterAppearanceRefresh(selection,^(UIView *owner){owner.backgroundColor=SGRedesignLightAppearance()?[UIColor colorWithWhite:1 alpha:.55]:[UIColor colorWithWhite:0 alpha:.55];});
            SGRAppearanceApplyMode(SGRAppearanceLight,NO);SGRAppearanceApplyMode(SGRAppearanceDark,NO);
            NSLog(@"NAVSELECTION explicit dark layer %@",[UIColor colorWithCGColor:selection.layer.backgroundColor]);
            expect(luminance([UIColor colorWithCGColor:selection.layer.backgroundColor],UIColor.blackColor)<.01,@"explicit rail callback dark selection");
            SGRAppearanceApplyMode(SGRAppearanceDark,NO);
            UIColor *originalCover=surface.backgroundColor;
            SGSetInt(SGRKeyAppearance,SGRAppearanceArtwork);SGRSetArtworkTonalPalette(UIColor.redColor,YES);SGInvalidateAppearanceColors();SGRefreshAppearanceOwners();SGRRefreshNativeSurfaces();
            UIColor *redTile=surface.backgroundColor;
            SGRSetArtworkTonalPalette(UIColor.blueColor,YES);SGInvalidateAppearanceColors();SGRefreshAppearanceOwners();SGRRefreshNativeSurfaces();
            expect(!same(redTile,surface.backgroundColor),@"Home tile same-dark tonal hue changes");
            SGRSetArtworkTonalPalette(nil,NO);SGSetInt(SGRKeyAppearance,SGRAppearanceDark);SGInvalidateAppearanceColors();SGRefreshAppearanceOwners();SGRRefreshNativeSurfaces();
            expect(same(originalCover,surface.backgroundColor),@"Home tile disabling tonal restores own-cover tint");
            tonalNativeChecks();
            independentPaletteChecks();
            NSLog(@"HOME RETAINED CHECKS %ld failures",(long)failures);
            NSLog(@"ARTWORK SUITE COMPLETE: %ld checks %ld failures -- %@",(long)checks,(long)failures,failures?@"FAIL":@"PASS");
        });
        NSLog(@"GLOBAL ARTWORK CHECKS: %ld checks %ld failures -- %@",(long)checks,(long)failures,failures?@"FAIL":@"PASS");
        return;
        if (!broken) searchConnectionChecks(self.window);
        controlRenderingChecks(self.window);
        if (!broken) nativeNavigationAppearanceChecks(self.window);
        if (wantLight) {
            expect(contrast(SGRPrimary(),field.fieldColor)>=7,@"light primary contrast");
            expect(contrast(SGRSecondary(),field.fieldColor)>=4.5,@"light secondary contrast");
            expect(contrast(SGRTertiary(),field.fieldColor)>=4.5,@"light tertiary contrast");
            expect(contrast(SGRAccent(),field.fieldColor)>=4.5,@"light accent contrast");
            for (UIColor *sample in @[UIColor.whiteColor, UIColor.yellowColor, UIColor.cyanColor, UIColor.greenColor,
                                      UIColor.magentaColor, UIColor.redColor, UIColor.blueColor, UIColor.blackColor]) {
                chosenAccent=sample;
                expect(contrast(SGRAccent(),[UIColor colorWithWhite:0.90 alpha:1])>=4.5,@"chosen accent stays readable on pale controls");
            }
            chosenAccent=nil;
            expect(luminance(field.fieldColor,UIColor.whiteColor)>.82,@"animated artwork surface stays pale");
        } else expect(contrast(SGRPrimary(),field.fieldColor)>=5.5,@"dark primary contrast");
        for (NSInteger i=0;i<50;i++) { field.frame=CGRectMake(0,0,i%2?852:393,i%2?393:852); [field setNeedsLayout]; [field layoutIfNeeded]; }
        field.frame=controller.view.bounds;[field layoutIfNeeded];
        expect(field.layer.sublayers.count==5,@"repeat resize does not accumulate appearance layers");
        UILabel *status=[[UILabel alloc] initWithFrame:CGRectMake(20,580,w-40,50)];
        status.numberOfLines=2;status.textAlignment=NSTextAlignmentCenter;status.textColor=SGRPrimary();
        status.text=[NSString stringWithFormat:@"%@ mode\n%d checks, %d failures",wantLight?@"Light":@"Dark",checks,failures];[controller.view addSubview:status];
        if (envOn("SG_TEST_SELECTOR")) {
            NSArray<SGModRow *> *rows=SGRAppearanceRows();
            SGModPage *page=[[SGModPage alloc] initWithTitle:@"Appearance" intro:nil sections:@[SGSection(nil,rows)] footer:nil];
            UINavigationController *nav=[[UINavigationController alloc] initWithRootViewController:page];
            self.window.rootViewController=nav;
            UITableViewController *picker=(UITableViewController *)rows.firstObject.page();
            [nav pushViewController:picker animated:NO];
            [picker.view layoutIfNeeded];
            NSInteger target=wantLight?SGRAppearanceDark:SGRAppearanceLight;
            [picker.tableView.delegate tableView:picker.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:target inSection:0]];
            expect(SGInt(SGRKeyAppearance,-1)==target,@"real settings choice persists exact appearance key");
            expect(SGRAppearanceNeedsRestart(),@"queued selection distinguished until main-queue transaction");
            expect(SGRedesignLightAppearance()==wantLight && SGTestNativeIsLight()==wantLight,@"picker coalesces before changing either provider");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{
                expect(!SGRAppearanceNeedsRestart() && SGRedesignLightAppearance()!=wantLight && SGTestNativeIsLight()!=wantLight,@"real picker applies native and owned appearance live");
                expect(!nav.presentedViewController && nav.topViewController==page,@"picker returns without a restart alert or navigation reconstruction");
                NSLog(@"APPEARANCE CHECKS: %d checks, %d failures -- %@",checks,failures,failures?@"FAIL":@"PASS");
            });
        } else NSLog(@"APPEARANCE CHECKS: %d checks, %d failures -- %@",checks,failures,failures?@"FAIL":@"PASS");
        if (envOn("SG_TEST_LIVE_SYSTEM")) {
            self.systemTransitions=0;
            SGRegisterAppearanceRefresh(self, ^(id owner) {
                Delegate *delegate=owner;
                delegate.systemTransitions++;
                [delegate recordSystemAppearance];
            });
            [self recordSystemAppearance];
            NSLog(@"SYSTEM LIVE READY");
        }
    });
    return;
}
@end
int main(int argc,char **argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(Delegate.class)); } }
