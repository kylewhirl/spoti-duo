// Duo release checks are intentionally unavailable until a verified Duo-owned feed exists.
// Never query the upstream project or reuse its cached release recommendations.
#import "Core/SGCore.h"
#import "About.h"
NSString *const SGUpdateURL = @"";
NSString *const SGUpdateCheckedNotification = @"spotifyglass.update.checked.notification";
@implementation SGUpdateChange
@end
@implementation SGUpdateRelease
@end
NSArray<SGUpdateRelease *> *SGUpdateReleases(void) { return @[]; }
SGUpdateRelease *SGUpdateNewestRelease(void) { return nil; }
BOOL SGUpdateIsNewer(NSString *version) { return NO; }
NSString *SGUpdateVersion(void) { return nil; }
NSString *SGUpdateStatus(void) { return @"not configured"; }
void SGCheckForUpdate(BOOL force) {
    // No network request, usage body, cached upstream result, or forced bypass.
}
