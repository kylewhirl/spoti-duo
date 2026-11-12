#import <CoreText/SFNTLayoutTypes.h>
#import "Core/SGCore.h"
#import "SGRTokens.h"
#import "SGRAccent.h"

const CGFloat SGRSideMargin = 16;
const CGFloat SGRGrid = 8;
const CGFloat SGRRadiusArtwork = 12;
const CGFloat SGRRadiusCard = 16;
const CGFloat SGRRadiusCover = 8;
const CGFloat SGRRadiusThumb = 6;
const CGFloat SGRGlassCircleSize = 44;
const CGFloat SGRActionHeight = 48;
const CGFloat SGRActionSpacing = 12;
const CGFloat SGRGlassSpacing = 16;
const NSTimeInterval SGRCrossfade = 0.35;

// A layout spring settles in about this long without overshooting; a press gives a little back.
static const NSTimeInterval kLayoutDuration = 0.45, kPressDuration = 0.32;
static const CGFloat kPressDamping = 0.62;

// Immutable role tables swapped together, so background/ink never see half a palette.
static NSArray<UIColor *> *artworkLightRoles, *artworkDarkRoles;
static UIColor *artworkSeed;
static NSObject *tonalLock(void) {
    static NSObject *lock; static dispatch_once_t once;
    dispatch_once(&once, ^{ lock=[NSObject new]; }); return lock;
}
static CGFloat tonalLinear(CGFloat c) { return c<=.04045?c/12.92:pow((c+.055)/1.055,2.4); }
static CGFloat tonalEncoded(CGFloat c) { return c<=.0031308?c*12.92:1.055*pow(c,1/2.4)-.055; }
// Preserve the seed's chromatic direction at a specified relative luminance. Gamut-limit
// chroma rather than clipping channels (which would alter luminance and break contrast).
static UIColor *tonalColor(CGFloat r, CGFloat g, CGFloat b, CGFloat y, CGFloat chroma) {
    CGFloat lum=.2126*r+.7152*g+.0722*b, delta[]={r-lum,g-lum,b-lum};
    CGFloat largest=MAX(fabs(delta[0]),MAX(fabs(delta[1]),fabs(delta[2])));
    CGFloat scale=largest>.000001?MIN(y,1-y)*chroma/largest:0;
    for (int i=0;i<3;i++) {
        if (delta[i]>0) scale=MIN(scale,(1-y)/delta[i]);
        else if (delta[i]<0) scale=MIN(scale,-y/delta[i]);
    }
    CGFloat c[]={tonalEncoded(y+scale*delta[0]),tonalEncoded(y+scale*delta[1]),tonalEncoded(y+scale*delta[2]),1};
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGColorRef cg=CGColorCreate(space,c); UIColor *color=[UIColor colorWithCGColor:cg];
    CGColorRelease(cg); CGColorSpaceRelease(space); return color;
}
BOOL SGRSetArtworkTonalPalette(UIColor *dominant, BOOL enabled) {
    NSCAssert(NSThread.isMainThread,@"Tonal palette commits are main-thread only");
    CGFloat r=0,g=0,b=0,a=0;
    BOOL valid=enabled && dominant && [dominant getRed:&r green:&g blue:&b alpha:&a] &&
        isfinite(r) && isfinite(g) && isfinite(b) && isfinite(a) && a>0;
    @synchronized(tonalLock()) {
        if (!valid) { BOOL changed=artworkSeed!=nil; artworkSeed=nil; artworkLightRoles=nil; artworkDarkRoles=nil; return changed; }
        if ([artworkSeed isEqual:dominant]) return NO;
        r=tonalLinear(MIN(1,MAX(0,r))); g=tonalLinear(MIN(1,MAX(0,g))); b=tonalLinear(MIN(1,MAX(0,b)));
        // Text passes >=4.5:1 even on the strongest selected surface, without alpha stacking.
        const CGFloat light[]={.90,.80,.015,.07,.10,.36,.70};
        const CGFloat dark[]={.018,.035,.95,.68,.52,.24,.07};
        NSMutableArray *l=[NSMutableArray new], *d=[NSMutableArray new];
        for (NSUInteger i=0;i<7;i++) {
            CGFloat chroma=(i>=SGRArtworkRolePrimary && i<=SGRArtworkRoleTertiary)?.25:.85;
            [l addObject:tonalColor(r,g,b,light[i],chroma)]; [d addObject:tonalColor(r,g,b,dark[i],chroma)];
        }
        artworkLightRoles=[l copy]; artworkDarkRoles=[d copy]; artworkSeed=dominant; return YES;
    }
}
BOOL SGRArtworkTonalActive(void) { @synchronized(tonalLock()) { return artworkSeed!=nil; } }
UIColor *SGRArtworkRoleColor(SGRArtworkRole role, BOOL light) {
    @synchronized(tonalLock()) { NSArray *roles=light?artworkLightRoles:artworkDarkRoles; return role>=0 && role<roles.count?roles[role]:nil; }
}
static UIColor *tonalToken(SGRArtworkRole role, UIColor *light, UIColor *dark) {
    static NSCache *cache; static dispatch_once_t once;
    dispatch_once(&once, ^{ cache=[NSCache new]; cache.countLimit=256; });
    NSArray *key=@[@(role),light,dark]; UIColor *color=[cache objectForKey:key];
    if (!color) {
        color=[UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
            // Reads the color-affecting revision trait as well as local appearance scope.
            BOOL isLight=SGAppearanceStyleForTraits(traits)==UIUserInterfaceStyleLight;
            return SGRArtworkRoleColor(role,isLight) ?: [(isLight?light:dark) resolvedColorWithTraitCollection:traits];
        }];
        [cache setObject:color forKey:key];
    }
    return color;
}

