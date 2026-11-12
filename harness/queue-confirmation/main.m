#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <dlfcn.h>
#import "Core/SGAppearance.h"
#import "Redesigned/Queue/SGRQueueConfirmation.h"
// Inject only the accessibility preference boundary; no simulator/user setting changes.
static BOOL fixtureReduceTransparency;
BOOL UIAccessibilityIsReduceTransparencyEnabled(void) { return fixtureReduceTransparency; }
static BOOL fixtureRedesigned=YES;
BOOL SGRedesignedUI(void){return fixtureRedesigned;}
UIColor *SGRAccentColor(void){return nil;}
BOOL SGIsBaseSurface(CGColorRef color){return NO;}
void SGRequireClasses(NSArray *classes){}
// Main-app snackbar shells only. Production renderer, appearance owners, native
// UIKit Liquid Glass, and the actual Shared localization C boundary are compiled.
@interface SPTSnackbarWithActionView:UIView
@property(nonatomic,copy)NSString *text;
@property(nonatomic,strong)UIButton *actionButton;
@property(nonatomic,strong)UILabel *textLabel;
@end
@implementation SPTSnackbarWithActionView
- (instancetype)initWithFrame:(CGRect)f {if(!(self=[super initWithFrame:f]))return nil;_textLabel=[UILabel new];_actionButton=[UIButton buttonWithType:UIButtonTypeSystem];[self addSubview:_textLabel];[self addSubview:_actionButton];return self;}
- (void)layoutSubviews{[super layoutSubviews];_textLabel.frame=CGRectMake(14,0,self.bounds.size.width-90,self.bounds.size.height);_textLabel.text=_text;_actionButton.frame=CGRectMake(self.bounds.size.width-70,0,60,self.bounds.size.height);}
@end
@interface SPTSnackbarTextButtonContentViewModel:NSObject
@property(nonatomic,copy)void (^nativeBind)(UIView *);
- (void)bindView:(UIView *)v;
@end
@implementation SPTSnackbarTextButtonContentViewModel
- (void)bindView:(UIView *)v {if(self.nativeBind)self.nativeBind(v);}
@end
@interface SPTSnackbarView:UIView
@property(nonatomic,strong)UIView *containerView;
@property(nonatomic,strong)SPTSnackbarWithActionView *contentView;
@end
@implementation SPTSnackbarView
- (instancetype)initWithFrame:(CGRect)f {if(!(self=[super initWithFrame:f]))return nil;_containerView=[UIView new];_contentView=[SPTSnackbarWithActionView new];[self addSubview:_containerView];[_containerView addSubview:_contentView];_containerView.backgroundColor=UIColor.systemGray5Color;return self;}
- (void)layoutSubviews{[super layoutSubviews];_containerView.frame=self.bounds;_contentView.frame=_containerView.bounds;[_contentView layoutIfNeeded];}
@end
static NSMutableArray *fails;static NSMutableDictionary *checks;static NSUInteger opened=0;
static void check(NSString *n,BOOL v){checks[n]=@(v);if(!v)[fails addObject:n];}
static UIView *pill(SPTSnackbarView *v){for(UIView *c in v.subviews)if([c.accessibilityIdentifier isEqual:@"SGRQueueConfirmation"])return c;return nil;}
static UIButton *openControl(UIView *v){return [v valueForKey:@"openButton"];}
static UILabel *label(UIView *v){return [v valueForKey:@"label"];}
static void refresh(SPTSnackbarView *v){[v setNeedsLayout];[v layoutIfNeeded];}
static NSString *docs(void){return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;}
static void render(UIView *v,NSString *name){UIGraphicsImageRendererFormat*f=[UIGraphicsImageRendererFormat defaultFormat];f.scale=2;UIImage *im=[[[UIGraphicsImageRenderer alloc]initWithSize:v.bounds.size format:f]imageWithActions:^(UIGraphicsImageRendererContext*c){[v drawViewHierarchyInRect:v.bounds afterScreenUpdates:YES];}];[UIImagePNGRepresentation(im)writeToFile:[docs()stringByAppendingPathComponent:name] atomically:YES];}
@interface Delegate:UIResponder<UIApplicationDelegate,UIWindowSceneDelegate>@property(nonatomic,strong)UIWindow *window;@end
@implementation Delegate
- (void)opened:(id)sender{opened++;}
- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options { UISceneConfiguration *config=[[UISceneConfiguration alloc]initWithName:@"Fixture" sessionRole:session.role];config.delegateClass=Delegate.class;return config; }
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
 fails=[NSMutableArray new];checks=[NSMutableDictionary new];
 self.window=[[UIWindow alloc]initWithWindowScene:(UIWindowScene *)scene];UIViewController *vc=[UIViewController new];self.window.rootViewController=vc;[self.window makeKeyAndVisible];
 SGConfigureRedesignAppearance(UIUserInterfaceStyleLight);vc.view.backgroundColor=UIColor.whiteColor;
 SPTSnackbarView *s=[[SPTSnackbarView alloc]initWithFrame:CGRectMake(16,200,self.window.bounds.size.width-32,52)];s.contentView.text=@"Added to Queue";[s.contentView.actionButton setTitle:@"Open" forState:UIControlStateNormal];[s.contentView.actionButton addTarget:self action:@selector(opened:) forControlEvents:UIControlEventTouchUpInside];[vc.view addSubview:s];
 UILabel *heading=[[UILabel alloc]initWithFrame:CGRectMake(24,80,290,30)];heading.text=@"Queue confirmation fixture";heading.font=[UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];[vc.view addSubview:heading];
 UILabel *info=[[UILabel alloc]initWithFrame:CGRectMake(24,120,290,60)];info.text=@"Production pill on a reconstructed native snackbar. Open retains its original action.";info.numberOfLines=3;info.font=[UIFont systemFontOfSize:14];[vc.view addSubview:info];
 UIView *player=[[UIView alloc]initWithFrame:CGRectMake(16,268,self.window.bounds.size.width-32,54)];player.backgroundColor=[UIColor colorWithWhite:.94 alpha:1];player.layer.cornerRadius=27;[vc.view addSubview:player];UILabel *song=[[UILabel alloc]initWithFrame:CGRectMake(18,0,250,54)];song.text=@"Current song  ·  Still playing";song.font=[UIFont systemFontOfSize:15 weight:UIFontWeightMedium];[player addSubview:song];
 refresh(s);UIView *p=pill(s);
 check(@"recognizedQueueSuccess",p!=nil);check(@"nativeLifetimeIntact",s.contentView.superview==s.containerView);check(@"originalContentConcealed",s.containerView.alpha==0&&s.containerView.accessibilityElementsHidden);check(@"pillNarrowerThanHost",p.bounds.size.width<s.bounds.size.width);check(@"centered",fabs(CGRectGetMidX(p.frame)-CGRectGetMidX(s.bounds))<.01);check(@"messageTruthful",[label(p).text isEqual:@"Added to Queue"]);check(@"openAccessible",[openControl(p).accessibilityLabel isEqual:@"Open"]);check(@"touchTarget",openControl(p).bounds.size.width>=44&&openControl(p).bounds.size.height>=44);
 [openControl(p)sendActionsForControlEvents:UIControlEventTouchUpInside];[openControl(p)sendActionsForControlEvents:UIControlEventTouchUpInside];check(@"openOriginalActionOnce",opened==1);check(@"openDisabledAfterActivation",!openControl(p).enabled);
 [s removeFromSuperview];check(@"detachRestoresNative",pill(s)==nil&&s.containerView.alpha==1);[vc.view addSubview:s];refresh(s);check(@"reattachSameTextEnablesOpen",openControl(pill(s)).enabled);[openControl(pill(s))sendActionsForControlEvents:UIControlEventTouchUpInside];[[SPTSnackbarTextButtonContentViewModel new]bindView:s.contentView];refresh(s);check(@"rebindSameTextEnablesOpen",openControl(pill(s)).enabled);
 SPTSnackbarTextButtonContentViewModel *nativeRebind=[SPTSnackbarTextButtonContentViewModel new];nativeRebind.nativeBind=^(UIView *v){v.superview.alpha=.42;v.superview.accessibilityElementsHidden=YES;};[nativeRebind bindView:s.contentView];check(@"rebindPreservesFreshNativeState",pill(s)==nil&&fabs(s.containerView.alpha-.42)<.01&&s.containerView.accessibilityElementsHidden);refresh(s);SGRReleaseQueueConfirmation(s);check(@"rebindRestoresFreshNativeState",fabs(s.containerView.alpha-.42)<.01&&s.containerView.accessibilityElementsHidden);s.containerView.alpha=1;s.containerView.accessibilityElementsHidden=NO;refresh(s);
 s.contentView.text=@"Couldn’t add to queue";refresh(s);check(@"errorRestoresNative",pill(s)==nil&&s.containerView.alpha==1&&!s.containerView.accessibilityElementsHidden);s.contentView.text=@"Added to playlist";refresh(s);check(@"unrelatedNativeUnchanged",pill(s)==nil);
 s.contentView.text=@"Added to Queue";refresh(s);p=pill(s);check(@"reuseRebindsAction",openControl(p).enabled);check(@"onePillOnRepeatedLayouts",s.subviews.count==2);for(int i=0;i<100;i++)refresh(s);check(@"repeatedLayoutStable",s.subviews.count==2&&pill(s)==p);
 s.frame=CGRectMake(16,200,215,52);refresh(s);check(@"narrowWidthFallsBack",pill(s)==nil&&s.containerView.alpha==1);s.frame=CGRectMake(16,200,self.window.bounds.size.width-32,52);refresh(s);
 s.semanticContentAttribute=UISemanticContentAttributeForceRightToLeft;refresh(s);p=pill(s);check(@"rtlOpenOnLeadingSide",CGRectGetMinX(openControl(p).frame)<CGRectGetMinX(label(p).frame));s.semanticContentAttribute=UISemanticContentAttributeForceLeftToRight;refresh(s);
 s.traitOverrides.preferredContentSizeCategory=UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;refresh(s);check(@"largeDynamicTypeFallsBack",pill(s)==nil&&s.containerView.alpha==1);s.traitOverrides.preferredContentSizeCategory=UIContentSizeCategoryLarge;refresh(s);
 [s.contentView.actionButton setTitle:@"Open the complete playback queue" forState:UIControlStateNormal];s.frame=CGRectMake(16,200,270,52);refresh(s);check(@"longActionFallsBackWithoutTruncation",pill(s)==nil&&s.containerView.alpha==1);[s.contentView.actionButton setTitle:@"Open" forState:UIControlStateNormal];s.frame=CGRectMake(16,200,self.window.bounds.size.width-32,52);refresh(s);
 fixtureReduceTransparency=YES;refresh(s);UIView *solid=pill(s).subviews.firstObject;check(@"reduceTransparencySolid",solid!=nil&&![solid isKindOfClass:UIVisualEffectView.class]);fixtureReduceTransparency=NO;refresh(s);check(@"restoreTransparencyGlass",[pill(s).subviews.firstObject isKindOfClass:UIVisualEffectView.class]);
 s.contentView.actionButton.enabled=NO;refresh(s);check(@"nativeDisabledRespected",!openControl(pill(s)).enabled);s.contentView.actionButton.enabled=YES;refresh(s);
 s.alpha=.35;refresh(s);check(@"nativeRootFadePreserved",fabs(s.alpha-.35)<.01&&pill(s).alpha==1);s.alpha=1;
 fixtureRedesigned=NO;refresh(s);check(@"nativeModeRestored",pill(s)==nil&&s.containerView.alpha==1);fixtureRedesigned=YES;refresh(s);
 NSString *(*nativeLocalize)(NSString*,NSString*)=dlsym(RTLD_DEFAULT,"__sptloc_localized");NSString *nativeNext=nativeLocalize(@"Queue:sSongAddedToPlayNext",nil);s.contentView.text=nativeNext;refresh(s);check(@"nativeNextConfirmationOnly",[label(pill(s)).text isEqual:nativeNext]);s.contentView.text=@"Added to Queue";refresh(s);
 NSString *(*localize)(NSString*,NSString*)=dlsym(RTLD_DEFAULT,"__sptloc_localized");NSString *value=localize?localize(@"Queue:sSongAddedToUpNext",nil):nil;check(@"actualNativeLocalizationBoundary",[value isKindOfClass:NSString.class] && ![value containsString:@"sSong"]);
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.8*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
 render(vc.view,@"light.png");SGConfigureRedesignAppearance(UIUserInterfaceStyleDark);SGRefreshAppearanceOwners();vc.view.backgroundColor=UIColor.blackColor;heading.textColor=UIColor.whiteColor;info.textColor=UIColor.lightGrayColor;player.backgroundColor=[UIColor colorWithWhite:.12 alpha:1];song.textColor=UIColor.whiteColor;refresh(s);UIView *darkPill= pill(s);CGFloat white=0;[label(darkPill).textColor getWhite:&white alpha:nil];check(@"retainedDarkInk",white>.95);
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.8*NSEC_PER_SEC)),dispatch_get_main_queue(),^{render(vc.view,@"dark.png");NSDictionary*r=@{@"checks":checks,@"failures":fails,@"passed":@(fails.count==0),@"nativeLocalizationResult":value?:@"unavailable",@"nativePlayNextConfirmation":nativeNext?:@"unavailable",@"reduceTransparencyCoverage":@"Injected accessibility boolean; production glass mode switch and rendering",@"coverage":@"Production queue renderer/hooks + native UIKit glass + actual SpotifyShared localization C function. Main-app snackbar and queue operation are not running."};[[NSJSONSerialization dataWithJSONObject:r options:NSJSONWritingPrettyPrinted error:nil]writeToFile:[docs()stringByAppendingPathComponent:@"result.json"] atomically:YES];NSLog(@"QUEUE FIXTURE %@",r);});
 });
}
@end
int main(int argc,char**argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(Delegate.class));}}
