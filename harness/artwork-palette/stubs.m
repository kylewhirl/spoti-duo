// Fixture player-state and playback-transition inputs; production accent/appearance hooks are compiled.
#import <UIKit/UIKit.h>

// Redesigned/Kit/SGRBridges.x: SGRField.m asks whether the player is opening or closing for its moving field.
BOOL SGRPlayerIsTransitioning(void) { return NO; }
void SGRObservePlayerTransition(id owner, void (^began)(id owner), void (^ended)(id owner)) {}


#import "Redesigned/Kit/SGRBridges.h"
NSNotificationName const SGRNowPlayingArtworkDidChangeNotification=@"fixture.artwork";
UIImage *fixtureArt; NSString *fixtureIdentity;
@interface FixtureTrack:NSObject @end
@implementation FixtureTrack
- (id)URI {return @"track:current";}
@end
@interface FixtureState:NSObject @end
@implementation FixtureState
- (id)track {return [FixtureTrack new];}
@end
UIImage *SGRNowPlayingArtwork(NSString **uri,NSString **identity) {if(uri)*uri=@"track:current";if(identity)*identity=fixtureIdentity;return fixtureArt;}
SPTPlayerState *SGPlayerState(void) {return (id)[FixtureState new];}
NSString *SGURIString(id uri) { return [uri isKindOfClass:NSString.class]?uri:nil; }
void SGAddPlayerStateObserver(id<SGPlayerStateObserver> observer) {}

UIImage *SGRCurrentNowPlayingArtwork(NSString **identity) {return SGRNowPlayingArtwork(NULL,identity);}

BOOL fixturePending;
BOOL SGRCurrentNowPlayingArtworkPending(void) {return fixturePending;}

CFTimeInterval SGRHomeProbeBegin(void) {return 0;}
void SGRHomeProbeEnd(NSUInteger probe, CFTimeInterval time) {}
