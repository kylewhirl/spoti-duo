#import "Redesigned/Kit/SGRHeaderInfo.h"
#import "Redesigned/Kit/SGRRepaint.h"
@interface SGRControlTapProbe : NSObject
@property(nonatomic) NSUInteger taps;
- (void)tapped;
@end
@implementation SGRControlTapProbe
- (void)tapped { self.taps++; }
@end
static UIImage *controlRender(UIView *view) {
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat new];format.scale=2;format.opaque=NO;
    return [[[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size format:format] imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    }];
}
static UIColor *controlPixel(UIImage *image,CGPoint point) {
    size_t w=CGImageGetWidth(image.CGImage),h=CGImageGetHeight(image.CGImage);
    unsigned char *bytes=calloc(w*h,4);CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx=CGBitmapContextCreate(bytes,w,h,8,w*4,space,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGContextDrawImage(ctx,CGRectMake(0,0,w,h),image.CGImage);
    size_t x=MIN(w-1,(size_t)(point.x*image.scale)),y=MIN(h-1,(size_t)(point.y*image.scale));
    unsigned char *p=bytes+(y*w+x)*4;
    UIColor *result=[UIColor colorWithRed:p[0]/255. green:p[1]/255. blue:p[2]/255. alpha:p[3]/255.];
    CGContextRelease(ctx);CGColorSpaceRelease(space);free(bytes);return result;
}
static NSUInteger controlInkPixels(UIImage *image,CGRect rect,UIColor *paper) {
    size_t w=CGImageGetWidth(image.CGImage),h=CGImageGetHeight(image.CGImage);
    unsigned char *bytes=calloc(w*h,4);CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx=CGBitmapContextCreate(bytes,w,h,8,w*4,space,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGContextDrawImage(ctx,CGRectMake(0,0,w,h),image.CGImage);NSUInteger count=0;
    for(size_t y=MAX(0,CGRectGetMinY(rect)*image.scale);y<MIN(h,CGRectGetMaxY(rect)*image.scale);y++)
        for(size_t x=MAX(0,CGRectGetMinX(rect)*image.scale);x<MIN(w,CGRectGetMaxX(rect)*image.scale);x++) {
            unsigned char *p=bytes+(y*w+x)*4;
            UIColor *c=[UIColor colorWithRed:p[0]/255. green:p[1]/255. blue:p[2]/255. alpha:p[3]/255.];
            if(contrast(c,paper)>=4.5)count++;
        }
    CGContextRelease(ctx);CGColorSpaceRelease(space);free(bytes);return count;
}
static void controlRenderingChecks(UIWindow *window) {
    UIUserInterfaceStyle saved=SGRedesignAppearanceStyle();UIView *previousRoot=sgr_playlistRoot;
    for(NSNumber *initial in @[@1,@2]) {
        SGConfigureRedesignAppearance(initial.integerValue);SGRefreshAppearanceOwners();
        UIView *page=[[UIView alloc] initWithFrame:window.rootViewController.view.bounds];
        SGRegisterAppearanceView(page);[window.rootViewController.view addSubview:page];sgr_playlistRoot=page;
        SGRArtworkField *field=[[SGRArtworkField alloc] initWithFrame:page.bounds];
        [page addSubview:field];[field setProvisionalColor:[UIColor colorWithRed:.1 green:.24 blue:.3 alpha:1]];
        SGRHeaderInfo *header=[[SGRHeaderInfo alloc] initWithFrame:CGRectMake(0,100,page.bounds.size.width,160)];
        [page addSubview:header];[header showTitle:@"Production playlist controls" creator:nil length:nil about:nil];
        UIButton *native=[[UIButton alloc] initWithFrame:CGRectMake(0,0,48,48)];
        native.accessibilityLabel=@"Play";
        UIImageView *imageView=[[UIImageView alloc] initWithFrame:native.bounds];
        imageView.image=[UIImage systemImageNamed:@"play.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular]];
        [native addSubview:imageView];
        SGRControlTapProbe *tap=[SGRControlTapProbe new];[native addTarget:tap action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        // Identical production header wiring to PlaylistHeader: native source plus visible artwork field.
        [header showShuffle:nil play:native trailing:nil trailingFallback:nil playColor:field.fieldColor];
        SGRPlayCapsule *capsule=[header valueForKey:@"play"];
        CGRect initialFrame=CGRectZero;UIImage *source=imageView.image;
        for(NSUInteger i=0;i<12;i++) {
            BOOL light=(i%2)==0;
            SGConfigureRedesignAppearance(light?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark);SGRefreshAppearanceOwners();
            [page updateTraitsIfNeeded];[header setNeedsLayout];[page layoutIfNeeded];[capsule setNeedsLayout];[capsule layoutIfNeeded];[CATransaction flush];
            if(i==0)initialFrame=capsule.frame;
            expect(CGRectEqualToRect(capsule.frame,initialFrame),@"production capsule appearance preserves geometry");
            expect(imageView.image==source && capsule.source==native,@"production capsule keeps native source glyph and action owner");
            UIImage *render=controlRender(page);
            CGRect region=[capsule convertRect:capsule.bounds toView:page];
            UIColor *fill=controlPixel(render,CGPointMake(CGRectGetMidX(region),CGRectGetMinY(region)+5));
            expect(luminance(fill,UIColor.whiteColor)>.98,@"actual rendered production capsule retains its opaque white fill through repaint");
            CGRect glyph=CGRectInset([[capsule valueForKey:@"glyph"] convertRect:[[capsule valueForKey:@"glyph"] bounds] toView:page],8,7);
            CGRect title=[[capsule valueForKey:@"title"] convertRect:[[capsule valueForKey:@"title"] bounds] toView:page];
            expect(controlInkPixels(render,glyph,fill)>30,@"actual production capsule glyph has at least 4.5:1 rendered contrast");
            expect(controlInkPixels(render,title,fill)>60,@"actual production capsule title has at least 4.5:1 rendered contrast");
            if(!light) {
                UIColor *ink=[[capsule valueForKey:@"title"] textColor];
                expect(CGColorEqualToColor([ink resolvedColorWithTraitCollection:capsule.traitCollection].CGColor,field.fieldColor.CGColor),@"Dark capsule restores exact current artwork ink");
            }
            if(i<2) {
                NSString *name=[NSString stringWithFormat:@"capsule-created-%@-rendered-%@.png",initial,light?@"light":@"dark"];
                NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:name];
                [UIImagePNGRepresentation(render) writeToFile:path atomically:YES];
            }
        }
        [capsule sendActionsForControlEvents:UIControlEventTouchUpInside];
        expect(tap.taps==1,@"production capsule dispatches exactly one native play action");
        native.accessibilityLabel=@"Pause";imageView.image=[UIImage systemImageNamed:@"pause.fill"];
        expect([capsule.accessibilityLabel isEqual:@"Pause"],@"native play-to-pause image update keeps native title and state");
        SGConfigureRedesignAppearance(UIUserInterfaceStyleLight);SGRefreshAppearanceOwners();
        [page updateTraitsIfNeeded];[page layoutIfNeeded];[capsule layoutIfNeeded];[CATransaction flush];
        UIImage *pause=controlRender(page);CGRect region=[capsule convertRect:capsule.bounds toView:page];
        UIColor *paper=controlPixel(pause,CGPointMake(CGRectGetMidX(region),CGRectGetMinY(region)+5));
        CGRect glyph=[[capsule valueForKey:@"glyph"] convertRect:[[capsule valueForKey:@"glyph"] bounds] toView:page];
        CGRect title=[[capsule valueForKey:@"title"] convertRect:[[capsule valueForKey:@"title"] bounds] toView:page];
        expect(controlInkPixels(pause,glyph,paper)>30 && controlInkPixels(pause,title,paper)>60,@"native Pause glyph and title render with readable contrast after state change");
        NSString *pausePath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"capsule-created-%@-pause-light.png",initial]];
        [UIImagePNGRepresentation(pause) writeToFile:pausePath atomically:YES];
        [page removeFromSuperview];
    }
    sgr_playlistRoot=previousRoot;SGConfigureRedesignAppearance(saved);SGRefreshAppearanceOwners();
}
