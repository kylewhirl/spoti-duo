#import <Foundation/Foundation.h>

// Seed only an installation with no existing mod state. Never fill holes in an existing profile.
BOOL SGSeedNewInstallDefaults(NSUserDefaults *store);
NSDictionary<NSString *, id> *SGNewInstallDefaults(void);
