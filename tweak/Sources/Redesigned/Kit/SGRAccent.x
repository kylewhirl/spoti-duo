// The redesign's accent colour, chosen apart from the native look's: its copy of Native/Appearance/Accent.x.
// Accent colour: Spotify's green, #1ED760, is one token. Its three components occur once in the
// whole binary, and every green the app draws, from the play button to the "Zobrazit vše" links
// and the progress bar, is that token or a state blended from it. So it is swapped where it is
// born, in the UIColor initialiser, and the blends follow. Lottie animations carry their own green
// and are caught at the layer, below. Image assets with green baked in, the logo above all, are
// out of reach.
#import "Core/SGCore.h"
#import "SGRAccent.h"
#import "SGRAppearance.h"
#import <stdatomic.h>
#import <objc/runtime.h>
#import "Settings/SGPageStyle.h"

// The greens the app is known to build from literals: the token, and the older brand green the
// upsell backend still names.
static const uint32_t kGreens[] = {0x1ED760, 0x1DB954};

static _Atomic(NSInteger) sg_accent = -1;   // 0xRRGGBB once chosen, read at launch

// The redesign's own green until another is picked; Spotify's is a pick of its own, stored as -1.
static const NSInteger kDefaultAccent = 0x37F200;

static void refreshRetainedAccents(void);
static BOOL accentLight;
static NSInteger artworkRGB=-1;
static NSInteger chosen(void) {
    NSInteger rgb = SGInt(SGRKeyAccent, kDefaultAccent);
    return rgb >= 0 && rgb <= 0xFFFFFF ? rgb : -1;
}

static void unpack(uint32_t rgb, CGFloat *r, CGFloat *g, CGFloat *b) {
    *r = ((rgb >> 16) & 0xFF) / 255.0;
    *g = ((rgb >> 8) & 0xFF) / 255.0;
    *b = (rgb & 0xFF) / 255.0;
}

static NSInteger effective(void) { return SGInt(SGRKeyAccentArtwork,0)==1 && artworkRGB>=0 ? artworkRGB : chosen(); }
static CGFloat luminance(CGFloat r,CGFloat g,CGFloat b) {
    CGFloat a[]={r,g,b}; for(int i=0;i<3;i++) a[i]=a[i]<=.04045?a[i]/12.92:pow((a[i]+.055)/1.055,2.4);
    return .2126*a[0]+.7152*a[1]+.0722*a[2];
}
void SGRSetArtworkAccent(UIColor *color, BOOL light) {
    CGFloat r=0,g=0,b=0,a=0; artworkRGB=-1;
    if (color && [color getRed:&r green:&g blue:&b alpha:&a]) {
        // Filled native controls keep black icons legible. SGRAccent separately darkens light foregrounds.
        for(int n=0;n<100;n++) {
            CGFloat l=luminance(r,g,b);
            if (light ? (l>=.18 && l<=.30) : l>=.32) break;
            if(light && l>.30) {r*=.96;g*=.96;b*=.96;} else {r+=(1-r)*.04;g+=(1-g)*.04;b+=(1-b)*.04;}
        }
        artworkRGB=((NSInteger)lround(r*255)<<16)|((NSInteger)lround(g*255)<<8)|(NSInteger)lround(b*255);
    }
    NSInteger next=effective(); BOOL rgbChanged=next!=atomic_load(&sg_accent); BOOL changed=rgbChanged || accentLight!=light; accentLight=light; atomic_store(&sg_accent,next);
    if(changed) refreshRetainedAccents();
    if(rgbChanged) SGRefreshAppearanceOwners();
}
UIColor *SGRAccentColor(void) {
    NSInteger rgb = effective();
    if (rgb < 0) return nil;
    CGFloat r, g, b;
    unpack((uint32_t)rgb, &r, &g, &b);
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

NSString *SGRAccentLabel(void) {
    NSInteger rgb = chosen();
    if (SGInt(SGRKeyAccentArtwork,0)==1) return @"Match artwork";
    return rgb < 0 ? @"Spotify green" : [NSString stringWithFormat:@"#%06lX", (long)rgb];
}

#pragma mark - picker

@interface SGRAccentPicker : NSObject <UIColorPickerViewControllerDelegate>
@end

@implementation SGRAccentPicker

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)picker {
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [picker.selectedColor getRed:&r green:&g blue:&b alpha:&a];
    uint32_t rgb = ((uint32_t)lround(MIN(1, MAX(0, r)) * 255) << 16)
                 | ((uint32_t)lround(MIN(1, MAX(0, g)) * 255) << 8)
                 | (uint32_t)lround(MIN(1, MAX(0, b)) * 255);
    SGSetInt(SGRKeyAccent, rgb);
    SGSetInt(SGRKeyAccentArtwork,0); SGRAppearanceApplyPreference();
}

