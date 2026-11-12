#import <UIKit/UIKit.h>

// UIKit Back belongs to SPNavigationBar, outside the redesigned page subtree. Acquire
// that bar only while its top page contains an explicitly registered redesign root.
// Called by the proven native owner hooks; exposed for the real UIKit regression.
void SGRRefreshNativeNavigationAppearance(UINavigationController *navigation);
