// What the harness does not compile: the accent hook (SGRAccent.x) and the repaint hook (SGRRepaint.x).
#import <UIKit/UIKit.h>

// Redesigned/Kit/SGRBridges.x: SGRField.m asks whether the player is opening or closing for its moving field.
BOOL SGRPlayerIsTransitioning(void) { return NO; }
void SGRObservePlayerTransition(id owner, void (^began)(id owner), void (^ended)(id owner)) {}

NSString *SGRAccentLabel(void) { return @"Spotify green"; }
void SGRPickAccent(void) {}
