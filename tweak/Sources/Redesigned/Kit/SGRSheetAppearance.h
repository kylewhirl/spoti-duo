#import <UIKit/UIKit.h>

// Explicit Spotify presentation owners only. Never applies to a window or arbitrary modal.
void SGRApplyNativeSheetAppearance(UIViewController *controller);
// Share payloads are content, not app chrome, including when inserted after the sheet loads.
BOOL SGRNativeSheetPreservesView(UIView *view);

BOOL SGRNativeSheetOwnsEffect(UIView *view);
void SGRRefreshNativeSheetNode(UIView *view);

// Exact context-menu normal row semantic role; native cached base.text may outlive a theme.
BOOL SGRNativeContextMenuUsesBaseText(UIView *view);

// Exact Library filter presentation subtree, for its observed #101010 chip surface.
BOOL SGRNativeLibraryFilterOwnsView(UIView *view);
