#import "Redesigned/Kit/SGRSearchAppearance.h"
#import "Redesigned/Kit/SGRConnectionBar.h"

static void searchConnectionChecks(UIWindow *window) {
    NSInteger prior=SGInt(SGRKeyAppearance,SGRAppearanceSystem);
    for (NSNumber *initial in @[@0,@1]) {
        SGRAppearanceApplyMode(initial.integerValue,NO);
        UIViewController *header=[UIViewController new];header.view=[[UIView alloc]initWithFrame:CGRectMake(0,50,380,150)];
        header.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
        [window.rootViewController addChildViewController:header];[window.rootViewController.view addSubview:header.view];
        header.view.backgroundColor=initial.boolValue?UIColor.whiteColor:[UIColor colorWithWhite:18./255 alpha:1];
        UIBlurEffect *native=[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *fieldPlate=[[UIVisualEffectView alloc]initWithEffect:native];fieldPlate.frame=CGRectMake(8,8,260,42);fieldPlate.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
        fieldPlate.layer.cornerRadius=21;fieldPlate.clipsToBounds=YES;[header.view addSubview:fieldPlate];
        UITextField *input=[[UITextField alloc]initWithFrame:CGRectMake(12,2,230,38)];input.text=@"linger";input.placeholder=@"What do you want to listen to?";
        input.textColor=initial.boolValue?UIColor.blackColor:UIColor.whiteColor;input.keyboardAppearance=UIKeyboardAppearanceDark;
        NSObject *delegate=[NSObject new];input.delegate=(id)delegate;[fieldPlate.contentView addSubview:input];
        UITextRange *selection=[input textRangeFromPosition:[input positionFromPosition:input.beginningOfDocument offset:1] toPosition:[input positionFromPosition:input.beginningOfDocument offset:4]];input.selectedTextRange=selection;
        UIVisualEffectView *cancel=[[UIVisualEffectView alloc]initWithEffect:native];cancel.frame=CGRectMake(278,8,94,42);cancel.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;cancel.layer.cornerRadius=21;cancel.clipsToBounds=YES;[header.view addSubview:cancel];
        UIButton *cancelButton=[UIButton buttonWithType:UIButtonTypeSystem];cancelButton.frame=cancel.bounds;[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];[cancelButton setTitleColor:initial.boolValue?UIColor.blackColor:UIColor.whiteColor forState:UIControlStateNormal];[cancel.contentView addSubview:cancelButton];
        SGRControlTapProbe *tap=[SGRControlTapProbe new];[cancelButton addTarget:tap action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        UIVisualEffectView *chip=[[UIVisualEffectView alloc]initWithEffect:native];chip.frame=CGRectMake(8,68,100,36);chip.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;chip.layer.cornerRadius=18;chip.clipsToBounds=YES;[header.view addSubview:chip];
        UILabel *label=[[UILabel alloc]initWithFrame:chip.bounds];label.text=@"Songs";label.textAlignment=NSTextAlignmentCenter;label.textColor=initial.boolValue?UIColor.blackColor:UIColor.whiteColor;[chip.contentView addSubview:label];
        UIImage *art=glyphImage(UIColor.cyanColor);UIImageView *image=[[UIImageView alloc]initWithImage:art];image.frame=CGRectMake(140,65,36,36);[header.view addSubview:image];
        UIView *media=[UIView new];media.accessibilityIdentifier=@"Encore.ImageView";[header.view addSubview:media];
        UIVisualEffectView *mediaEffect=[[UIVisualEffectView alloc]initWithEffect:native];mediaEffect.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;[media addSubview:mediaEffect];
        SGRApplySearchAppearance(header);
        expect(input.delegate==(id)delegate && [input.text isEqual:@"linger"] && [input.placeholder hasPrefix:@"What"],@"search preserves native input, delegate, query and placeholder");
        expect([input offsetFromPosition:input.beginningOfDocument toPosition:input.selectedTextRange.start]==1 && [input offsetFromPosition:input.beginningOfDocument toPosition:input.selectedTextRange.end]==4,@"search appearance preserves input selection");
        for (NSUInteger step=0;step<8;step++) {
            BOOL light=step%2;
            expect(SGRAppearanceApplyMode(light?SGRAppearanceLight:SGRAppearanceDark,NO),@"retained search changes live");
            [header.view layoutIfNeeded];[fieldPlate layoutIfNeeded];[cancel layoutIfNeeded];[chip layoutIfNeeded];
            UIColor *paper=light?[UIColor colorWithWhite:.92 alpha:1]:[UIColor colorWithWhite:.18 alpha:1];
            expect(contrast(input.textColor,paper)>7 && contrast(label.textColor,paper)>7 && contrast(cancelButton.titleLabel.textColor,paper)>7,@"search query, Cancel and chip maintain contrast in both modes");
            expect(fieldPlate.overrideUserInterfaceStyle==(light?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark) && chip.overrideUserInterfaceStyle==fieldPlate.overrideUserInterfaceStyle,@"search field and category effect traits stay coherent");
            expect(light?(fieldPlate.effect!=native && chip.effect!=native):(fieldPlate.effect==native && chip.effect==native),@"search Light adapts explicit blur; Dark restores exact native effect");
            expect(mediaEffect.effect==native && mediaEffect.overrideUserInterfaceStyle==UIUserInterfaceStyleDark,@"artwork effect boundary remains untouched by search styling");
            expect(image.image==art,@"search effect work never changes result artwork pixels");
            [cancelButton sendActionsForControlEvents:UIControlEventTouchUpInside];expect(tap.taps==step+1,@"Cancel continues delivering native target action once");
            if (step==0 || step==1) {
                UIImage *render=controlRender(header.view);
                UIColor *fill=controlPixel(render,CGPointMake(20,79));
                expect(controlInkPixels(render,CGRectMake(10,70,96,32),fill)>40,@"rendered category text has visible contrasting ink");
                NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"search-initial-%@-%@.png",initial,light?@"light":@"dark"]];[UIImagePNGRepresentation(render)writeToFile:path atomically:YES];
            }
        }
        UIColor *latest=[UIColor colorWithWhite:.37 alpha:1];input.textColor=latest;input.keyboardAppearance=UIKeyboardAppearanceDefault;
        UIBlurEffect *latestEffect=[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];fieldPlate.effect=latestEffect;
        fieldPlate.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
        expect(fieldPlate.overrideUserInterfaceStyle==UIUserInterfaceStyleLight && fieldPlate.effect!=latestEffect,@"late native search effect and forced-dark assignment stay scoped");
        UIView *outside=[UIView new];[outside addSubview:fieldPlate];
        expect(fieldPlate.effect==latestEffect && fieldPlate.overrideUserInterfaceStyle==UIUserInterfaceStyleDark,@"search effect restores latest native source and style on scope exit");
        expect(same(input.textColor,latest) && input.keyboardAppearance==UIKeyboardAppearanceDefault,@"input restores latest native ink and keyboard policy on scope exit");
        SGRAppearanceApplyMode(SGRAppearanceDark,NO);SGRAppearanceApplyMode(SGRAppearanceLight,NO);
        expect(fieldPlate.effect==latestEffect && same(input.textColor,latest),@"exited search nodes no longer follow retained appearance callbacks");
        [header.view addSubview:fieldPlate];expect(fieldPlate.effect!=latestEffect && same(input.textColor,SGRPrimary()),@"native search controls can reenter the header after reuse");
        UIView *group=[UIView new];[header.view addSubview:group];[group addSubview:fieldPlate];[outside addSubview:group];
        expect(fieldPlate.effect==latestEffect && same(input.textColor,latest),@"moving an ancestor out restores all nested search appearance nodes");
        [header.view removeFromSuperview];[header removeFromParentViewController];
    }
    NSUInteger geometry=0;
    for (NSNumber *width in @[@320,@466,@744,@1000]) for (NSNumber *rtl in @[@NO,@YES]) for (NSNumber *leftRail in @[@NO,@YES]) {
        UIView *host=[[UIView alloc]initWithFrame:CGRectMake(0,0,width.doubleValue,700)];
        UIView *bar=[[UIView alloc]initWithFrame:CGRectMake(0,640,width.doubleValue,60)];[host addSubview:bar];bar.backgroundColor=UIColor.blackColor;
        bar.semanticContentAttribute=rtl.boolValue?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;
        UIView *container=[UIView new];container.translatesAutoresizingMaskIntoConstraints=NO;container.accessibilityIdentifier=@"LimitedExperienceIndicatorBar.BackgroundContainer";[bar addSubview:container];
        NSLayoutConstraint *leading=[container.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor],*trailing=[container.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor];
        [NSLayoutConstraint activateConstraints:@[leading,trailing,[container.topAnchor constraintEqualToAnchor:bar.topAnchor constant:4],[container.bottomAnchor constraintEqualToAnchor:bar.bottomAnchor]]];
        UILabel *label=[UILabel new];label.text=@"Slow connection";label.textAlignment=NSTextAlignmentCenter;label.translatesAutoresizingMaskIntoConstraints=NO;[container addSubview:label];
        [NSLayoutConstraint activateConstraints:@[[label.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:8],[label.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-8],[label.topAnchor constraintEqualToAnchor:container.topAnchor constant:4]]];
        CGRect nativeFrame=bar.frame;
        for (NSUInteger i=0;i<10;i++) {
            CGFloat w=width.doubleValue-(i%2)*16;bar.frame=CGRectMake(0,640,w,60);
            CGRect rail=CGRectMake(leftRail.boolValue?8:w-60,-460,52,520);
            SGRLayoutConnectionBarInRail(bar,rail);[bar layoutIfNeeded];
            CGRect lane=SGRConnectionBarContentLane(bar.bounds,rail);
            expect(CGRectGetWidth(container.frame)>180 && CGRectGetMinX(container.frame)>=CGRectGetMinX(lane)-.01 && CGRectGetMaxX(container.frame)<=CGRectGetMaxX(lane)+.01,@"native connection content reflows wholly inside content lane for both rail edges and RTL");
            expect(!CGRectIntersectsRect(container.frame,rail) && !CGRectIntersectsRect([label convertRect:label.bounds toView:bar],rail),@"connection background and native text cannot cover the rail");
            expect(CGRectGetMinY(bar.frame)==CGRectGetMinY(nativeFrame) && CGRectGetHeight(bar.frame)==CGRectGetHeight(nativeFrame),@"connection reflow preserves native Y, height and bottom reservation");geometry++;
        }
        leading.constant=3;trailing.constant=-5;SGRLayoutConnectionBarInRail(bar,CGRectMake(8,-460,52,520));
        SGRLayoutConnectionBarInRail(bar,CGRectNull);[bar layoutIfNeeded];
        expect(leading.constant==3 && trailing.constant==-5 && same(bar.backgroundColor,UIColor.blackColor),@"leaving vertical mode restores latest native constraints and backing");
        SGRLayoutConnectionBarInRail(bar,CGRectMake(8,-460,52,520));[bar removeFromSuperview];SGRLayoutConnectionBarInRail(bar,CGRectMake(8,-460,52,520));
        expect(leading.constant==3 && trailing.constant==-5,@"detached connection bar releases its scoped horizontal adjustments");
    }
    expect(CGRectEqualToRect(SGRConnectionBarContentLane(CGRectMake(0,0,466,44),CGRectMake(600,0,52,600)),CGRectMake(0,0,466,44)),@"offscreen rail does not narrow a translated message bar");
    expect(CGRectEqualToRect(SGRConnectionBarContentLane(CGRectMake(0,0,466,0),CGRectMake(406,0,52,600)),CGRectMake(0,0,466,0)),@"hidden zero-height band retains native layout");
    for (NSNumber *rtl in @[@NO,@YES]) {
        UIView *host=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,100)];
        UIView *bar=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,44)];bar.backgroundColor=UIColor.blackColor;[host addSubview:bar];
        bar.semanticContentAttribute=rtl.boolValue?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;
        UIView *container=[UIView new];container.translatesAutoresizingMaskIntoConstraints=NO;container.accessibilityIdentifier=@"LimitedExperienceIndicatorBar.BackgroundContainer";[bar addSubview:container];
        NSLayoutConstraint *leading=[container.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor],*trailing=[container.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor];
        [NSLayoutConstraint activateConstraints:@[leading,trailing,[container.topAnchor constraintEqualToAnchor:bar.topAnchor],[container.bottomAnchor constraintEqualToAnchor:bar.bottomAnchor]]];
        SGRLayoutConnectionBarInRail(bar,CGRectMake(260,-500,52,540));
        bar.bounds=CGRectMake(0,0,40,44);CGRect collapsed=CGRectMake(8,-500,52,540);
        expect(CGRectEqualToRect(SGRConnectionBarContentLane(bar.bounds,collapsed),bar.bounds),@"collapsed connection lane falls back to native bounds");
        SGRLayoutConnectionBarInRail(bar,collapsed);[bar layoutIfNeeded];
        expect(leading.constant==0 && trailing.constant==0 && same(bar.backgroundColor,UIColor.blackColor) && CGRectGetWidth(container.frame)>=0,@"collapsed lane restores native constraints/backing without negative width in either direction");
        bar.bounds=CGRectMake(0,0,320,44);leading.constant=rtl.boolValue?5:260;trailing.constant=rtl.boolValue?-260:-5;
        CGFloat nativeLeading=leading.constant,nativeTrailing=trailing.constant;
        SGRLayoutConnectionBarInRail(bar,CGRectMake(260,-500,52,540));
        expect(leading.constant==nativeLeading && trailing.constant==nativeTrailing && same(bar.backgroundColor,UIColor.blackColor),@"native insets too large for narrowed lane remain untouched");
        expect(CGRectEqualToRect(SGRConnectionBarContentLane(bar.bounds,CGRectMake(NAN,0,52,44)),bar.bounds) && CGRectEqualToRect(SGRConnectionBarContentLane(bar.bounds,CGRectInfinite),bar.bounds),@"non-finite native rail region fails closed");
    }
    for (NSNumber *mode in @[@0,@1]) {
        SGRAppearanceApplyMode(mode.integerValue,NO);BOOL light=mode.boolValue;
        UIView *scene=[[UIView alloc]initWithFrame:CGRectMake(0,100,380,280)];scene.backgroundColor=light?UIColor.whiteColor:UIColor.blackColor;
        [window.rootViewController.view addSubview:scene];
        CGRect railFrame=CGRectMake(320,10,52,262);
        UIView *rail=[[UIView alloc]initWithFrame:railFrame];rail.backgroundColor=light?[UIColor colorWithWhite:.88 alpha:1]:[UIColor colorWithWhite:.18 alpha:1];rail.layer.cornerRadius=26;[scene addSubview:rail];
        for (NSUInteger index=0;index<3;index++) {
            UIImageView *icon=[[UIImageView alloc]initWithImage:[UIImage systemImageNamed:@[@"house.fill",@"magnifyingglass",@"books.vertical"][index]]];icon.tintColor=light?UIColor.blackColor:UIColor.whiteColor;icon.contentMode=UIViewContentModeScaleAspectFit;icon.frame=CGRectMake(13,26+index*76,26,26);[rail addSubview:icon];
        }
        UIView *player=[[UIView alloc]initWithFrame:CGRectMake(8,170,304,52)];player.layer.cornerRadius=26;player.backgroundColor=rail.backgroundColor;[scene addSubview:player];
        UILabel *song=[[UILabel alloc]initWithFrame:CGRectInset(player.bounds,16,0)];song.text=@"bad habits. · bren.";song.textColor=light?UIColor.blackColor:UIColor.whiteColor;[player addSubview:song];
        UIView *bar=[[UIView alloc]initWithFrame:CGRectMake(0,230,380,50)];bar.backgroundColor=scene.backgroundColor;[scene addSubview:bar];
        UIView *container=[UIView new];container.backgroundColor=scene.backgroundColor;container.translatesAutoresizingMaskIntoConstraints=NO;container.accessibilityIdentifier=@"LimitedExperienceIndicatorBar.BackgroundContainer";[bar addSubview:container];
        [NSLayoutConstraint activateConstraints:@[[container.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor],[container.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor],[container.topAnchor constraintEqualToAnchor:bar.topAnchor],[container.bottomAnchor constraintEqualToAnchor:bar.bottomAnchor]]];
        UILabel *status=[UILabel new];status.translatesAutoresizingMaskIntoConstraints=NO;status.text=@"Slow connection";status.font=[UIFont systemFontOfSize:14];status.textColor=song.textColor;status.textAlignment=NSTextAlignmentCenter;[container addSubview:status];
        [NSLayoutConstraint activateConstraints:@[[status.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:8],[status.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-8],[status.topAnchor constraintEqualToAnchor:container.topAnchor constant:4]]];
        SGRLayoutConnectionBarInRail(bar,[bar convertRect:rail.bounds fromView:rail]);[scene layoutIfNeeded];
        UIImage *render=controlRender(scene);UIColor *railPixel=controlPixel(render,CGPointMake(328,244));
        expect(same(railPixel,rail.backgroundColor),@"rendered connection band leaves lower rail visible in both appearances");
        expect(controlInkPixels(render,CGRectMake(48,232,220,24),scene.backgroundColor)>50,@"rendered native connection status stays readable in its content lane");
        NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"connection-layout-%@.png",light?@"light":@"dark"]];[UIImagePNGRepresentation(render)writeToFile:path atomically:YES];[scene removeFromSuperview];
    }
    NSLog(@"SEARCH CONNECTION: %lu reflow geometries",(unsigned long)geometry);
    SGRAppearanceApplyMode(prior,NO);
}
