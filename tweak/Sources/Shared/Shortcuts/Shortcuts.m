#import <Foundation/Foundation.h>
#import <objc/message.h>
// Existing shared player capture, read only on the main queue.
extern id SGKaraokePlayer(void);
#import "Headers/SPTPlayer.h"

// Proven in Spotify 9.1.94: SPTPlayerContext.URI is NSURL; SPTEsperantoPlayer
// exposes playContext:options:. Never drive buttons or borrow another app's credentials.
static void attempt(NSString *uri, void (^completion)(NSString *), NSUInteger remaining, BOOL submitted) {
    id player = SGKaraokePlayer();
    @try {
        if (submitted) {
            SPTPlayerState *state = [player respondsToSelector:@selector(state)] ? [(id<SPTPlayer>)player state] : nil;
            id context = state.contextURI;
            NSString *actual = [context isKindOfClass:NSURL.class] ? [context absoluteString] : context;
            BOOL same = [actual isKindOfClass:NSString.class] && ([actual isEqualToString:uri] ||
                ([uri isEqualToString:@"spotify:collection:tracks"] && [actual hasPrefix:@"spotify:user:"] && [actual hasSuffix:@":collection"]));
            if (same && state.isPlaying && !state.isPaused) { completion(nil); return; }
        } else if ([player respondsToSelector:NSSelectorFromString(@"playContext:options:")]) {
            id context = [NSClassFromString(@"SPTPlayerContext") new];
            SEL setter = NSSelectorFromString(@"setURI:");
            if (![context respondsToSelector:setter]) { completion(@"This Spotify version does not support playlist playback from Shortcuts."); return; }
            ((void (*)(id, SEL, id))objc_msgSend)(context, setter, [NSURL URLWithString:uri]);
            ((id (*)(id, SEL, id, id))objc_msgSend)(player, NSSelectorFromString(@"playContext:options:"), context, nil);
            submitted = YES;
        }
    } @catch (__unused NSException *exception) {
        completion(@"Spoti Duo could not start this playlist."); return;
    }
    if (!remaining) { completion(submitted ? @"Spoti Duo did not start playback. Check that the playlist is available and you are signed in." : @"Spoti Duo's player is not ready. Open Spoti Duo and try again."); return; }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 250 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        attempt(uri, completion, remaining - 1, submitted);
    });
}

__attribute__((constructor)) static void SGDuoInstallShortcuts(void) {
    [NSNotificationCenter.defaultCenter addObserverForName:@"SGDuoShortcutPlay" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        NSString *uri = note.object;
        void (^completion)(NSString *) = note.userInfo[@"completion"];
        if (!completion) return;
        if (![uri isKindOfClass:NSString.class]) { completion(@"Missing playlist."); return; }
        attempt(uri, completion, 40, NO);
    }];
}
