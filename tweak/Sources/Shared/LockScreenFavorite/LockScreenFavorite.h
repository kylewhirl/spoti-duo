// The native Now Playing favorite action, owned and handled by Spotify.
#import <Foundation/Foundation.h>

extern NSString *const SGLockScreenFavoriteFlag;
// Reuses the original flag override key, so prior On/Off choices remain authoritative.
NSString *SGLockScreenFavoritePreferenceKey(void);
