// Spotify 9.1.94 has independent native Swift and Objective-C theme stores. Commit both,
// verify through original accessors, then publish to registered semantic/owned surfaces.
#import "Core/SGCore.h"
#import "SGRAppearance.h"
#import "SGRNativeTheme.h"
#import "SGRNativeSurface.h"
#import "SGRShareControls.h"
#import "SGRBridges.h"
#import "SGRPalette.h"
#import "SGRAccent.h"
#import "SGRTokens.h"

@interface SPTEncoreColorTheme : NSObject
+ (instancetype)main;
+ (void)setMain:(SPTEncoreColorTheme *)theme;
+ (instancetype)light;
+ (instancetype)dark;
@end

static UIUserInterfaceStyle artworkStyle;
static UIColor *artworkAccent;
static NSString *artworkIdentity;
static NSUInteger artworkGeneration;
static id selectedTheme;
static BOOL available, apiReady, requestQueued;
static NSInteger appliedMode;
static id (*originalObjCMain)(id, SEL);
static void (*originalObjCSetMain)(id, SEL, id);
static NSString *lastFailure;
static NSHashTable<UIWindowScene *> *observedScenes;
static NSMutableArray<UIView *> *transitionCovers;

BOOL SGRAppearanceBridgeAvailable(void) { return available; }
BOOL SGRAppearanceNeedsRestart(void) {
    return SGInt(SGRKeyAppearance, SGRAppearanceSystem) != appliedMode;
}
NSString *SGRAppearanceStatus(void) {
    if (!available) return @"Unavailable · Dark fallback";
    if (lastFailure) return lastFailure;
    if (!SGRNativeThemeMatches(SGRedesignLightAppearance()) ||
        originalObjCMain(NSClassFromString(@"SPTEncoreColorTheme"), @selector(main)) != selectedTheme)
        return @"Theme changed · Retry appearance";
    return SGRedesignLightAppearance() ? @"Light" : @"Dark";
}

