// The redesign's resolved appearance. Native UI keeps the default dark behavior.
#import <UIKit/UIKit.h>

UIUserInterfaceStyle SGRedesignAppearanceStyle(void);
void SGConfigureRedesignAppearance(UIUserInterfaceStyle style);
BOOL SGRedesignLightAppearance(void);
UIColor *SGAppearanceColor(UIColor *light, UIColor *dark);
// Main-thread only. Owners are weak; callbacks must use their argument, not capture the owner.
// Registration replaces that owner's callback. Refresh runs after the bridge commits its mode.
void SGRegisterAppearanceRefresh(id owner, void (^refresh)(id owner));
void SGRegisterAppearanceView(UIView *view);
void SGRegisterAppearanceController(UIViewController *controller);
void SGRefreshAppearanceOwners(void);
// Main-thread palette changes invalidate retained dynamic colors without changing Light/Dark.
void SGInvalidateAppearanceColors(void);

// Release a scoped presentation override when a reused native view leaves its owner.
void SGUnregisterAppearanceView(UIView *view);
void SGUnregisterAppearanceRefresh(id owner);

// Explicit local appearance scopes. Unspecified is an explicit global boundary,
// not inheritance (use for independent modals presented by an artwork-themed page).
// Scope storage is associated with its root; registries remain weak. Main-thread only.
void SGSetAppearanceScope(UIView *root, UIUserInterfaceStyle style);
void SGClearAppearanceScope(UIView *root);
UIUserInterfaceStyle SGAppearanceStyleForView(UIView *view);
UIUserInterfaceStyle SGAppearanceStyleForOwner(id owner);
UIUserInterfaceStyle SGAppearanceStyleForTraits(UITraitCollection *traits);
void SGRefreshAppearanceSubtree(UIView *root);
