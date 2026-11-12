#import <UIKit/UIKit.h>

// Native message bar stays at its native Y/height. Only the painted/content lane changes.
CGRect SGRConnectionBarContentLane(CGRect bounds, CGRect rail);
void SGRLayoutConnectionBar(UIView *bar);
// Explicit rail input is also the geometry fixture seam; production obtains it from UIKit.
void SGRLayoutConnectionBarInRail(UIView *bar, CGRect rail);
