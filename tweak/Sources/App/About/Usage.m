// Duo does not collect or transmit upstream usage reports, even if an older build enabled them.
#import "About.h"
NSData *SGUsageBody(void) { return nil; }
BOOL SGUsageOwed(void) { return NO; }
void SGUsageNoteAsked(void) { }
