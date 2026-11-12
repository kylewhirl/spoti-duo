#import "Redesigned/Kit/SGRNavigationAppearance.h"
#import <AVKit/AVKit.h>

// Only Spotify's ownership/lifecycle is mocked. The UINavigationBar, automatic
// Back item, native glass platter, rendered chevron, pop action and transition
// layout below are the actual simulator UIKit implementation, not drawn replicas.
@interface SPNavigationBar : UINavigationBar @end
@implementation SPNavigationBar @end
@interface SPNavigationController : UINavigationController <UINavigationControllerDelegate> @end
@implementation SPNavigationController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    self.navigationBar.tintColor=UIColor.whiteColor;
    self.delegate=self;
}
- (void)navigationController:(UINavigationController *)navigation willShowViewController:(UIViewController *)controller animated:(BOOL)animated {}
- (void)navigationController:(UINavigationController *)navigation didShowViewController:(UIViewController *)controller animated:(BOOL)animated {}
@end

static void navigationSettle(UIWindow *window) {
    [window setNeedsLayout];[window layoutIfNeeded];
    [CATransaction flush];
    NSDate *end=[NSDate dateWithTimeIntervalSinceNow:.20];
    while (end.timeIntervalSinceNow>0) [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:end];
    [window layoutIfNeeded];[CATransaction flush];
}
static UIView *navigationBackPlatter(UIView *view) {
    if ([NSStringFromClass(view.class) isEqualToString:@"_UIButtonBarButton"] && !view.hidden && view.alpha>.01 && CGRectGetWidth(view.bounds)>20) return view;
    for (UIView *child in view.subviews) { UIView *found=navigationBackPlatter(child);if (found) return found; }
    return nil;
}
static UIImage *navigationCapture(UIWindow *window, NSString *name) {
    navigationSettle(window);
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat defaultFormat];
    format.scale=1;format.opaque=YES;format.preferredRange=UIGraphicsImageRendererFormatRangeStandard;
    UIImage *image=[[[UIGraphicsImageRenderer alloc] initWithSize:window.bounds.size format:format] imageWithActions:^(UIGraphicsImageRendererContext *context) {
        expect([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES],@"actual UIKit navigation window snapshot succeeds");
    }];
    NSString *directory=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
    expect([UIImagePNGRepresentation(image) writeToFile:[directory stringByAppendingPathComponent:name] atomically:YES],@"write native navigation rendering evidence");
    return image;
}
static NSArray<NSNumber *> *navigationPixels(UIImage *image, CGRect rectangle) {
    CGImageRef crop=CGImageCreateWithImageInRect(image.CGImage,CGRectIntegral(rectangle));
    if (!crop) return @[];
    size_t width=CGImageGetWidth(crop),height=CGImageGetHeight(crop);
    uint8_t *bytes=calloc(width*height,4);
    CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();
    CGContextRef context=CGBitmapContextCreate(bytes,width,height,8,width*4,space,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGContextDrawImage(context,CGRectMake(0,0,width,height),crop);
    NSMutableArray *values=[NSMutableArray new];
    for (size_t i=0;i<width*height;i++) [values addObject:@((.2126*bytes[4*i]+.7152*bytes[4*i+1]+.0722*bytes[4*i+2])/255.)];
    CGContextRelease(context);CGColorSpaceRelease(space);CGImageRelease(crop);free(bytes);return values;
}
static CGFloat navigationMean(NSArray<NSNumber *> *values) {
    CGFloat sum=0;for (NSNumber *value in values) sum+=value.doubleValue;return values.count?sum/values.count:0;
}
static CGFloat navigationDifference(NSArray<NSNumber *> *a, NSArray<NSNumber *> *b) {
    if (!a.count || a.count!=b.count) return 1;
    CGFloat total=0;for(NSUInteger i=0;i<a.count;i++) total+=fabs(a[i].doubleValue-b[i].doubleValue);return total/a.count;
}
static void nativeNavigationAppearanceChecks(UIWindow *window) {
    NSInteger saved=SGInt(SGRKeyAppearance,SGRAppearanceSystem);
    UIViewController *originalRoot=window.rootViewController;
    expect(SGRAppearanceApplyMode(SGRAppearanceLight,NO),@"native navigation baseline uses selected Light while Spotify forces its own bar Dark");
    UIViewController *root=[UIViewController new];root.title=@"Library";root.navigationItem.backButtonDisplayMode=UINavigationItemBackButtonDisplayModeMinimal;
    UIViewController *page=[UIViewController new];page.title=@"Playlist";
    UIColor *backdrop=[UIColor colorWithRed:.82 green:.90 blue:1 alpha:1];
    page.view.backgroundColor=backdrop;
    SPNavigationController *navigation=[[SPNavigationController alloc] initWithNavigationBarClass:SPNavigationBar.class toolbarClass:nil];
    [navigation setViewControllers:@[root,page] animated:NO];
    window.rootViewController=navigation;
    [window makeKeyAndVisible];navigationSettle(window);
    UINavigationBar *bar=navigation.navigationBar;
    bar.barStyle=UIBarStyleDefault;
    // Transparent page-backed native glass matches the redesigned entity screens.
    UINavigationBarAppearance *appearance=[UINavigationBarAppearance new];[appearance configureWithTransparentBackground];
    bar.standardAppearance=appearance;bar.scrollEdgeAppearance=appearance;
    navigationSettle(window);
    UIView *back=navigationBackPlatter(bar);
    expect(back!=nil,@"native UIKit automatic Back platter exists before any appearance ownership");
    CGRect backFrame=back?[back convertRect:back.bounds toView:window]:CGRectZero;
    expect(!CGRectIsEmpty(backFrame),@"native UIKit Back has a visible rendering region");
    expect(bar.overrideUserInterfaceStyle==UIUserInterfaceStyleDark && !SGRNativeSurfaceHasRootWithin(page.view),@"baseline reproduces exact forced-dark native Back outside the Light page registry");
    UIImage *baseline=navigationCapture(window,@"navigation-native-forced-dark.png");
    NSArray *baselinePixels=navigationPixels(baseline,backFrame);
    CGRect nativeBarFrame=bar.frame;
    NSArray *nativeItems=bar.items;
    id nativeDelegate=bar.delegate;
    id nativeGesture=navigation.interactivePopGestureRecognizer;
    UINavigationBarAppearance *nativeAppearance=bar.standardAppearance;
    UIUserInterfaceStyle nativePageStyle=page.overrideUserInterfaceStyle;
    // Only now register the page, so the same retained native Back proves the fix.
    SGRApplyNativeLightSurface(page.view,NO);
    [bar setNeedsLayout];navigationSettle(window);
    expect(bar.overrideUserInterfaceStyle==UIUserInterfaceStyleLight,@"native owner hook releases forced Dark only for registered Light top page");
    expect(contrast(bar.tintColor,backdrop)>=7,@"native Back inherits readable Light primary tint");
    expect(page.overrideUserInterfaceStyle==nativePageStyle,@"bar-only adapter does not change its native page controller traits");
    UIImage *light=navigationCapture(window,@"navigation-native-light.png");
    NSArray *lightPixels=navigationPixels(light,backFrame);
    CGFloat baselineMean=navigationMean(baselinePixels),lightMean=navigationMean(lightPixels);
    CGFloat changed=navigationDifference(baselinePixels,lightPixels);
    expect(baselinePixels.count>100 && lightMean>baselineMean+.08 && changed>.10,@"actual native Back pixels change from dark glass/white ink to light glass/dark ink, not merely property readbacks");
    expect(back==navigationBackPlatter(bar) && CGRectEqualToRect(nativeBarFrame,bar.frame) && CGRectEqualToRect(backFrame,[back convertRect:back.bounds toView:window]),@"same retained UIKit Back and exact native frames survive appearance change");
    expect([bar.items isEqual:nativeItems] && bar.delegate==nativeDelegate && navigation.interactivePopGestureRecognizer==nativeGesture && bar.standardAppearance==nativeAppearance,@"native items, delegate, interactive pop recognizer and appearance object remain unchanged");
    expect(SGRAppearanceApplyMode(SGRAppearanceDark,NO),@"native navigation switches to Dark live");
    UIImage *dark=navigationCapture(window,@"navigation-native-dark.png");
    CGFloat darkDifference=navigationDifference(baselinePixels,navigationPixels(dark,backFrame));
    expect(bar.overrideUserInterfaceStyle==UIUserInterfaceStyleDark && [bar.tintColor isEqual:UIColor.whiteColor] && darkDifference<.07,@"Dark returns native forced-dark Back rendering and exact source tint");
    for (NSUInteger i=0;i<4;i++) {
        BOOL lightMode=(i%2)==1;
        expect(SGRAppearanceApplyMode(lightMode?SGRAppearanceLight:SGRAppearanceDark,NO),@"retained native navigation survives repeated live theme transitions");
        expect(bar.overrideUserInterfaceStyle==(lightMode?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark),@"retained navigation bar follows each committed appearance");
    }
    bar.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;bar.barStyle=UIBarStyleBlack;bar.tintColor=UIColor.whiteColor;
    expect(bar.overrideUserInterfaceStyle==UIUserInterfaceStyleLight && bar.barStyle==UIBarStyleDefault && contrast(bar.tintColor,backdrop)>=7,@"late native forced-dark/style/white-tint assignments cannot split Light Back chrome");
    AVPlayerViewController *media=[AVPlayerViewController new];
    media.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    [navigation pushViewController:media animated:NO];navigationSettle(window);
    expect(bar.overrideUserInterfaceStyle==UIUserInterfaceStyleDark && bar.barStyle==UIBarStyleBlack && [bar.tintColor isEqual:UIColor.whiteColor],@"pushing unowned OS video restores latest original bar policy despite retained owned page below it");
    expect(media.overrideUserInterfaceStyle==UIUserInterfaceStyleDark && media.view.overrideUserInterfaceStyle==UIUserInterfaceStyleUnspecified,@"OS video controller and video controls remain outside native Back appearance ownership");
    expect(SGRAppearanceApplyMode(SGRAppearanceDark,NO) && SGRAppearanceApplyMode(SGRAppearanceLight,NO),@"change theme while OS video is topmost");
    expect(bar.overrideUserInterfaceStyle==UIUserInterfaceStyleDark && bar.barStyle==UIBarStyleBlack && media.overrideUserInterfaceStyle==UIUserInterfaceStyleDark,@"unowned OS navigation is untouched by later theme callbacks");
    [navigation popViewControllerAnimated:NO];navigationSettle(window);
    expect(navigation.topViewController==page && bar.overrideUserInterfaceStyle==UIUserInterfaceStyleLight,@"native pop back into the retained owned page reacquires Light navigation styling");
    [navigation popViewControllerAnimated:NO];navigationSettle(window);
    expect(navigation.topViewController==root && bar.overrideUserInterfaceStyle==UIUserInterfaceStyleDark && bar.barStyle==UIBarStyleBlack,@"leaving the managed page restores original navigation appearance");
    // A registered page in an unrelated UIKit navigation controller is not authority
    // to alter its chrome, even if an external caller invokes the helper directly.
    UINavigationController *foreign=[[UINavigationController alloc] initWithRootViewController:page];
    [foreign loadViewIfNeeded];foreign.navigationBar.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    foreign.navigationBar.tintColor=UIColor.magentaColor;
    SGRRefreshNativeNavigationAppearance(foreign);
    expect(foreign.navigationBar.overrideUserInterfaceStyle==UIUserInterfaceStyleDark && [foreign.navigationBar.tintColor isEqual:UIColor.magentaColor],@"unowned UIKit navigation owner is untouched even with a registered descendant");
    NSDictionary *evidence=@{@"baselineMean":@(baselineMean),@"lightMean":@(lightMean),@"lightMeanAbsoluteDifference":@(changed),@"darkMeanAbsoluteDifference":@(darkDifference),@"backFrame":NSStringFromCGRect(backFrame)};
    NSString *directory=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
    [[NSJSONSerialization dataWithJSONObject:evidence options:NSJSONWritingPrettyPrinted error:nil] writeToFile:[directory stringByAppendingPathComponent:@"navigation-rendering.json"] atomically:YES];
    window.rootViewController=originalRoot;[window makeKeyAndVisible];
    expect(SGRAppearanceApplyMode(saved,NO),@"native navigation rendering fixture restores initial mode and window");
    navigationSettle(window);
}