@end

void SGRPickAccent(void) {
    static SGRAccentPicker *delegate;
    if (!delegate) delegate = [SGRAccentPicker new];
    UIColorPickerViewController *picker = [UIColorPickerViewController new];
    picker.supportsAlpha = NO;
    picker.selectedColor = SGRAccentColor() ?: [UIColor colorWithRed:0x1E / 255.0 green:0xD7 / 255.0 blue:0x60 / 255.0 alpha:1];
    picker.delegate = delegate;
    [SGTopController() presentViewController:picker animated:YES completion:nil];
}

// A darker green than the token comes out as the accent darkened by the same amount, so the two
// keep their relation.
static BOOL swap(CGFloat *r, CGFloat *g, CGFloat *b) {
    NSInteger accent=atomic_load(&sg_accent); if(accent<0) return NO;
    for (size_t i = 0; i < sizeof(kGreens) / sizeof(kGreens[0]); i++) {
        CGFloat gr, gg, gb;
        unpack(kGreens[i], &gr, &gg, &gb);
        if (fabs(*r - gr) > 0.01 || fabs(*g - gg) > 0.01 || fabs(*b - gb) > 0.01) continue;
        CGFloat ar, ag, ab;
        unpack((uint32_t)accent, &ar, &ag, &ab);
        CGFloat factor = MAX(gr, MAX(gg, gb)) / (0xD7 / 255.0);
        *r = MIN(1, ar * factor);
        *g = MIN(1, ag * factor);
        *b = MIN(1, ab * factor);
        return YES;
    }
    return NO;
}

