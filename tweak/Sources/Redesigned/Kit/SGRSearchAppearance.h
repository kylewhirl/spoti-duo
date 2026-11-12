#import <UIKit/UIKit.h>

// Search's proven HeaderViewController only. Native field, Cancel and filter chips remain
// native controls; their effects and input ink adopt the same selected appearance.
void SGRApplySearchAppearance(UIViewController *header);
BOOL SGRSearchOwnsEffect(UIView *view);
void SGRRefreshSearchNode(UIView *view);
