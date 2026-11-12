#import "Redesigned/Kit/SGRNativeGlyph.h"
@interface FixtureAddToButtonOwner:NSObject { @public uint8_t currentStatus; NSUInteger actionCount; }
- (void)performAction;
@end
@implementation FixtureAddToButtonOwner
- (void)performAction { actionCount++; }
@end
@interface FixtureStateMicroInteractionView:UIView @end
@implementation FixtureStateMicroInteractionView @end
static UIImage *glyphImage(UIColor *color) {
    return [[[UIGraphicsImageRenderer alloc]initWithSize:CGSizeMake(24,24)] imageWithActions:^(UIGraphicsImageRendererContext *ctx){[color setFill];UIRectFill(CGRectMake(4,4,16,16));}];
}
static UIColor *glyphCenter(UIImage *image) {
    size_t width=CGImageGetWidth(image.CGImage),height=CGImageGetHeight(image.CGImage);
    uint8_t *pixels=calloc(width*height,4);CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();
    CGContextRef context=CGBitmapContextCreate(pixels,width,height,8,width*4,space,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    UIGraphicsPushContext(context);[image drawInRect:CGRectMake(0,0,width,height)];UIGraphicsPopContext();
    CGContextRelease(context);CGColorSpaceRelease(space);
    uint8_t *pixel=pixels+((height/2)*width+width/2)*4;
    CGFloat a=pixel[3]/255.;UIColor *result=a?[UIColor colorWithRed:pixel[0]/(255.*a) green:pixel[1]/(255.*a) blue:pixel[2]/(255.*a) alpha:1]:UIColor.clearColor;
    free(pixels);return result;
}
static void nativeGlyphChecks(BOOL light) {
    UIView *root=[UIView new];root.backgroundColor=SGRNeutralField();SGRApplyNativeLightSurface(root,YES);
    UIView *outside=[UIView new];
    UIButton *search=[UIButton new];search.accessibilityIdentifier=@"YourLibraryHeader.search";[root addSubview:search];
    UIImage *white=glyphImage(UIColor.whiteColor),*red=glyphImage(UIColor.redColor);
    UIImageView *glyph=[[UIImageView alloc]initWithImage:white];[search addSubview:glyph];SGRRefreshNativeGlyph(glyph);
    expect(same(glyphCenter(glyph.image),light?SGRPrimary():UIColor.whiteColor),@"known UIImage-backed Library glyph has semantic contrast");
    UIImage *stable=glyph.image;for(NSUInteger i=0;i<100;i++)SGRRefreshNativeGlyph(glyph);
    expect(glyph.image==stable,@"repeated native glyph refresh reuses emitted image rather than processing each frame");
    glyph.image=red;SGRRefreshNativeGlyph(glyph);
    expect(glyph.image==red,@"native active colored glyph asset is not recolored");
    UIImage *lazyCyan=[white imageWithTintColor:UIColor.cyanColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    glyph.image=lazyCyan;SGRRefreshNativeGlyph(glyph);
    expect(glyph.image==lazyCyan && same(glyphCenter(glyph.image),UIColor.cyanColor),@"lazy-tinted active glyph is recognized by UIKit drawing and preserved");
    glyph.image=white;[outside addSubview:search];SGRRefreshNativeGlyph(glyph);
    expect(glyph.image==white,@"moving known image control outside restores exact source UIImage");
    [root addSubview:search];SGRRefreshNativeGlyph(glyph);
    glyph.highlightedImage=white;
    expect(same(glyphCenter(glyph.highlightedImage),light?SGRPrimary():UIColor.whiteColor),@"highlighted source glyph gets matching appearance");
    UIView *avatar=[UIView new];avatar.accessibilityIdentifier=@"Components.UI.SideDrawerButton";[root addSubview:avatar];
    UIImageView *photo=[[UIImageView alloc]initWithImage:white];[avatar addSubview:photo];SGRRefreshNativeGlyph(photo);
    expect(photo.image==white,@"avatar original bitmap remains exact even if all white");
    UIImageView *unknown=[[UIImageView alloc]initWithImage:white];[root addSubview:unknown];SGRRefreshNativeGlyph(unknown);
    expect(unknown.image==white,@"unidentified original artwork remains exact");
    UIButton *add=[UIButton new];add.accessibilityIdentifier=@"Components.UI.AddToButton";add.bounds=CGRectZero;
    FixtureAddToButtonOwner *model=[FixtureAddToButtonOwner new];model->currentStatus=0;
    [add addTarget:model action:@selector(performAction) forControlEvents:UIControlEventTouchUpInside];
    UIView *native=[FixtureStateMicroInteractionView new];native.alpha=.8;[add addSubview:native];[root addSubview:add];SGRRefreshNativeGlyph(add);
    expect(fabs(native.alpha-(light?0:.8))<.001,@"unsaved AddTo glyph replaced only in Light with proven state");
    // Reproduce the device path: creation/refresh at zero size, native sizing later
    // with no intervening call to our refresh or layout observer.
    add.bounds=CGRectMake(0,0,44,40);
    if(light) {
        UIView *replacement=nil;for(UIView *child in add.subviews)if([child isKindOfClass:SGRGlyphView.class])replacement=child;
        expect(replacement && CGPointEqualToPoint(replacement.center,CGPointMake(22,20)),@"AddTo glyph stays centered when native bounds arrive after its bitmap");
        add.bounds=CGRectMake(0,0,52,48);
        expect(CGPointEqualToPoint(replacement.center,CGPointMake(26,24)),@"AddTo glyph follows later native bounds without waiting for layout");
    }

    // Native AddTo updates currentStatus, then calls UIButton.setSelected:. Its
    // animation may not touch CAShapeLayer or lay out the button. Do not manually
    // refresh the adapter here: that would hide the reported stale-plus regression.
    NSString *label=@"Native collection action";add.accessibilityLabel=label;
    NSArray *actions=[add actionsForTarget:model forControlEvent:UIControlEventTouchUpInside];
    model->currentStatus=1;add.selected=YES;
    expect(fabs(native.alpha-.8)<.001,@"native selected publication restores liked checkmark without layout or render callback");
    for(UIView *child in add.subviews)if([child isKindOfClass:SGRGlyphView.class])
        expect(child.alpha==0,@"liked native button has no stale replacement plus overlay");
    model->currentStatus=0;add.selected=NO;
    expect(fabs(native.alpha-(light?0:.8))<.001,@"native deselection publishes unlike state without layout or render callback");
    // A native selected state is a positive saved signal even if model observation
    // temporarily lags. Unknown model values must also fall back to native.
    model->currentStatus=0;add.selected=YES;SGRRefreshNativeGlyph(add);
    expect(fabs(native.alpha-.8)<.001,@"selected native state is never covered by model-lagging plus");
    model->currentStatus=1;add.selected=NO;
    expect(fabs(native.alpha-.8)<.001,@"model-added and selected-NO disagreement keeps native glyph");
    model->currentStatus=3;add.selected=NO;
    expect(fabs(native.alpha-.8)<.001,@"unknown model preserves native glyph instead of guessing unsaved");
    model->currentStatus=0;add.selected=NO;
    [add removeTarget:model action:@selector(performAction) forControlEvents:UIControlEventTouchUpInside];
    add.selected=NO;
    expect(fabs(native.alpha-.8)<.001,@"missing model owner restores native glyph during same-BOOL publication");
    [add addTarget:model action:@selector(performAction) forControlEvents:UIControlEventTouchUpInside];
    add.selected=NO;
    expect(fabs(native.alpha-(light?0:.8))<.001,@"same-BOOL re-publication refreshes a replacement after track/model reuse");
    expect([add.accessibilityLabel isEqual:label] && [[add actionsForTarget:model forControlEvent:UIControlEventTouchUpInside] isEqual:actions],@"appearance keeps native collection actions and accessibility label unchanged");
    [add sendActionsForControlEvents:UIControlEventTouchUpInside];
    expect(model->actionCount==1,@"collection action fires exactly once through untouched native target");
    for(NSUInteger cycle=0;cycle<12;cycle++) {
        BOOL saved=cycle%2;model->currentStatus=saved?1:0;add.selected=saved;
        expect(fabs(native.alpha-((light&&!saved)?0:.8))<.001,@"reused native AddTo button follows repeated liked/unliked publications");
    }
    model->currentStatus=0;add.selected=NO;
    UIButton *unrelated=[UIButton new];[root addSubview:unrelated];
    UIView *unrelatedNative=[FixtureStateMicroInteractionView new];unrelatedNative.alpha=.7;[unrelated addSubview:unrelatedNative];
    unrelated.selected=YES;unrelated.selected=NO;
    expect(unrelated.subviews.count==1 && fabs(unrelatedNative.alpha-.7)<.001,@"unrelated button selection is not adapted");

    CAShapeLayer *render=[CAShapeLayer layer];[native.layer addSublayer:render];
    model->currentStatus=1;render.fillColor=UIColor.cyanColor.CGColor;
    [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    expect(fabs(native.alpha-.8)<.001,@"saved native accent animation restored after render event without forced layout");
    model->currentStatus=0;render.strokeColor=UIColor.whiteColor.CGColor;
    [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    expect(fabs(native.alpha-(light?0:.8))<.001,@"unsaved glyph reacts to native render event without forced layout");
    native.alpha=.4;
    model->currentStatus=1;render.fillColor=UIColor.cyanColor.CGColor;
    [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    expect(fabs(native.alpha-.4)<.001,@"native alpha change while replaced is retained for saved animation");
    model->currentStatus=0;SGRRefreshNativeGlyph(add);[outside addSubview:add];SGRRefreshNativeGlyph(add);
    expect(fabs(native.alpha-.4)<.001,@"reused AddTo control restores native animation outside scope");
    model->currentStatus=1;add.selected=YES;model->currentStatus=0;add.selected=NO;
    expect(fabs(native.alpha-.4)<.001,@"out-of-scope selected publications leave native glyph opacity exact");
    UISlider *slider=[UISlider new];slider.accessibilityIdentifier=@"SPTNowPlayingSliderV2";slider.minimumTrackTintColor=UIColor.cyanColor;slider.maximumTrackTintColor=nil;
    UIImage *track=glyphImage(UIColor.whiteColor);[slider setMinimumTrackImage:track forState:UIControlStateNormal];
    slider.frame=CGRectMake(0,0,300,24);slider.value=.5;
    [root addSubview:slider];[slider layoutIfNeeded];SGRRefreshNativeGlyph(slider);
    __block NSUInteger adaptedTracks=0;
    SGForEachView(slider, ^(UIView *view) {
        if(![view isKindOfClass:UIImageView.class] || !((UIImageView *)view).image)return;
        SGRRefreshNativeGlyph(view);
        if(same(glyphCenter(((UIImageView *)view).image),light?[UIColor colorWithWhite:.08 alpha:1]:UIColor.whiteColor))adaptedTracks++;
    });
    expect(adaptedTracks>0,@"real UISlider track bitmap adapts without mutating tint/image state");
    expect(same(slider.minimumTrackTintColor,UIColor.cyanColor),@"native slider tint setting is untouched");
    [outside addSubview:slider];SGRRefreshNativeGlyph(slider);
    expect(same(slider.minimumTrackTintColor,UIColor.cyanColor) && slider.maximumTrackTintColor==nil,@"slider restores original native tint and nil on scope exit");
    expect([slider minimumTrackImageForState:UIControlStateNormal]==track,@"slider retains any native custom track image across appearance scope");
}
