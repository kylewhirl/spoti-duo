// Compile the production implementation into this translation unit so the fixture can
// exercise applyHeader directly without pretending to reconstruct Spotify's controllers.
#import <UIKit/UIKit.h>
@interface _TtC28CreativeWorkPlatform_PageKit19HeaderContainerView : UIView @end
@implementation _TtC28CreativeWorkPlatform_PageKit19HeaderContainerView @end
@interface ArtworkFixtureHeader : UIView
@property(nonatomic) CGFloat nativeContentHeight;
@end
@implementation ArtworkFixtureHeader
- (CGSize)intrinsicContentSize { return CGSizeMake(UIViewNoIntrinsicMetric,self.nativeContentHeight); }
@end
#import "AlbumHeader.m"
UIView *SGRAlbumPageOf(UIView *v) { for(;v;v=v.superview) if([v.accessibilityIdentifier isEqualToString:@"artwork-fixture-page"]) return v; return nil; }
UIColor *SGRAlbumFieldColor(UIView *v) { return UIColor.blackColor; }
void SGRAlbumSetArtwork(UIView *v,UIImage *i) {}
void SGRAlbumSetSpotifyColor(UIView *v,UIColor *c) {}
static NSUInteger checks,failures;
static BOOL near(CGFloat a,CGFloat b) { return fabs(a-b)<.51; }
static BOOL sameRect(CGRect a,CGRect b) { return near(a.origin.x,b.origin.x)&&near(a.origin.y,b.origin.y)&&near(a.size.width,b.size.width)&&near(a.size.height,b.size.height); }
static void verify(BOOL ok,NSString *name) { checks++; if(!ok) { failures++; NSLog(@"FAIL %@",name); } }
static UIImage *sampleImage(UIColor *color) {
 UIGraphicsImageRenderer *r=[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(400,400)];
 return [r imageWithActions:^(UIGraphicsImageRendererContext *c) { [color setFill]; UIRectFill(CGRectMake(0,0,400,400)); }];
}
static UILabel *fixtureLabel(UIView *parent,NSString *identifier,NSString *text) {
 UIView *row=[[UIView alloc] initWithFrame:CGRectMake(0,0,300,25)]; row.accessibilityIdentifier=identifier; [parent addSubview:row];
 UILabel *label=[[UILabel alloc] initWithFrame:row.bounds]; label.text=text; [row addSubview:label]; return label;
}
@interface ArtworkFixture : NSObject
@property(nonatomic,strong) UIView *stage,*page,*root,*container,*adapter,*cover;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) ArtworkFixtureHeader *header;
@property(nonatomic,strong) UIImageView *source;
@property(nonatomic,strong) UILabel *title,*creator,*metadata;
@property(nonatomic,strong) NSLayoutConstraint *containerWidth,*containerHeight,*containerTop,*adapterTop;
@property(nonatomic,strong) NSArray<NSLayoutConstraint *> *ownedConstraints;
- (instancetype)initIn:(UIView *)stage knownContainer:(BOOL)known width:(CGFloat)width height:(CGFloat)height;
- (void)settle;
- (void)resize:(CGFloat)width height:(CGFloat)height;
- (void)replaceContainer:(BOOL)known;
- (void)replacePage;
- (CGRect)heroWorld;
- (CGRect)titleWorld;
- (CGRect)crop;
- (SGRAlbumHero *)hero;
- (SGRHeaderInfo *)info;
@end
@implementation ArtworkFixture
- (instancetype)initIn:(UIView *)stage knownContainer:(BOOL)known width:(CGFloat)width height:(CGFloat)height {
 if(!(self=[super init])) return nil; self.stage=stage;
 CGRect windowFrame=stage.window.frame; windowFrame.size.width=width+34; stage.window.frame=windowFrame; [stage.window layoutIfNeeded];
 self.page=[[UIView alloc] initWithFrame:CGRectMake(0,0,width+34,1800)]; self.page.accessibilityIdentifier=@"artwork-fixture-page"; [stage addSubview:self.page];
 self.scroll=[[UIScrollView alloc] initWithFrame:CGRectMake(0,0,1100,1400)]; self.scroll.contentSize=CGSizeMake(1100,3000); self.scroll.contentInsetAdjustmentBehavior=UIScrollViewContentInsetAdjustmentNever; [self.page addSubview:self.scroll];
 // Root is an independent reference plane, as in the native root-top inequality.
 self.root=[[UIView alloc] initWithFrame:CGRectMake(0,100,1100,1400)]; [self.page addSubview:self.root];
 self.container=[[(known ? _TtC28CreativeWorkPlatform_PageKit19HeaderContainerView.class : UIView.class) alloc] initWithFrame:CGRectZero];
 self.adapter=[UIView new]; self.header=[ArtworkFixtureHeader new]; self.header.nativeContentHeight=height;
 self.header.accessibilityIdentifier=@"CreativeWorkPlatform.Components.UI.CreativeWorkHeader";
 [self.scroll addSubview:self.container]; [self.container addSubview:self.adapter]; [self.adapter addSubview:self.header];
 for(UIView *v in @[self.container,self.adapter,self.header]) v.translatesAutoresizingMaskIntoConstraints=NO;
 self.containerWidth=[self.container.widthAnchor constraintEqualToConstant:width];
 self.containerHeight=[self.container.heightAnchor constraintEqualToConstant:height];
 self.containerTop=[self.container.topAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.topAnchor constant:100];
 self.adapterTop=[self.adapter.topAnchor constraintLessThanOrEqualToAnchor:self.root.topAnchor];
 self.ownedConstraints=@[
  [self.container.leadingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.leadingAnchor constant:17],self.containerTop,self.containerWidth,self.containerHeight,
  // Exact relationships decoded from Spotify 9.1.94 HeaderContainerView.
  [self.adapter.heightAnchor constraintGreaterThanOrEqualToAnchor:self.container.heightAnchor],
  [self.adapter.leadingAnchor constraintEqualToAnchor:self.container.leadingAnchor],
  [self.adapter.trailingAnchor constraintEqualToAnchor:self.container.trailingAnchor],
  [self.adapter.bottomAnchor constraintEqualToAnchor:self.container.bottomAnchor],self.adapterTop,
  [self.header.topAnchor constraintEqualToAnchor:self.adapter.topAnchor],
  [self.header.bottomAnchor constraintEqualToAnchor:self.adapter.bottomAnchor],
  [self.header.leadingAnchor constraintEqualToAnchor:self.adapter.leadingAnchor],
  [self.header.trailingAnchor constraintEqualToAnchor:self.adapter.trailingAnchor]];
 [NSLayoutConstraint activateConstraints:self.ownedConstraints];
 self.cover=[[UIView alloc] initWithFrame:CGRectMake(0,0,300,300)]; self.cover.accessibilityIdentifier=@"CreativeWorkPlatform.Components.UI.ArtWorkElement.WithCoverArt"; [self.header addSubview:self.cover];
 self.source=[[UIImageView alloc] initWithFrame:self.cover.bounds]; self.source.image=sampleImage(UIColor.redColor); [self.cover addSubview:self.source];
 self.title=fixtureLabel(self.header,@"CreativeWorkPlatform.Components.UI.TitleRow",@"A Long Album Title With Words That Wrap Differently Across Narrow and Wide Windows");
 self.creator=fixtureLabel(self.header,@"CreativeWorkPlatform.Components.UI.ParentRow",@"Example Artist");
 self.metadata=fixtureLabel(self.header,@"Components.UI.MetadataRow",@"Album • 2026");
 [self settle]; return self;
}
- (void)settle {
 [self.page setNeedsLayout]; [self.page layoutIfNeeded];
 applyPage(self.page); [self.header layoutIfNeeded]; [self.info layoutIfNeeded]; [self.hero layoutIfNeeded];
}
- (void)resize:(CGFloat)width height:(CGFloat)height {
 CGRect windowFrame=self.stage.window.frame; windowFrame.size.width=width+34; self.stage.window.frame=windowFrame; [self.stage.window layoutIfNeeded];
 CGRect pageFrame=self.page.frame; pageFrame.size.width=width+34; self.page.frame=pageFrame;
 self.containerWidth.constant=width; self.containerHeight.constant=height;
 self.header.nativeContentHeight=height; [self.header invalidateIntrinsicContentSize]; [self settle];
}
- (void)replaceContainer:(BOOL)known {
 UIView *old=self.container;
 UIView *next=[[(known ? _TtC28CreativeWorkPlatform_PageKit19HeaderContainerView.class : UIView.class) alloc] initWithFrame:CGRectZero]; next.translatesAutoresizingMaskIntoConstraints=NO;
 [NSLayoutConstraint deactivateConstraints:self.ownedConstraints];
 [self.adapter removeFromSuperview]; [old removeFromSuperview]; [self.scroll addSubview:next]; [next addSubview:self.adapter];
 NSMutableArray *replacement=[NSMutableArray array];
 for(NSLayoutConstraint *c in self.ownedConstraints) {
  NSLayoutConstraint *r=[NSLayoutConstraint constraintWithItem:c.firstItem==old?next:c.firstItem attribute:c.firstAttribute relatedBy:c.relation toItem:c.secondItem==old?next:c.secondItem attribute:c.secondAttribute multiplier:c.multiplier constant:c.constant]; r.priority=c.priority;
  if(c==self.containerWidth) self.containerWidth=r;
  if(c==self.containerHeight) self.containerHeight=r;
  if(c==self.containerTop) self.containerTop=r;
  if(c==self.adapterTop) self.adapterTop=r;
  [replacement addObject:r];
 }
 self.container=next; self.ownedConstraints=replacement; [NSLayoutConstraint activateConstraints:replacement]; [self settle];
}
- (void)replacePage {
 UIView *old=self.page,*next=[[UIView alloc] initWithFrame:old.frame]; next.accessibilityIdentifier=old.accessibilityIdentifier;
 [NSLayoutConstraint deactivateConstraints:self.ownedConstraints]; [self.stage addSubview:next];
 [self.scroll removeFromSuperview]; [next addSubview:self.scroll]; [self.root removeFromSuperview]; [next addSubview:self.root];
 self.page=next; [old removeFromSuperview]; [NSLayoutConstraint activateConstraints:self.ownedConstraints]; [self settle];
}
- (SGRAlbumHero *)hero { return objc_getAssociatedObject(self.header,&kHeroKey); }
- (SGRHeaderInfo *)info { return objc_getAssociatedObject(self.header,&kInfoKey); }
- (CGRect)heroWorld { return [self.hero convertRect:self.hero.bounds toView:self.stage]; }
- (CGRect)titleWorld { UILabel *t=[self.info valueForKey:@"_title"]; return [t convertRect:t.bounds toView:self.stage]; }
- (CGRect)crop {
 CGSize image=self.hero.picture.image.size,view=self.hero.picture.bounds.size;
 CGFloat scale=MAX(view.width/image.width,view.height/image.height);
 if(scale<=0 || !isfinite(scale)) return CGRectZero;
 CGSize visible=CGSizeMake(view.width/scale,view.height/scale);
 return CGRectMake((image.width-visible.width)/2,(image.height-visible.height)/2,visible.width,visible.height);
}
@end
static CGRect expectedHero(ArtworkFixture *f) {
 CGRect plane=[f.container convertRect:f.container.bounds toView:f.stage];
 CGFloat h=round(plane.size.height-SGRHeaderInfoBottom-[f.info contentHeightForWidth:f.info.bounds.size.width]+SGRHeaderInfoTitleRise);
 return CGRectMake(plane.origin.x,plane.origin.y,plane.size.width,h);
}
static void validGeometry(ArtworkFixture *f,NSString *phase) {
 verify(sameRect(f.heroWorld,expectedHero(f)),[phase stringByAppendingString:@" logical world hero"]);
 verify(sameRect(f.info.frame,SGRHeaderInfoFrame(f.header,f.header)),[phase stringByAppendingString:@" info retains tested centered frame"]);
 verify(CGRectEqualToRect(f.hero.picture.frame,f.hero.bounds),[phase stringByAppendingString:@" picture fills hero"]);
 verify(f.hero.picture.contentMode==UIViewContentModeScaleAspectFill,[phase stringByAppendingString:@" aspect fill retained"]);
}
static void runChecks(UIView *stage) {
 ArtworkFixture *f=[[ArtworkFixture alloc] initIn:stage knownContainer:YES width:466 height:568];
 CGRect initial=f.heroWorld,title=f.titleWorld,crop=f.crop,container=[f.container convertRect:f.container.bounds toView:stage];
 validGeometry(f,@"rest");
 verify(title.size.width>200,@"fixture title has a real text column");
 verify(!f.adapter.hasAmbiguousLayout&&!f.header.hasAmbiguousLayout,@"intrinsic native sizing gives fixture a determinate solution");
 NSLog(@"METRIC rest hero=%@ title=%@ crop=%@",NSStringFromCGRect(initial),NSStringFromCGRect(title),NSStringFromCGRect(crop));
 for(NSUInteger round=0;round<3;round++) for(NSNumber *stretch in @[@40,@160,@280,@80,@0]) {
  CGFloat d=stretch.doubleValue; f.root.frame=CGRectMake(0,100-d,1100,1400); [f settle];
  NSString *phase=[NSString stringWithFormat:@"stretch %@ cycle %lu",stretch,(unsigned long)round];
  verify(near(f.header.bounds.size.height,568+d),[phase stringByAppendingString:@" solver stretched header"]);
  verify(sameRect([f.container convertRect:f.container.bounds toView:stage],container),[phase stringByAppendingString:@" container unchanged"]);
  verify(sameRect(f.titleWorld,title),[phase stringByAppendingString:@" title world unchanged"]);
  verify(sameRect(f.heroWorld,initial),[phase stringByAppendingString:@" hero world unchanged"]);
  verify(sameRect(f.crop,crop),[phase stringByAppendingString:@" crop unchanged"]);
  if(round==0) NSLog(@"METRIC stretch=%@ header=%@ hero=%@ title=%@ crop=%@",stretch,NSStringFromCGRect(f.header.frame),NSStringFromCGRect(f.heroWorld),NSStringFromCGRect(f.titleWorld),NSStringFromCGRect(f.crop));
 }
 // Scroll changes only native scroll position; root moves with it here to keep stretch zero.
 for(CGFloat offset=0;offset<=800;offset+=20) {
  f.scroll.contentOffset=CGPointMake(0,offset); f.root.frame=CGRectMake(0,100-offset,1100,1400); [f settle];
  CGRect wanted=initial; wanted.origin.y-=offset;
  verify(sameRect(f.heroWorld,wanted),@"native scroll translation retained");
  verify(near(f.scroll.contentOffset.y,offset)&&CGSizeEqualToSize(f.scroll.contentSize,CGSizeMake(1100,3000))&&UIEdgeInsetsEqualToEdgeInsets(f.scroll.contentInset,UIEdgeInsetsZero),@"scroll inputs untouched");
 }
 f.scroll.contentOffset=CGPointZero; f.root.frame=CGRectMake(0,100,1100,1400); [f settle];
 for(NSArray *size in @[@[@669,@640],@[@951,@520],@[@320,@700],@[@466,@568],@[@402,@480],@[@466,@568]]) {
  [f resize:[size[0] doubleValue] height:[size[1] doubleValue]]; validGeometry(f,[NSString stringWithFormat:@"resize %@",size]);
 }
 // Text changes are genuine artwork remeasurement, not a permanent historical maximum.
 for(NSString *name in @[@"Short Album",@"A much longer replacement album title whose real layout needs several lines at this width",@"Short Again"]) {
  f.title.text=name; [f settle]; validGeometry(f,[NSString stringWithFormat:@"title %@",name]);
 }
 f.metadata.text=@"Deluxe Album • November 2026 • Remastered"; [f settle]; validGeometry(f,@"metadata changes");
 UIView *meta=f.metadata.superview; CGRect retained=f.titleWorld,retainedArt=f.heroWorld; [meta removeFromSuperview]; [f settle];
 verify(sameRect(f.titleWorld,retained)&&sameRect(f.heroWorld,retainedArt),@"unavailable metadata stays retained"); [f.header addSubview:meta]; [f settle];
 // Recycling a rendered metadata row with the same text is not new album artwork.
 [meta removeFromSuperview]; f.metadata=fixtureLabel(f.header,@"Components.UI.MetadataRow",@"Deluxe Album • November 2026 • Remastered"); [f settle];
 verify(sameRect(f.heroWorld,retainedArt),@"same-identity metadata source replacement is stable");
 [f replaceContainer:YES]; validGeometry(f,@"replacement native container");
 [f replacePage]; validGeometry(f,@"replacement owning page");
 // Nonzero bounds are real coordinate conversions, not a hard-coded origin.
 f.header.bounds=CGRectMake(7,11,f.header.bounds.size.width,f.header.bounds.size.height); [f settle]; validGeometry(f,@"nonzero header bounds");
 // Moving the container bounds without moving its constrained children violates the
 // decoded visual edge contract, so it must use fallback, not guess at that new layout.
 f.container.bounds=CGRectMake(9,13,f.container.bounds.size.width,f.container.bounds.size.height); [f settle];
 verify(near(f.hero.frame.origin.x,0)&&near(f.hero.frame.origin.y,0),@"misaligned container bounds use legacy fallback");
 f.container.bounds=(CGRect){CGPointZero,f.container.bounds.size}; [f settle]; validGeometry(f,@"native pins restored");
 // Repeated calls do not change native frames/constraints or the hero world plane.
 CGRect steady=f.heroWorld,headerFrame=f.header.frame; NSArray *native=[f.ownedConstraints copy];
 for(NSUInteger i=0;i<100;i++) [f settle];
 verify(sameRect(f.heroWorld,steady)&&sameRect(f.header.frame,headerFrame),@"100 unchanged layout passes stable");
 verify([native isEqualToArray:f.ownedConstraints],@"native constraint identities retained");
 for(NSLayoutConstraint *c in native) verify(c.active,@"native constraints remain active");
 // Late image on same source, then an unrelated source's delayed completion.
 f.source.image=nil; UIImage *late=sampleImage(UIColor.blueColor); f.source.image=late;
 verify(f.hero.picture.image==late,@"late artwork updates without layout");
 UIImageView *old=f.source,*replacement=[[UIImageView alloc] initWithFrame:f.cover.bounds];
 [old removeFromSuperview]; [f.cover addSubview:replacement]; f.source=replacement; [f settle];
 verify(f.hero.picture.image==nil,@"replacement empty artwork does not retain previous owner");
 UIImage *replacementImage=sampleImage(UIColor.greenColor); replacement.image=replacementImage;
 verify(f.hero.picture.image==replacementImage,@"replacement source late artwork updates"); old.image=sampleImage(UIColor.yellowColor);
 verify(f.hero.picture.image==replacementImage,@"old source callback cannot overwrite new owner");
 [replacement removeFromSuperview]; [f settle]; verify(f.hero.picture.image==replacementImage,@"temporarily missing source preserves current artwork");
 [f.cover addSubview:old]; f.source=old; [f settle]; verify(f.hero.picture.image==old.image,@"returning source becomes current owner");
 replacement.image=late; verify(f.hero.picture.image==old.image,@"second abandoned source callback ignored");
 [f.page removeFromSuperview];
 // Initial incomplete layout, valid growth, legitimate shrink below minimum, then recovery.
 ArtworkFixture *loading=[[ArtworkFixture alloc] initIn:stage knownContainer:YES width:402 height:160];
 verify(loading.hero.hidden || CGRectIsEmpty(loading.hero.frame),@"short initial container not drawn");
 [loading resize:402 height:440]; validGeometry(loading,@"loaded growth");
 [loading resize:402 height:160]; verify(loading.hero.hidden || CGRectIsEmpty(loading.hero.frame),@"short reflow cannot retain giant old hero");
 [loading resize:402 height:500]; validGeometry(loading,@"loaded recovery"); verify(!loading.hero.hidden,@"hero reappears after valid growth");
 [loading.page removeFromSuperview];
 // An unrecognized hierarchy must retain legacy same-width stability.
 ArtworkFixture *fallback=[[ArtworkFixture alloc] initIn:stage knownContainer:NO width:402 height:568];
 CGRect legacy=fallback.heroWorld; [fallback resize:402 height:480];
 verify(near(fallback.heroWorld.size.height,legacy.size.height),@"missing container fallback preserves legacy same-width maximum");
 [fallback resize:320 height:480]; validGeometry(fallback,@"fallback width invalidation");
 [fallback resize:320 height:400]; fallback.title.text=@"A Newly Confirmed Album"; [fallback settle]; validGeometry(fallback,@"fallback confirmed title invalidation");
 [fallback resize:320 height:360]; fallback.creator.text=@"New Artist"; [fallback settle]; validGeometry(fallback,@"fallback confirmed creator invalidation");
 [fallback resize:320 height:340]; [fallback replacePage]; validGeometry(fallback,@"fallback owning page invalidation");
 [fallback replaceContainer:YES]; validGeometry(fallback,@"fallback becomes verified container");
 [fallback resize:320 height:600]; [fallback resize:320 height:400]; validGeometry(fallback,@"verified container shrinks without maximum");
 [fallback replaceContainer:NO]; [fallback resize:320 height:360]; CGFloat fallbackHeight=fallback.heroWorld.size.height;
 verify(near(fallbackHeight,round(400-SGRHeaderInfoBottom-[fallback.info contentHeightForWidth:fallback.info.bounds.size.width]+SGRHeaderInfoTitleRise)),@"new missing-container scope begins at its current dimensions");
 [fallback.page removeFromSuperview];
 // Coordinate safety: support positive axis-aligned scale/translation, and fall back
 // rather than enclosing a rotated/sheared/mirrored plane in an unrelated rectangle.
 ArtworkFixture *scaled=[[ArtworkFixture alloc] initIn:stage knownContainer:YES width:402 height:568];
 scaled.page.transform=CGAffineTransformMake(1.25,0,0,.8,12,-9); [scaled settle];
 CGRect local=[scaled.header convertRect:scaled.container.bounds fromView:scaled.container];
 CGFloat scaledHeight=round(local.size.height-SGRHeaderInfoBottom-[scaled.info contentHeightForWidth:scaled.info.bounds.size.width]+SGRHeaderInfoTitleRise);
 verify(sameRect(scaled.hero.frame,CGRectMake(local.origin.x,local.origin.y,local.size.width,scaledHeight)),@"shared-ancestor scale and translation keep converted plane");
 scaled.page.transform=CGAffineTransformIdentity; scaled.adapter.transform=CGAffineTransformMake(1.25,0,0,.8,12,-9); [scaled settle];
 verify(near(scaled.hero.frame.origin.x,0)&&near(scaled.hero.frame.origin.y,0)&&near(scaled.hero.frame.size.width,scaled.header.bounds.size.width),@"adapter-local scale violating native pins uses fallback");
 [scaled.page removeFromSuperview];
 CGAffineTransform unsupported[]={CGAffineTransformMakeRotation(.15),CGAffineTransformMake(1,.1,.2,1,0,0),CGAffineTransformMakeScale(-1,1)};
 for(NSUInteger i=0;i<3;i++) {
  ArtworkFixture *transformed=[[ArtworkFixture alloc] initIn:stage knownContainer:YES width:402 height:568];
  transformed.adapter.transform=unsupported[i]; [transformed settle];
  verify(near(transformed.hero.frame.origin.x,0)&&near(transformed.hero.frame.origin.y,0)&&near(transformed.hero.frame.size.width,transformed.header.bounds.size.width),@"unsupported transform uses legacy local plane");
  [transformed.page removeFromSuperview];
 }
 ArtworkFixture *ownership=[[ArtworkFixture alloc] initIn:stage knownContainer:YES width:402 height:568];
 ownership.root.frame=CGRectMake(0,-60,1100,1400); [ownership settle];
 verify(near(ownership.hero.frame.origin.y,160),@"verified owning page uses container plane");
 UIView *foreign=[[UIView alloc] initWithFrame:ownership.page.frame]; [stage addSubview:foreign];
 applyHeader(ownership.header,foreign);
 verify(near(ownership.hero.frame.origin.y,0),@"wrong page cannot authorize distant container plane");
 [ownership settle]; validGeometry(ownership,@"return to verified owning page");
 [foreign removeFromSuperview]; [ownership.page removeFromSuperview];
 ArtworkFixture *distant=[[ArtworkFixture alloc] initIn:stage knownContainer:NO width:402 height:568];
 UIView *outer=[[_TtC28CreativeWorkPlatform_PageKit19HeaderContainerView alloc] initWithFrame:distant.page.frame]; [stage addSubview:outer];
 [distant.page removeFromSuperview]; [outer addSubview:distant.page];
 distant.root.frame=CGRectMake(0,-60,1100,1400); [distant settle];
 verify(near(distant.hero.frame.origin.y,0),@"native container outside current page is ignored");
 [outer removeFromSuperview];
 NSLog(@"ALBUM ARTWORK CHECKS: %lu checks, %lu failures -- %@",(unsigned long)checks,(unsigned long)failures,failures?@"FAIL":@"PASS");
}
@interface ArtworkApp : UIResponder <UIApplicationDelegate,UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation ArtworkApp
- (UISceneConfiguration *)application:(UIApplication *)a configurationForConnectingSceneSession:(UISceneSession *)s options:(UISceneConnectionOptions *)o { UISceneConfiguration *c=[[UISceneConfiguration alloc] initWithName:@"Artwork" sessionRole:s.role]; c.delegateClass=self.class; return c; }
- (void)scene:(UIScene *)s willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)o {
 self.window=[[UIWindow alloc] initWithWindowScene:(UIWindowScene *)s]; self.window.rootViewController=[UIViewController new]; [self.window makeKeyAndVisible];
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{ runChecks(self.window.rootViewController.view); });
}
@end
int main(int argc,char **argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(ArtworkApp.class)); } }
