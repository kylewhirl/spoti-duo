#import "SGInstallDefaults.h"

NSDictionary<NSString *, id> *SGNewInstallDefaults(void) {
    // Explicit user-facing choices from the approved Duo configuration. Do not copy cached navbar
    // discovery, onboarding state, diagnostic counters, updates, account information or credentials.
    return @{
        @"spotipw.usage": @NO, // No original-developer usage reporting
        @"spotifyglass.redesign": @YES,
        @"spotifyglass.redesign.appearance": @2, // System
        @"spotifyglass.redesign.palette.artwork": @1,
        @"spotifyglass.redesign.accent.matchArtwork": @1,
        @"spotifyglass.redesign.accent": @116732,
        @"spotifyglass.redesign.navbar.hideLabels": @YES,
        @"spotifyglass.redesign.player.artworkAppearance": @0, // Follow app
        @"spotifyglass.redesign.player.movingBackground": @YES,
        @"spotifyglass.liveActivity": @NO,
        @"spotifyglass.liveActivity.view": @1,
        @"spotifyglass.lyricsAllTracks": @YES,
        @"spotifyglass.lyricsSimulateWords": @YES,
        @"spotifyglass.lyricsProviders": @[@"musixmatch"],
    };
}

BOOL SGSeedNewInstallDefaults(NSUserDefaults *store) {
    // Even a single legacy preference, stock-reset marker, or onboarding/cache key proves this is
    // an existing install. Leave ALL its settings (including absent values using old fallbacks) alone.
    for (NSString *key in store.dictionaryRepresentation) {
        if ([key hasPrefix:@"spotifyglass."]) return NO;
    }
    [SGNewInstallDefaults() enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        [store setObject:value forKey:key];
    }];
    return YES;
}

// Objective-C +load runs before this image's C/Logos constructors cache launch-time preferences.
// Mach-O does not honor ELF constructor priorities. This is not registerDefaults:
// direct objectForKey readers and migrations need the same explicit first-install choices.
#ifndef SG_INSTALL_DEFAULTS_TEST
@interface SGInstallDefaultConfiguration : NSObject
@end
@implementation SGInstallDefaultConfiguration
+ (void)load {
    @autoreleasepool { SGSeedNewInstallDefaults(NSUserDefaults.standardUserDefaults); }
}
@end
#endif
