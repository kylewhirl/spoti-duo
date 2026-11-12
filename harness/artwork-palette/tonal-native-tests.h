static void tonalNativeChecks(void) {
    for (NSNumber *isLight in @[@NO,@YES]) {
        BOOL light=isLight.boolValue;
        SGSetInt(SGRKeyAppearance,SGRAppearanceArtwork);
        SGConfigureRedesignAppearance(light?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark);
        expect(SGRSetArtworkTonalPalette(UIColor.redColor,YES),@"new tonal seed reports change");
        expect(!SGRSetArtworkTonalPalette(UIColor.redColor,YES),@"same tonal seed no change");
        for(NSInteger role=SGRArtworkRoleBase;role<=SGRArtworkRoleSelected;role++) expect(fabs(CGColorGetAlpha(SGRArtworkRoleColor(role,light).CGColor)-1)<.001,@"tonal roles opaque");
        UIView *owned=[[UIView alloc]initWithFrame:CGRectMake(0,0,40,40)];[UIApplication.sharedApplication.windows.firstObject addSubview:owned];SGRegisterAppearanceView(owned);owned.backgroundColor=SGRNeutralField();
        UIColor *ownedBefore=[UIColor colorWithCGColor:owned.layer.backgroundColor];
        UIView *root=[[UIView alloc]initWithFrame:CGRectMake(0,0,390,300)];SGRApplyNativeLightSurface(root,YES);
        UIView *card=[[UIView alloc]initWithFrame:CGRectMake(16,20,358,230)];card.backgroundColor=[UIColor colorWithWhite:31/255.0 alpha:1];[root addSubview:card];
        NSMutableArray *labels=[NSMutableArray new];
        NSArray *sources=@[UIColor.whiteColor,[UIColor colorWithWhite:179/255.0 alpha:1],[UIColor colorWithWhite:153/255.0 alpha:1]];
        for(NSUInteger i=0;i<3;i++) {UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(16,15+i*48,320,44)];label.text=@[@"Primary title",@"Secondary description",@"Tertiary metadata"][i];label.textColor=sources[i];[card addSubview:label];[labels addObject:label];}
        UIView *media=[UIView new];media.accessibilityIdentifier=@"Encore.ImageView";[root addSubview:media];UILabel *overlay=[UILabel new];overlay.textColor=UIColor.whiteColor;[media addSubview:overlay];
        UIColor *prior=root.backgroundColor;
        UIImage *before=controlRender(root);
        NSString *redDir=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
        [UIImagePNGRepresentation(before) writeToFile:[redDir stringByAppendingPathComponent:light?@"tonal-native-red-light.png":@"tonal-native-red-dark.png"] atomically:YES];
        SGRSetArtworkTonalPalette(UIColor.blueColor,YES);SGInvalidateAppearanceColors();SGRefreshAppearanceOwners();SGRRefreshNativeSurfaces();
        [owned setNeedsLayout];[owned layoutIfNeeded];[CATransaction flush];
        expect(!same(ownedBefore,[UIColor colorWithCGColor:owned.layer.backgroundColor]),@"same-theme retained owned dynamic layer changes hue");
        expect(same([SGRNeutralField() resolvedColorWithTraitCollection:root.traitCollection],SGRArtworkRoleColor(SGRArtworkRoleBase,light)),@"resolved field equals tonal role");
        expect(!same(prior,root.backgroundColor),@"same-theme native base changes hue");
        expect(![UIImagePNGRepresentation(before) isEqual:UIImagePNGRepresentation(controlRender(root))],@"same retained native pixels change hue");
        expect(same(card.backgroundColor,SGRArtworkRoleColor(SGRArtworkRoleElevated,light)),@"native elevated maps despite matching source style");
        for(UILabel *label in labels) expect(contrast(label.textColor,card.backgroundColor)>=4.5,@"native tonal text contrast on elevated");
        expect(same(overlay.textColor,UIColor.whiteColor),@"tonal mode preserves media overlay");
        UILabel *alpha=[UILabel new];[card addSubview:alpha];alpha.textColor=[UIColor colorWithWhite:1 alpha:.5];expect(fabs(CGColorGetAlpha(alpha.textColor.CGColor)-.5)<.001,@"native tonal source alpha preserved once");
        NSString *dir=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
        [UIImagePNGRepresentation(controlRender(root)) writeToFile:[dir stringByAppendingPathComponent:light?@"tonal-native-light.png":@"tonal-native-dark.png"] atomically:YES];
        SGRSetArtworkTonalPalette(nil,NO);SGSetInt(SGRKeyAppearance,light?SGRAppearanceLight:SGRAppearanceDark);SGInvalidateAppearanceColors();SGRefreshAppearanceOwners();SGRRefreshNativeSurfaces();
        expect(same(card.backgroundColor,light?[UIColor colorWithWhite:.92 alpha:1]:[UIColor colorWithWhite:31/255.0 alpha:1]),@"fixed mode restores original elevated behavior");
        expect(same(((UILabel *)labels[0]).textColor,light?[UIColor colorWithWhite:.08 alpha:1]:UIColor.whiteColor),@"fixed mode restores primary behavior");
    }
    SGRAppearanceApplyMode(SGRAppearanceLight,NO); // resynchronize native providers after direct Core-style unit cases
    extern UIImage *fixtureArt;extern NSString *fixtureIdentity;
    fixtureArt=[UIImage systemImageNamed:@"music.note"];fixtureIdentity=@"tonal-highlevel";SGSetInt(SGRKeyAppearance,SGRAppearanceArtwork);SGRAppearanceArtworkDidChange();NSUInteger generation=SGRAppearanceArtworkGeneration();
    SGRPalette *p=[SGRPalette new];[p setValue:@(.01) forKey:@"artworkLuminance"];[p setValue:UIColor.redColor forKey:@"rawDominantColor"];
    SGRAppearanceAcceptArtworkPalette(p,fixtureIdentity,generation);SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
    UIView *live=[UIView new];SGRApplyNativeLightSurface(live,YES);UIColor *red=live.backgroundColor;
    [p setValue:UIColor.blueColor forKey:@"rawDominantColor"];SGRAppearanceAcceptArtworkPalette(p,fixtureIdentity,generation);SGRAppearanceApplyMode(SGRAppearanceArtwork,NO);
    NSLog(@"HIGHLEVEL red=%@ blue=%@ active=%d light=%d status=%@ gen=%lu",red,live.backgroundColor,SGRArtworkTonalActive(),SGRedesignLightAppearance(),SGRAppearanceStatus(),(unsigned long)generation);
    expect(!SGRedesignLightAppearance()&&!same(red,live.backgroundColor),@"actual ApplyMode sameDark commit refreshes retained native hue");
    NSLog(@"TONAL NATIVE FINAL %d checks %d failures",checks,failures);
}