UIColor *SGRPrimary(void) {
    return tonalToken(SGRArtworkRolePrimary,[UIColor colorWithWhite:0.08 alpha:1], UIColor.whiteColor);
}

UIColor *SGRSecondary(void) {
    return tonalToken(SGRArtworkRoleSecondary,[UIColor colorWithWhite:SGRIncreaseContrast() ? 0.22 : 0.30 alpha:1],
        [UIColor colorWithWhite:1 alpha:SGRIncreaseContrast() ? 0.80 : 0.65]);
}

UIColor *SGRTertiary(void) {
    return tonalToken(SGRArtworkRoleTertiary,[UIColor colorWithWhite:SGRIncreaseContrast() ? 0.30 : 0.40 alpha:1],
        [UIColor colorWithWhite:1 alpha:SGRIncreaseContrast() ? 0.60 : 0.40]);
}

// Read per call: the accent is stored as it is picked, and the colour row reads it the same way.
UIColor *SGRAccent(void) {
    // Resolve the selected hue at draw time, not when a retained control is created.
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        UIColor *color=SGRAccentColor() ?: [UIColor colorWithRed:0x1E/255.0 green:0xD7/255.0 blue:0x60/255.0 alpha:1];
        CGFloat r=0,g=0,b=0,a=1;
        if (![color getRed:&r green:&g blue:&b alpha:&a]) return color;
        CGFloat maximum=MAX(r,MAX(g,b));
        CGFloat scale=SGAppearanceStyleForTraits(traits)==UIUserInterfaceStyleLight && maximum>.40 ? .40/maximum : 1;
        return [UIColor colorWithRed:r*scale green:g*scale blue:b*scale alpha:a];
    }];
}

UIColor *SGRNeutralField(void) {
    return tonalToken(SGRArtworkRoleBase,[UIColor colorWithWhite:0.97 alpha:1], [UIColor colorWithWhite:0x12 / 255.0 alpha:1]);
}

UIColor *SGRSolidGlassFill(void) {
    return tonalToken(SGRArtworkRoleElevated,[UIColor colorWithWhite:0.92 alpha:1], [UIColor colorWithWhite:1 alpha:0.16]);
}

