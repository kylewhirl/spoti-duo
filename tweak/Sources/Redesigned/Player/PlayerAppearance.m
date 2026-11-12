// Artwork-local Now Playing appearance. Never changes app preference or Spotify provider.
#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRKit.h"
#import "Player.h"
#import "Redesigned/Kit/SGRAppearance.h"
static __weak UIViewController *playerOwner;
static __weak SGRArtworkField *scopedField;
static UIUserInterfaceStyle artworkStyle=UIUserInterfaceStyleUnspecified;
static void applyPlayerStyle(void) {
    UIView *root=playerOwner.viewIfLoaded;
    // App-wide artwork mode is authoritative; avoid stale independent player scopes.
    BOOL adaptive=SGInt(SGRKeyPlayerArtworkAppearance,0)==1 && SGInt(SGRKeyAppearance,SGRAppearanceSystem)!=SGRAppearanceArtwork;
    // Spotify owns the background in a separate controller/plane. It need not be
    // below the content owner; bind both explicit roots to the same local style.
    SGRArtworkField *field=SGRPlayerField();
    if (scopedField && scopedField!=field) SGClearAppearanceScope(scopedField);
    scopedField=field;
    if (adaptive && artworkStyle!=UIUserInterfaceStyleUnspecified) SGSetAppearanceScope(field,artworkStyle);
    else SGClearAppearanceScope(field);
    [field refreshLocalAppearance];
    if (!root) return;
    if (adaptive && artworkStyle!=UIUserInterfaceStyleUnspecified) SGSetAppearanceScope(root,artworkStyle);
    else SGClearAppearanceScope(root);
    SGRegisterAppearanceController(playerOwner);
    SGRefreshAppearanceSubtree(root);
    SGRRefreshNativeSurfaceSubtree(root);
}
void SGRPlayerApplyAppearancePreference(void) { applyPlayerStyle(); }
void SGRPlayerRegisterArtworkAppearance(UIViewController *controller) {
    if (playerOwner==controller) return;
    playerOwner=controller;
    applyPlayerStyle();
}
void SGRPlayerSetArtworkLuminance(CGFloat luminance) {
    if (!isfinite(luminance)) return;
    UIUserInterfaceStyle next=luminance>=.45?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark;
    if (next==artworkStyle) return;
    artworkStyle=next;
    applyPlayerStyle();
}
