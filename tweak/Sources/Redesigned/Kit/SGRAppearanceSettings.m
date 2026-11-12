#import "Core/SGCore.h"
#import "Settings/SGModPage.h"
#import "Settings/SGPageStyle.h"
#import "SGRAccent.h"
#import "SGRAppearance.h"

// Going back to Spotify's green is offered only once a colour of the mod's is set, so a stray tap
// cannot wipe it.
static void chooseAccent(void) {
    UIViewController *top = SGTopController();
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Accent colour" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Match artwork" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { SGSetInt(SGRKeyAccentArtwork,1); SGRAppearanceApplyPreference(); }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Pick a colour" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { SGRPickAccent(); }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Spotify's green" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { SGSetInt(SGRKeyAccent, -1); SGSetInt(SGRKeyAccentArtwork,0); SGRAppearanceApplyPreference(); }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = top.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(top.view.bounds), CGRectGetMidY(top.view.bounds), 0, 0);
    sheet.popoverPresentationController.permittedArrowDirections = 0;
    [top presentViewController:sheet animated:YES completion:nil];
}

// The picker persists the key before this callback. One main-queue transaction applies it.
NSArray<SGModRow *> *SGRAppearanceRows(void) {
    SGModRow *appearance = SGChoiceRow(@"Appearance", @"Change the app appearance immediately", SGRKeyAppearance,
        @[@"Dark", @"Light", @"System", @"Match artwork"], SGRAppearanceSystem);
    appearance.choiceNotes = @[@"Deep black backgrounds and light text.", @"Light backgrounds and dark text.", @"Follow the phone's appearance, including changes while Spotify is open.", @"Choose light or dark from the current artwork. Uses System when artwork is unavailable."];
    appearance.choiceFooter = @"Changes apply without restarting or interrupting playback. System follows the phone and is the default when no choice has been saved.";
    // Existing installs inherited artwork colors from Appearance. When that user changes
    // base mode, preserve the displayed color-theme choice rather than silently turning it off.
    NSInteger paletteChoice = SGInt(SGRKeyArtworkPalette,SGInt(SGRKeyAppearance,SGRAppearanceSystem)==SGRAppearanceArtwork ? 1 : 0);
    appearance.chosen = ^(NSInteger index) {
        if (SGInt(SGRKeyArtworkPalette,-1)<0) SGSetInt(SGRKeyArtworkPalette,paletteChoice);
        SGRAppearanceApplyPreference();
    };
    SGModRow *palette = SGChoiceRow(@"Color theme", @"Choose colors separately from light or dark appearance", SGRKeyArtworkPalette,
        @[@"Standard", @"Match artwork"], SGInt(SGRKeyAppearance,SGRAppearanceSystem)==SGRAppearanceArtwork ? 1 : 0);
    palette.choiceNotes = @[@"Use standard surfaces and text colors.", @"Tint backgrounds, cards and text from the current artwork without changing your Appearance choice."];
    palette.choiceFooter = @"For a consistently dark app with artwork colors, choose Dark under Appearance and Match artwork here. Accent colour is selected separately.";
    palette.chosen = ^(NSInteger index) { SGRAppearanceApplyPreference(); };
    SGModRow *player = SGChoiceRow(@"Now Playing appearance", @"Choose how the full-screen player looks", SGRKeyPlayerArtworkAppearance,
        @[@"Follow app", @"Match artwork"], 0);
    player.choiceNotes = @[@"Use the app's selected appearance, including Match artwork.", @"Dark artwork gets light controls; light artwork gets dark controls."];
    player.choiceFooter = @"Only changes Now Playing unless the app itself uses Match artwork, which takes priority.";
    player.chosen = ^(NSInteger index) { SGRPlayerApplyAppearancePreference(); };
    return @[
        SGWithSymbol(player, @"photo"),
        SGWithSymbol(appearance, @"circle.lefthalf.filled"),
        SGWithSymbol(palette, @"photo.artframe"),
        SGWithSymbol(SGStatActionRow(@"Accent colour", nil, ^NSString *{ return SGRAccentLabel(); }, ^{ chooseAccent(); }), @"paintpalette"),
    ];
}
