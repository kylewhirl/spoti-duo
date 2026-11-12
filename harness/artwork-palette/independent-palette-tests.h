static void independentPaletteChecks(void) {
    NSString *paletteKey=@"spotifyglass.redesign.palette.artwork";
    extern UIImage *fixtureArt;extern NSString *fixtureIdentity;
    SGSetInt(SGRKeyAccent,0x8844CC);SGSetInt(SGRKeyAccentArtwork,0);SGSetInt(paletteKey,1);
    fixtureArt=[UIImage systemImageNamed:@"music.note"];fixtureIdentity=@"independent-matrix";SGRAppearanceArtworkDidChange();NSUInteger generation=SGRAppearanceArtworkGeneration();
    SGRPalette *p=[SGRPalette new];
    for(NSNumber *mode in @[@(SGRAppearanceDark),@(SGRAppearanceLight),@(SGRAppearanceSystem)]) {
        SGSetInt(SGRKeyAppearance,mode.integerValue);
        BOOL expectedLight=mode.integerValue==SGRAppearanceLight || (mode.integerValue==SGRAppearanceSystem && UIScreen.mainScreen.traitCollection.userInterfaceStyle==UIUserInterfaceStyleLight);
        SGSetInt(paletteKey,0);SGRAppearanceApplyMode(mode.integerValue,NO);
        UIView *root=[UIView new];SGRApplyNativeLightSurface(root,YES);UIColor *prior=nil;
        UIColor *standardBaseline=[UIColor colorWithCGColor:root.layer.backgroundColor];SGSetInt(paletteKey,1);
        for(UIColor *seed in @[UIColor.redColor,UIColor.whiteColor]) {
            [p setValue:seed forKey:@"rawDominantColor"];[p setValue:@(seed==UIColor.whiteColor?.99:.01) forKey:@"artworkLuminance"];
            SGRAppearanceAcceptArtworkPalette(p,fixtureIdentity,generation);SGRAppearanceApplyMode(mode.integerValue,NO);
            expect(SGRedesignLightAppearance()==expectedLight,@"base appearance stays independent of artwork brightness");
            expect(SGRArtworkTonalActive(),@"tonal palette works with independent fixed/System appearance");
            if(prior)expect(!same(prior,root.backgroundColor),@"independent palette changes retained native base");prior=root.backgroundColor;
            expect(SGInt(SGRKeyAccent,0)==0x8844CC && same(SGRAccentColor(),[UIColor colorWithRed:0x88/255.0 green:0x44/255.0 blue:0xCC/255.0 alpha:1]),@"palette choice preserves manual accent");
        }
        SGSetInt(paletteKey,0);SGRAppearanceApplyMode(mode.integerValue,NO);expect(!SGRArtworkTonalActive(),@"Standard palette disables artwork tonal roles independently");
        NSLog(@"INDEPENDENT STANDARD mode=%@ field=%@ token=%@",mode,root.backgroundColor,SGRNeutralField());
        expect(same([UIColor colorWithCGColor:root.layer.backgroundColor],standardBaseline),@"Standard palette restores neutral base");SGSetInt(paletteKey,1);
    }
    SGSetInt(SGRKeyAppearance,SGRAppearanceDark);SGSetInt(SGRKeyAccentArtwork,1);[p setValue:UIColor.whiteColor forKey:@"rawDominantColor"];[p setValue:@(.99) forKey:@"artworkLuminance"];SGRAppearanceAcceptArtworkPalette(p,fixtureIdentity,generation);SGRAppearanceApplyMode(SGRAppearanceDark,NO);
    expect(!SGRedesignLightAppearance(),@"white cover does not override fixedDark");
    expect(same(SGRAccentColor(),UIColor.whiteColor),@"white artwork produces white native accent onDark");
    expect(contrast(SGRAccentColor(),UIColor.blackColor)>=4.5,@"white artwork native fill retains black glyph contrast");
    expect(contrast(SGRAccent(),SGRArtworkRoleColor(SGRArtworkRoleElevated,NO))>=4.5,@"white artwork foreground contrast onDark tonal surface");
    NSLog(@"INDEPENDENT PALETTE FINAL %d checks %d failures OS=%@",checks,failures,UIScreen.mainScreen.traitCollection.userInterfaceStyle==UIUserInterfaceStyleLight?@"Light":@"Dark");
}
