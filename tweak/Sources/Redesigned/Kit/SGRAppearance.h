#import <UIKit/UIKit.h>

static NSString *const SGRKeyArtworkPalette = @"spotifyglass.redesign.palette.artwork";
static NSString *const SGRKeyAppearance = @"spotifyglass.redesign.appearance";
typedef NS_ENUM(NSInteger, SGRAppearanceMode) {
    SGRAppearanceDark = 0,
    SGRAppearanceLight = 1,
    SGRAppearanceSystem = 2,
    SGRAppearanceArtwork = 3,
};
BOOL SGRAppearanceBridgeAvailable(void);
BOOL SGRAppearanceNeedsRestart(void); // compatibility: indicates an unapplied selection
NSString *SGRAppearanceStatus(void);
// Main-thread transaction used by the picker and system observer. Stores verify before any
// rendered appearance changes. The request form coalesces rapid preference/scene changes.
BOOL SGRAppearanceApplyMode(NSInteger mode, BOOL animated);
void SGRAppearanceApplyPreference(void);

static NSString *const SGRKeyPlayerArtworkAppearance = @"spotifyglass.redesign.player.artworkAppearance";
void SGRPlayerApplyAppearancePreference(void);

@class SGRPalette;
void SGRAppearanceArtworkDidChange(void);
NSUInteger SGRAppearanceArtworkGeneration(void);
void SGRAppearanceAcceptArtworkPalette(SGRPalette *palette, NSString *identity, NSUInteger generation);
