#import <Foundation/Foundation.h>
#import "SGInstallDefaults.h"
int main(void) { @autoreleasepool {
 NSString *suite = [@"spoti-defaults-test-" stringByAppendingString:NSUUID.UUID.UUIDString];
 NSUserDefaults *s = [[NSUserDefaults alloc] initWithSuiteName:suite];
 [s setObject:@"untouched" forKey:@"spotify.other"];
 NSCAssert(SGSeedNewInstallDefaults(s), @"fresh install seeded");
 for (NSString *k in SGNewInstallDefaults()) NSCAssert([[s objectForKey:k] isEqual:SGNewInstallDefaults()[k]], @"seed matches");
 NSCAssert(![s objectForKey:@"spotifyglass.onboarding.seen"], @"onboarding not copied");
 NSCAssert([[s stringForKey:@"spotify.other"] isEqual:@"untouched"], @"native preserved");
 [s setInteger:0 forKey:@"spotifyglass.redesign.appearance"];
 NSDictionary *before=[s persistentDomainForName:suite];
 NSCAssert(!SGSeedNewInstallDefaults(s), @"repeat must skip");
 NSCAssert([before isEqual:[s persistentDomainForName:suite]], @"repeat identical");
 for (NSString *legacy in @[@"spotifyglass.stock", @"spotifyglass.onboarding.seen", @"spotifyglass.musixmatchLyrics", @"spotifyglass.redesign.appearance"]) {
  [s removePersistentDomainForName:suite]; [s setBool:NO forKey:legacy];
  before=[s persistentDomainForName:suite];
  NSCAssert(!SGSeedNewInstallDefaults(s), @"legacy profile skip even explicit false");
  NSCAssert([before isEqual:[s persistentDomainForName:suite]], @"no new defaults injected in existing profile");
 }
 [s removePersistentDomainForName:suite];
 puts("PASS: fresh defaults, exact choices, native preservation, no onboarding/cache copy, repeated launches, legacy/reset/false values unchanged");
} }