// Source provenance is attached only where the two known semantic tokens are constructed.
// No arbitrary view-tree color matching or artwork traversal.
static char sourceKey, ownersKey, imageRecipeKey, imageTraitRegistrationKey;
static NSHashTable *accentOwners;
static NSObject *accentLock;
static NSMapTable *cgSources;
static NSMutableArray *cgSourceOrder;
static _Thread_local BOOL replayingAccent;
static BOOL sourceRGB(CGFloat r,CGFloat g,CGFloat b) {
    for(unsigned i=0;i<sizeof(kGreens)/sizeof(kGreens[0]);i++) {
        CGFloat x,y,z;unpack(kGreens[i],&x,&y,&z);
        if(fabs(r-x)<.01 && fabs(g-y)<.01 && fabs(b-z)<.01) return YES;
    } return NO;
}
static UIColor *sourceColor(CGFloat r,CGFloat g,CGFloat b,CGFloat a) {
    CGFloat c[]={r,g,b,a}; CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();
    CGColorRef cg=CGColorCreate(space,c); UIColor *color=[UIColor colorWithCGColor:cg];
    CGColorRelease(cg);CGColorSpaceRelease(space);return color;
}
// Strong bounded pointer-identity cache: retaining keys prevents CGColor address reuse.
static void rememberCG(CGColorRef color,UIColor *source) {
    if(!color||!source)return;
    @synchronized(accentLock) {
        id key=(__bridge id)color;
        if(![cgSources objectForKey:key]) [cgSourceOrder addObject:key];
        [cgSources setObject:source forKey:key];
        while(cgSourceOrder.count>512) {id first=cgSourceOrder.firstObject;[cgSources removeObjectForKey:first];[cgSourceOrder removeObjectAtIndex:0];}
    }
}
static UIColor *originalCG(CGColorRef color) {
    if(!color)return nil;
    @synchronized(accentLock) {return [cgSources objectForKey:(__bridge id)color];}
}
static void trackSource(id owner,NSString *property,id source) {
    if(replayingAccent) return;
    @synchronized(accentLock) {
        NSMutableDictionary *sources=objc_getAssociatedObject(owner,&ownersKey);
        if(!sources && source) {sources=[NSMutableDictionary new];objc_setAssociatedObject(owner,&ownersKey,sources,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
        if(source) {sources[property]=source;[accentOwners addObject:owner];}
        else { [sources removeObjectForKey:property]; if(!sources.count)[accentOwners removeObject:owner]; }
    }
}
static UIColor *mappedSource(UIColor *source,BOOL foreground) {
    CGFloat r=0,g=0,b=0,a=1;[source getRed:&r green:&g blue:&b alpha:&a];swap(&r,&g,&b);
    // Foreground contrast follows the receiving view's local artwork scope, not
    // only the app-wide style. Preserve +0 factory ownership and token provenance.
    BOOL artwork=SGInt(SGRKeyAccentArtwork,0)==1 && artworkRGB>=0;
    UIColor *mapped=[UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        CGFloat rr=r,gg=g,bb=b;
        if(foreground && artwork && SGAppearanceStyleForTraits(traits)==UIUserInterfaceStyleLight) {
            CGFloat max=MAX(rr,MAX(gg,bb));if(max>.4){rr*=.4/max;gg*=.4/max;bb*=.4/max;}
        }
        return sourceColor(rr,gg,bb,a);
    }];
    objc_setAssociatedObject(mapped,&sourceKey,source,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    rememberCG(mapped.CGColor,source);
    return mapped;
}
static UIColor *trackedColor(id owner,NSString *property,UIColor *color,BOOL foreground) {
    UIColor *source=objc_getAssociatedObject(color,&sourceKey);
    trackSource(owner,property,source);
    return source?mappedSource(source,foreground):color;
}
%hook UIColor
- (UIColor *)initWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a {
    // init returns +1. Logos C hooks do not infer Objective-C method-family ownership.
    // Preserve the original init result/ownership; only the +0 class factory wraps tokens.
    swap(&r,&g,&b);
    return %orig(r,g,b,a);
}

+ (UIColor *)colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a {
    BOOL semantic=sourceRGB(r,g,b); UIColor *source=semantic?sourceColor(r,g,b,a):nil;
    swap(&r,&g,&b); UIColor *result=%orig(r,g,b,a);
    if(source) { UIColor *resolved=sourceColor(r,g,b,a); result=[UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {return resolved;}]; objc_setAssociatedObject(result,&sourceKey,source,OBJC_ASSOCIATION_RETAIN_NONATOMIC); rememberCG(result.CGColor,source); }
    return result;
}
%end
%group SGRAccentDynamicSources
%hook SGRTokenDynamicColor
- (UIColor *)colorWithAlphaComponent:(CGFloat)alpha {
    UIColor *result=%orig;
    UIColor *source=objc_getAssociatedObject(self,&sourceKey);
    if(!source) return result;
    source=[source colorWithAlphaComponent:alpha];
    UIColor *resolved=result;
    UIColor *wrapped=[UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {return [resolved resolvedColorWithTraitCollection:traits];}];
    objc_setAssociatedObject(wrapped,&sourceKey,source,OBJC_ASSOCIATION_RETAIN_NONATOMIC);rememberCG(wrapped.CGColor,source);
    return wrapped;
}
%end
%end

// Baked-tint images do not respond to UIView.tintColor changes. Preserve a recipe
// only when UIKit receives a color carrying our semantic-token provenance. Never
// classify image pixels or recolor album artwork. These are all +0 UIImage methods.
static UIImage *imageFromRecipe(NSDictionary *recipe,UIView *owner) {
    UIImage *base=recipe[@"base"];
    UIImage *result=[base imageWithTintColor:[mappedSource(recipe[@"source"],YES) resolvedColorWithTraitCollection:owner.traitCollection]
                              renderingMode:[recipe[@"mode"] integerValue]];
    if(result && result!=base) objc_setAssociatedObject(result,&imageRecipeKey,recipe,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return result;
}
static UIImage *recordTintedImage(UIImage *base,UIColor *color,UIImage *result) {
    if(replayingAccent || !result || result==base) return result;
    UIColor *source=objc_getAssociatedObject(color,&sourceKey);
    if(source) {
        NSDictionary *recipe=@{@"base":base,@"source":source,@"mode":@(result.renderingMode)};
        objc_setAssociatedObject(result,&imageRecipeKey,recipe,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return result;
}
%hook UIImage
- (UIImage *)imageWithTintColor:(UIColor *)color {
    return recordTintedImage(self,color,%orig);
}
- (UIImage *)imageWithTintColor:(UIColor *)color renderingMode:(UIImageRenderingMode)mode {
    return recordTintedImage(self,color,%orig);
}
- (UIImage *)imageWithRenderingMode:(UIImageRenderingMode)mode {
    UIImage *result=%orig;
    NSDictionary *recipe=objc_getAssociatedObject(self,&imageRecipeKey);
    if(recipe && result && result!=self) {
        NSMutableDictionary *next=[recipe mutableCopy];next[@"mode"]=@(mode);
        objc_setAssociatedObject(result,&imageRecipeKey,next,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return result;
}
%end
// Trait observers are per-image-owner, not the shared appearance callback slot.
// They cannot overwrite another component's refresh registration.
static void refreshOwnerImages(UIView *owner) {
    NSDictionary *sources;@synchronized(accentLock){sources=[objc_getAssociatedObject(owner,&ownersKey) copy];}
    BOOL previous=replayingAccent;replayingAccent=YES;
    for(NSString *property in sources) {
        if([property isEqual:@"image"] || [property isEqual:@"highlightedImage"] || [property hasPrefix:@"imageState:"]) {
            UIImage *image=imageFromRecipe(sources[property],owner);
            if([property hasPrefix:@"imageState:"]) [(UIButton *)owner setImage:image forState:(UIControlState)[[property substringFromIndex:11] integerValue]];
            else [owner setValue:image forKey:property];
        }
    }
    replayingAccent=previous;
}
static void observeImageTraits(UIView *owner,NSDictionary *recipe) {
    if(!recipe || objc_getAssociatedObject(owner,&imageTraitRegistrationKey)) return;
    if(@available(iOS 17.0,*)) {
        NSMutableArray *traits=[NSMutableArray arrayWithObject:UITraitUserInterfaceStyle.class];
        Class local=NSClassFromString(@"SGRLocalAppearanceTrait");if(local)[traits addObject:local];
        id registration=[owner registerForTraitChanges:traits withHandler:^(id<UITraitEnvironment> environment,UITraitCollection *previous) {
            refreshOwnerImages((UIView *)environment);
        }];
        objc_setAssociatedObject(owner,&imageTraitRegistrationKey,registration,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}
%hook UIImageView
- (void)setImage:(UIImage *)image {
    NSDictionary *recipe=objc_getAssociatedObject(image,&imageRecipeKey);
    trackSource(self,@"image",recipe);observeImageTraits(self,recipe);
    %orig(recipe?imageFromRecipe(recipe,self):image);
}
- (void)setHighlightedImage:(UIImage *)image {
    NSDictionary *recipe=objc_getAssociatedObject(image,&imageRecipeKey);
    trackSource(self,@"highlightedImage",recipe);observeImageTraits(self,recipe);
    %orig(recipe?imageFromRecipe(recipe,self):image);
}
%end
%hook UIButton
- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    NSDictionary *recipe=objc_getAssociatedObject(image,&imageRecipeKey);
    trackSource(self,[NSString stringWithFormat:@"imageState:%lu",(unsigned long)state],recipe);observeImageTraits(self,recipe);
    %orig(recipe?imageFromRecipe(recipe,self):image,state);
}
%end

%hook UIView
- (void)setTintColor:(UIColor *)color { %orig(trackedColor(self,@"tintColor",color,YES)); }
- (void)setBackgroundColor:(UIColor *)color { %orig(trackedColor(self,@"backgroundColor",color,NO)); }
%end
%hook UILabel
- (void)setTextColor:(UIColor *)color { %orig(trackedColor(self,@"textColor",color,YES)); }
%end
%hook UIButton
- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state {
    %orig(trackedColor(self,[NSString stringWithFormat:@"title:%lu",(unsigned long)state],color,YES),state);
}
%end

// Lottie draws its animations, the play indicator and the checkmarks among them, from colours
// in the animation file straight onto shape layers, or into colour keyframes, never through
// UIColor. The same swap goes on the CGColor. Layers get set off the main thread too, so the
// copy is made with CoreGraphics alone; NULL when the colour is not one of the greens.
static CGColorRef swappedCopy(CGColorRef color) {
    if (!color || CFGetTypeID(color) != CGColorGetTypeID() || CGColorGetNumberOfComponents(color) != 4) return NULL;
    const CGFloat *c = CGColorGetComponents(color);
    CGFloat r = c[0], g = c[1], b = c[2];
    if (!swap(&r, &g, &b)) return NULL;
    CGFloat out[] = {r, g, b, c[3]};
    return CGColorCreate(CGColorGetColorSpace(color), out);
}

static id swappedValue(id value) {
    CGColorRef swapped = swappedCopy((__bridge CGColorRef)value);
    if (!swapped) return value;
    id boxed = (__bridge_transfer id)swapped;
    return boxed;
}

%hook CAShapeLayer
- (void)setFillColor:(CGColorRef)color {
    @synchronized(accentLock) {
    UIColor *source=originalCG(color);
    if(!source && color && CGColorGetNumberOfComponents(color)==4) { const CGFloat *c=CGColorGetComponents(color); if(sourceRGB(c[0],c[1],c[2]))source=[UIColor colorWithCGColor:color]; }
    trackSource(self,@"layerFill",source);
    CGColorRef swapped = swappedCopy(source ? source.CGColor : color);
    CGColorRef used = swapped ?: (source ? source.CGColor : color);
    %orig(used);
    if (swapped) CGColorRelease(swapped);
    }
}
- (void)setStrokeColor:(CGColorRef)color {
    @synchronized(accentLock) {
    UIColor *source=originalCG(color);
    if(!source && color && CGColorGetNumberOfComponents(color)==4) { const CGFloat *c=CGColorGetComponents(color); if(sourceRGB(c[0],c[1],c[2]))source=[UIColor colorWithCGColor:color]; }
    trackSource(self,@"layerStroke",source);
    CGColorRef swapped = swappedCopy(source ? source.CGColor : color);
    CGColorRef used = swapped ?: (source ? source.CGColor : color);
    %orig(used);
    if (swapped) CGColorRelease(swapped);
    }
}
%end

%hook CALayer
- (void)setBackgroundColor:(CGColorRef)color {
    @synchronized(accentLock) {
    UIColor *source=originalCG(color);
    if(!source && color && CGColorGetNumberOfComponents(color)==4) { const CGFloat *c=CGColorGetComponents(color); if(sourceRGB(c[0],c[1],c[2]))source=[UIColor colorWithCGColor:color]; }
    trackSource(self,@"layerBackground",source);
    CGColorRef swapped = swappedCopy(source ? source.CGColor : color);
    CGColorRef used = swapped ?: (source ? source.CGColor : color);
    %orig(used);
    if (swapped) CGColorRelease(swapped);
    }
}
%end

%hook CABasicAnimation
- (void)setFromValue:(id)value {
    id used = swappedValue(value);
    %orig(used);
}
- (void)setToValue:(id)value {
    id used = swappedValue(value);
    %orig(used);
}
%end

%hook CAKeyframeAnimation
- (void)setValues:(NSArray *)values {
    NSMutableArray *mapped = nil;
    for (NSUInteger i = 0; i < values.count; i++) {
        id swapped = swappedValue(values[i]);
        if (swapped == values[i] && !mapped) continue;
        if (!mapped) mapped = [values mutableCopy];
        mapped[i] = swapped;
    }
    NSArray *used = mapped ?: values;
    %orig(used);
}
%end

static void refreshRetainedAccents(void) {
    if(!NSThread.isMainThread) {dispatch_async(dispatch_get_main_queue(),^{refreshRetainedAccents();});return;}
    NSArray *owners; @synchronized(accentLock) {owners=accentOwners.allObjects;}
    [CATransaction begin];[CATransaction setDisableActions:YES];
    replayingAccent=YES;
    for(id owner in owners) {
        NSDictionary *sources;@synchronized(accentLock){sources=[objc_getAssociatedObject(owner,&ownersKey) copy];}
        for(NSString *property in sources) {
            @synchronized(accentLock) {
            if(objc_getAssociatedObject(owner,&ownersKey)[property]!=sources[property]) continue;
            if([property isEqual:@"image"] || [property isEqual:@"highlightedImage"] || [property hasPrefix:@"imageState:"]) {
                UIImage *image=imageFromRecipe(sources[property],owner);
                if([property hasPrefix:@"imageState:"]) [(UIButton *)owner setImage:image forState:(UIControlState)[[property substringFromIndex:11] integerValue]];
                else [owner setValue:image forKey:property];
                continue;
            }
            UIColor *source=sources[property]; BOOL fg=[property isEqual:@"tintColor"]||[property isEqual:@"textColor"]||[property hasPrefix:@"title:"];
            UIColor *mapped=mappedSource(source,fg);
            if([property hasPrefix:@"title:"]) [(UIButton *)owner setTitleColor:mapped forState:(UIControlState)[[property substringFromIndex:6] integerValue]];
            else if([property isEqual:@"layerFill"]) [(CAShapeLayer *)owner setFillColor:mapped.CGColor];
            else if([property isEqual:@"layerStroke"]) [(CAShapeLayer *)owner setStrokeColor:mapped.CGColor];
            else if([property isEqual:@"layerBackground"]) [(CALayer *)owner setBackgroundColor:mapped.CGColor];
            else [owner setValue:mapped forKey:property];
            }
        }
        if([owner isKindOfClass:UIView.class])[(UIView *)owner setNeedsDisplay];
        else if([owner isKindOfClass:CALayer.class])[(CALayer *)owner setNeedsDisplay];
    }
    replayingAccent=NO;[CATransaction commit];
}

%ctor {
    if (!SGRedesignedUI()) return;
    accentLock=[NSObject new];accentOwners=[NSHashTable weakObjectsHashTable];
    cgSources=[NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPointerPersonality valueOptions:NSPointerFunctionsStrongMemory];cgSourceOrder=[NSMutableArray new];
    sg_accent = chosen();
    %init;
    Class dynamicClass=object_getClass([UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {return UIColor.blackColor;}]);
    if(dynamicClass && class_getInstanceMethod(dynamicClass,@selector(colorWithAlphaComponent:))) { %init(SGRAccentDynamicSources, SGRTokenDynamicColor=dynamicClass); }
}