UIColor *SGRHairline(void) {
    CGFloat alpha = SGRIncreaseContrast() ? 0.20 : 0.12;
    // Dividers organize content; they are not accent or artwork-palette surfaces.
    return SGAppearanceColor([UIColor colorWithWhite:0 alpha:alpha], [UIColor colorWithWhite:1 alpha:alpha]);
}

UIColor *SGRElevated(UIColor *field) {
    CGFloat r = 0, g = 0, b = 0, a = 1;
    if (![field getRed:&r green:&g blue:&b alpha:&a]) return tonalToken(SGRArtworkRoleElevated,[UIColor colorWithWhite:0.92 alpha:1], [UIColor colorWithWhite:1 alpha:0.08]);
    // 12% towards white keeps a card on a black field clear of the greys SGRAmoled.x turns black.
    CGFloat lift = 0.12;
    return tonalToken(SGRArtworkRoleElevated,[UIColor colorWithWhite:0.92 alpha:1],
        [UIColor colorWithRed:r + (1 - r) * lift green:g + (1 - g) * lift blue:b + (1 - b) * lift alpha:1]);
}

UIFont *SGRFont(UIFontTextStyle style, UIFontWeight weight, UIContentSizeCategory largest) {
    UIContentSizeCategory current = UIApplication.sharedApplication.preferredContentSizeCategory;
    if (largest && UIContentSizeCategoryCompareToCategory(current, largest) == NSOrderedDescending) current = largest;
    UITraitCollection *traits = [UITraitCollection traitCollectionWithPreferredContentSizeCategory:current];
    CGFloat size = [UIFont preferredFontForTextStyle:style compatibleWithTraitCollection:traits].pointSize;
    return [UIFont systemFontOfSize:size weight:weight];
}

UIFont *SGRMonospacedDigitsFont(UIFont *font) {
    if (!font) return nil;
    NSArray *features = @[@{UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType), UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}];
    UIFontDescriptor *descriptor = [font.fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorFeatureSettingsAttribute: features}];
    return [UIFont fontWithDescriptor:descriptor size:font.pointSize];
}

BOOL SGRReduceMotion(void) {
    return UIAccessibilityIsReduceMotionEnabled();
}

BOOL SGRReduceTransparency(void) {
    return UIAccessibilityIsReduceTransparencyEnabled();
}

BOOL SGRIncreaseContrast(void) {
    return UIAccessibilityDarkerSystemColorsEnabled();
}

void SGRAnimate(SGRMotion motion, void (^animations)(void), void (^completion)(BOOL finished)) {
    if (!animations) return;
    if (motion != SGRMotionFade && SGRReduceMotion()) {
        [UIView performWithoutAnimation:animations];
        if (completion) completion(YES);
        return;
    }
    UIViewAnimationOptions options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState;
    switch (motion) {
        case SGRMotionLayout:
            [UIView animateWithDuration:kLayoutDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:options animations:animations completion:completion];
            break;
        case SGRMotionPress:
            [UIView animateWithDuration:kPressDuration delay:0 usingSpringWithDamping:kPressDamping initialSpringVelocity:0 options:options animations:animations completion:completion];
            break;
        case SGRMotionFade:
            [UIView animateWithDuration:SGRCrossfade delay:0 options:options | UIViewAnimationOptionCurveEaseInOut animations:animations completion:completion];
            break;
    }
}

BOOL SGRIsBaseSurface(CGColorRef color) {
    if (SGIsBaseSurface(color)) return YES;
    if (!SGRedesignLightAppearance() || !color || CGColorGetAlpha(color) < 0.99) return NO;
    UIColor *value = [UIColor colorWithCGColor:color];
    CGFloat r, g, b, a;
    return [value getRed:&r green:&g blue:&b alpha:&a] && r >= 0.95 && fabs(r-g) < 0.01 && fabs(g-b) < 0.01;
}
