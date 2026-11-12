// The player's settings that do not depend on the look: the lock screen widget's flags.
#import "Core/SGCore.h"
#import "Settings/SGModPage.h"
#import "PlayerSettings.h"
#import "Shared/LockScreenFavorite/LockScreenFavorite.h"

UIViewController *SGLockScreenWidgetPage(void) {
    // A regular switch writes an explicit YES/NO to the existing override key. A
    // flag row would remove the override on Off and fall back to our On default.
    SGModRow *favorite = SGSwitchRow(@"Favorite button", @"Save songs from the Lock Screen", SGLockScreenFavoritePreferenceKey());
    favorite.info = @"Uses Spotify's native favorite control and saved-song state. iOS chooses the icon and placement. Spotify's shared setting also enables its dislike control where supported. Auto uses the On default unless you reset all settings; existing On/Off choices are preserved. Changes apply after restarting Spotify.";
    return [[SGModPage alloc] initWithTitle:@"Lock screen widget" intro:SGRestartNote sections:@[
        SGSection(@"Controls", @[
            favorite,
            SGFlagRow(@"Skip button on podcasts", @"ios-feature-lockscreen.skip_button_on_podcasts"),
            SGFlagRow(@"Chapter skip controls", @"ios-feature-lockscreen.enable_chapter_skip_controls"),
            SGFlagRow(@"Burst skip", @"ios-feature-lockscreen.burst_skip_enabled"),
        ]),
        SGSection(@"Artwork", @[
            SGFlagRow(@"Animated artwork", @"ios-feature-lockscreen.animated_artwork_enabled"),
            SGFlagRow(@"Video artwork", @"ios-feature-lockscreen.vit_artwork_enabled"),
            SGFlagRow(@"Companion content", @"ios-feature-lockscreen.companion_content_enabled"),
        ]),
    ] footer:nil];
}
