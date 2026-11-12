#import "LockScreenFavorite.h"
#import "Core/SGPrefs.h"
#import "Core/SGFlagForce.h"

NSString *const SGLockScreenFavoriteFlag = @"ios-feature-lockscreen.like_dislike_enabled";

NSString *SGLockScreenFavoritePreferenceKey(void) {
    return [SGFlagOverridePrefix stringByAppendingString:SGLockScreenFavoriteFlag];
}

// Spotify 9.1.94's SPTLockScreenDefaultRemoteControlPolicy uses likeDislikeEnabled for
// availability/enabled and isTrackSaved for selected state. Enable that existing path:
// Spotify keeps ownership of handlers, eligible content, collection updates and failures.
// No MPRemoteCommand handler or saved-state cache is added here.
__attribute__((constructor)) static void registerFavoriteDefault(void) {
    SGRegisterFlagForcer(NO, ^id(NSString *key) {
        if (![key isEqualToString:SGLockScreenFavoriteFlag]) return nil;
        // Explicit flag overrides are resolved first by SGForcedFlagValue. SGEnabled
        // also honors Reset all settings (stock mode), where unset features stay off.
        return SGEnabled(SGLockScreenFavoritePreferenceKey()) ? @YES : nil;
    }, nil);
    // This is a default, not a locked flag: the dedicated switch and All flags edit
    // the same stored override. No preferences are written merely by launching.
}
