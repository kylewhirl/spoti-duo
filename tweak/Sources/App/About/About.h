// Duo update API compatibility. This source candidate has no configured release feed.
// All checks are inert; usage reporting is disabled regardless of legacy preferences.
#import <UIKit/UIKit.h>
#import "Settings/SGModPage.h"

extern NSString *const SGUpdateURL;   // empty until a Duo-owned feed is configured
extern NSString *const SGUpdateCheckedNotification;   // on the main thread, after a check ends either way

// One line of a release's changelog: what changed, under the heading Release Please put it under,
// and the commit it came from.
@interface SGUpdateChange : NSObject
@property (nonatomic, copy) NSString *kind;   // "Features", "Fixes", ... as the release names it
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *url;    // the commit, nil for a line written by hand
@end

// One GitHub release, as the last check stored it.
@interface SGUpdateRelease : NSObject
@property (nonatomic, copy) NSString *version;   // without the tag's v
@property (nonatomic, copy) NSString *date;      // ISO 8601, as GitHub publishes it
@property (nonatomic, copy) NSString *url;       // the release page, where the .deb is
@property (nonatomic, copy) NSArray<SGUpdateChange *> *changes;
@end

NSArray<SGUpdateRelease *> *SGUpdateReleases(void);   // newest first, empty until a check lands
SGUpdateRelease *SGUpdateNewestRelease(void);
NSString *SGUpdateVersion(void);  // nil unless GitHub has a release newer than this build
BOOL SGUpdateIsNewer(NSString *version);   // whether that release is newer than the build running
NSString *SGUpdateStatus(void);
void SGCheckForUpdate(BOOL force);
UIViewController *SGUpdatePage(void);   // UpdatePage.m: the state and the changelog

// Legacy key retained for compatibility; Usage.m never collects or sends a body.
#define SGKeyUsage @"spotipw.usage"
NSData *SGUsageBody(void);
BOOL SGUsageOwed(void);        // always NO in Duo
void SGUsageNoteAsked(void);

// UpdateNotice.m: the sheet a release newer than this build brings on its own, a few seconds after
// Spotify comes up, once per release. Watched from the settings %ctor; the switch is on the Updates
// page and takes effect at once.
#define SGKeyUpdateNotice @"spotifyglass.update.notice"
void SGWatchForUpdates(void);
BOOL SGUpdateNoticeShown(void);   // this run, so the donate sheet stays out of its way


// Whether the now playing card on the lock screen can open this build. It depends on the signature,
// not on the mod: iOS launches by the App ID of the application-identifier entitlement, so a build
// whose bundle id is not that App ID cannot be opened from the card. Signing.m says so once.
extern NSString *const SGSigningHelpURL;
NSString *SGSigningAppIdentifier(void);      // App ID without the team prefix, nil if unreadable
BOOL SGSigningOpensFromLockScreen(void);     // YES when unreadable, so a build that works stays quiet
SGModRow *SGSigningWarningRow(void);          // nil while the signature is sound
void SGCheckSigningOnce(void);
void SGShowSigningFixIfPending(void);   // the sheet the tour held back, if any

// Backup.m: the settings out to a JSON file through the share sheet, and back in from one, replacing
// what is set and restarting.
void SGExportSettings(void);
void SGImportSettings(void);

UIViewController *SGAboutPage(void);   // the Mod page