static UIUserInterfaceStyle systemStyle(void) {
    // Scene/screen traits are outside Spotify's forced-dark controllers and our registered
    // overrides. Never resolve System from a forced view or a window's effective style.
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class] && scene.activationState == UISceneActivationStateForegroundActive) {
            UIUserInterfaceStyle style=((UIWindowScene *)scene).traitCollection.userInterfaceStyle;
            if (style != UIUserInterfaceStyleUnspecified) return style;
        }
    }
    return UIScreen.mainScreen.traitCollection.userInterfaceStyle;
}
static BOOL objectGetter(Class cls, SEL selector) {
    Method method=class_getClassMethod(cls,selector);
    if (!method || method_getNumberOfArguments(method)!=2) return NO;
    char type[16]={0}; method_getReturnType(method,type,sizeof(type));
    return type[0]=='@';
}
static BOOL setProviders(Class cls, id desired, BOOL light) {
    id previous=originalObjCMain(cls,@selector(main));
    __block BOOL objcChanged=NO;
    BOOL result=SGRSetNativeTheme(light,^BOOL{
        objcChanged=YES;
        originalObjCSetMain(cls,@selector(setMain:),desired);
        return originalObjCMain(cls,@selector(main))==desired && SGRNativeThemeMatches(light);
    });
    if (!result && objcChanged) originalObjCSetMain(cls,@selector(setMain:),previous);
    return result;
}
static void clearCovers(void) {
    for (UIView *cover in transitionCovers) { [cover.layer removeAllAnimations]; [cover removeFromSuperview]; }
    transitionCovers=nil;
}
static NSArray<UIView *> *captureCovers(BOOL animated) {
    clearCovers();
    if (!animated || UIAccessibilityIsReduceMotionEnabled()) return @[];
    NSMutableArray<UIView *> *covers=[NSMutableArray new];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class] || scene.activationState!=UISceneActivationStateForegroundActive) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.hidden || window.alpha<=0 || window.windowLevel!=UIWindowLevelNormal) continue;
            UIView *cover=[window snapshotViewAfterScreenUpdates:NO];
            if (!cover) continue;
            cover.frame=window.bounds;
            cover.userInteractionEnabled=NO;
            cover.accessibilityElementsHidden=YES;
            [window addSubview:cover]; [covers addObject:cover];
        }
    }
    transitionCovers=covers;
    return covers;
}
BOOL SGRAppearanceApplyMode(NSInteger mode, BOOL animated) {
    if (!NSThread.isMainThread || !apiReady) return NO;
    SGLog(@"appearance request: mode=%ld accentArtwork=%d artStyle=%ld generation=%lu",(long)mode,SGInt(SGRKeyAccentArtwork,0)==1,(long)artworkStyle,(unsigned long)artworkGeneration);
    BOOL light=mode==SGRAppearanceLight || ((mode==SGRAppearanceSystem || (mode==SGRAppearanceArtwork && !artworkStyle)) && systemStyle()==UIUserInterfaceStyleLight) || (mode==SGRAppearanceArtwork && artworkStyle==UIUserInterfaceStyleLight);
    Class cls=NSClassFromString(@"SPTEncoreColorTheme");
    id desired=light?[cls light]:[cls dark];
    if (!desired || ![desired isKindOfClass:cls]) { lastFailure=@"Could not apply · Previous theme kept"; return NO; }
    if (available && selectedTheme==desired && SGRNativeThemeMatches(light) && originalObjCMain(cls,@selector(main))==desired) {
        appliedMode=mode; lastFailure=nil;
        BOOL paletteChanged=SGRSetArtworkTonalPalette(artworkAccent,SGInt(SGRKeyArtworkPalette,mode==SGRAppearanceArtwork ? 1 : 0)==1);
        SGRSetArtworkAccent(artworkAccent,light);
        SGRPlayerApplyAppearancePreference();
        if (paletteChanged) [UIView performWithoutAnimation:^{
            [CATransaction begin]; [CATransaction setDisableActions:YES];
            SGInvalidateAppearanceColors();
            SGRefreshAppearanceOwners();
            SGRRefreshNativeSurfaces();
            [CATransaction commit];
        }];
        return YES;
    }
    NSArray<UIView *> *covers=captureCovers(animated);
    if (!setProviders(cls,desired,light)) {
        clearCovers(); lastFailure=@"Could not apply · Previous theme kept";
        SGLog(@"appearance: provider transaction rejected; previous rendered theme retained");
        return NO;
    }
    // No UI or global appearance is published until BOTH independent stores verify.
    selectedTheme=desired;
    available=YES;
    appliedMode=mode;
    lastFailure=nil;
    SGRPlayerApplyAppearancePreference();
    [UIView performWithoutAnimation:^{
        [CATransaction begin]; [CATransaction setDisableActions:YES];
        SGConfigureRedesignAppearance(light?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark);
        BOOL paletteChanged=SGRSetArtworkTonalPalette(artworkAccent,SGInt(SGRKeyArtworkPalette,mode==SGRAppearanceArtwork ? 1 : 0)==1);
        if (paletteChanged) SGInvalidateAppearanceColors();
        SGRSetArtworkAccent(artworkAccent,light);
        SGRefreshAppearanceOwners();
        SGRRefreshNativeSurfaces();
        [CATransaction commit];
    }];
    if (covers.count) {
        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{ for (UIView *cover in covers) cover.alpha=0; }
                         completion:^(BOOL done) { for (UIView *cover in covers) [cover removeFromSuperview]; if (transitionCovers==covers) transitionCovers=nil; }];
    }
    SGLog(@"appearance: %@ applied live%@",light?@"light":@"dark",mode==SGRAppearanceSystem?@" from system":@"");
    return YES;
}
void SGRAppearanceApplyPreference(void) {
    if (!NSThread.isMainThread) { dispatch_async(dispatch_get_main_queue(),^{ SGRAppearanceApplyPreference(); }); return; }
    if (requestQueued) return;
    requestQueued=YES;
    dispatch_async(dispatch_get_main_queue(),^{
        requestQueued=NO;
        SGRAppearanceApplyMode(SGInt(SGRKeyAppearance,SGRAppearanceSystem),YES);
    });
}
NSUInteger SGRAppearanceArtworkGeneration(void) { return artworkGeneration; }
void SGRAppearanceAcceptArtworkPalette(SGRPalette *palette, NSString *identity, NSUInteger generation) {
    NSCAssert(NSThread.isMainThread,@"Artwork appearance is main-thread only");
    if (generation!=artworkGeneration || ![identity isEqual:artworkIdentity]) return;
    artworkStyle=palette && isfinite(palette.artworkLuminance) ? (palette.artworkLuminance>=.45?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark) : UIUserInterfaceStyleUnspecified;
    artworkAccent=palette.rawDominantColor ?: palette.edgeColor;
    SGRAppearanceApplyPreference();
}
void SGRAppearanceArtworkDidChange(void) {
    if (!NSThread.isMainThread) { dispatch_async(dispatch_get_main_queue(),^{ SGRAppearanceArtworkDidChange(); }); return; }
    NSString *identity=nil;
    UIImage *image=SGRCurrentNowPlayingArtwork(&identity);
    if (image && [artworkIdentity isEqual:identity]) return;
    NSUInteger generation=++artworkGeneration;
    artworkIdentity=image?[identity copy]:nil;
    // Keep the last successful palette while the next image or its palette is loading.
    // Only truly missing/failed artwork falls back to System/manual accent.
    if (!image || !identity) {
        if (!SGRCurrentNowPlayingArtworkPending()) {
            artworkStyle=UIUserInterfaceStyleUnspecified; artworkAccent=nil;
            SGRAppearanceApplyPreference();
        }
        return;
    }
    SGRPaletteRequest request={0};
    [SGRPalette paletteForImage:image request:request completion:^(SGRPalette *palette) {
        SGRAppearanceAcceptArtworkPalette(palette,identity,generation);
    }];
}
@interface SGRGlobalArtworkAppearanceObserver : NSObject <SGPlayerStateObserver> @end
@implementation SGRGlobalArtworkAppearanceObserver
- (void)playerStateDidChange:(SPTPlayerState *)state { SGRAppearanceArtworkDidChange(); }
@end
static SGRGlobalArtworkAppearanceObserver *artworkObserver;
static void observeScenes(void) {
    if (!observedScenes) observedScenes=[NSHashTable weakObjectsHashTable];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class] || [observedScenes containsObject:(id)scene]) continue;
        [observedScenes addObject:(id)scene];
        if (@available(iOS 17.0,*)) {
            [(UIWindowScene *)scene registerForTraitChanges:@[UITraitUserInterfaceStyle.class] withHandler:^(id<UITraitEnvironment> environment, UITraitCollection *previous) {
                if (SGInt(SGRKeyAppearance,SGRAppearanceSystem)>=SGRAppearanceSystem) SGRAppearanceApplyPreference();
            }];
        }
    }
}
static void beginSystemObservation(void) {
    observeScenes();
    for (NSNotificationName name in @[UIApplicationDidBecomeActiveNotification,UISceneDidActivateNotification,UISceneWillConnectNotification]) {
        [NSNotificationCenter.defaultCenter addObserverForName:name object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
            observeScenes();
            if (SGInt(SGRKeyAppearance,SGRAppearanceSystem)>=SGRAppearanceSystem) SGRAppearanceApplyPreference();
        }];
    }
}

%group SGRAppearanceBridge
%hook SPTEncoreColorTheme
+ (id)main { return selectedTheme ?: %orig; }
+ (void)setMain:(id)theme { %orig(selectedTheme ?: theme); }
%end
%end

%group SGRSystemAppearanceObservation
%hook UIScreen
- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    %orig;
    if (SGInt(SGRKeyAppearance,SGRAppearanceSystem)>=SGRAppearanceSystem &&
        previous.userInterfaceStyle!=self.traitCollection.userInterfaceStyle)
        SGRAppearanceApplyPreference();
}
%end
%end

%ctor {
    if (!SGRedesignedUI()) return;
    appliedMode=SGInt(SGRKeyAppearance,SGRAppearanceSystem);
    Class cls=NSClassFromString(@"SPTEncoreColorTheme");
    Method setter=class_getClassMethod(cls,@selector(setMain:));
    char result[16]={0}, argument[16]={0};
    if (setter) { method_getReturnType(setter,result,sizeof(result)); method_getArgumentType(setter,2,argument,sizeof(argument)); }
    if (!objectGetter(cls,@selector(main)) || !objectGetter(cls,@selector(light)) || !objectGetter(cls,@selector(dark)) ||
        !setter || method_getNumberOfArguments(setter)!=3 || result[0]!='v' || argument[0]!='@') {
        SGLog(@"appearance: semantic theme API unavailable; keeping dark fallback"); return;
    }
    originalObjCMain=(id (*)(id,SEL))method_getImplementation(class_getClassMethod(cls,@selector(main)));
    originalObjCSetMain=(void (*)(id,SEL,id))method_getImplementation(setter);
    apiReady=YES;
    %init(SGRSystemAppearanceObservation);
    // Install the validated accessors even if the first transaction is rejected. With no
    // selected theme they pass through; a later successful retry becomes pinned correctly.
    %init(SGRAppearanceBridge, SPTEncoreColorTheme=cls);
    SGRAppearanceApplyMode(appliedMode,NO);
    // These share controls explicitly use Dark or baked white pixels. Install only
    // the exact validated native callsites, after semantic providers are ready.
    BOOL shareControls=SGRInstallShareActionPalette();
    SGLog(@"appearance: scoped share controls %@",shareControls?@"enabled":@"not enabled; native rendering retained");
    dispatch_async(dispatch_get_main_queue(),^{
        beginSystemObservation();
        artworkObserver=[SGRGlobalArtworkAppearanceObserver new]; SGAddPlayerStateObserver(artworkObserver);
        [NSNotificationCenter.defaultCenter addObserverForName:SGRNowPlayingArtworkDidChangeNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) { SGRAppearanceArtworkDidChange(); }];
        SGRAppearanceArtworkDidChange();
    });
}
