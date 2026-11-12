// System-selected vertical navigation geometry, resolved at the window so translated pages and
// inherited content safe-area insets cannot move the rail. No model or size-class heuristics.
#import <UIKit/UIKit.h>

// Compact icon-only Duo navigation, shared by the rail and content clearance.
static const CGFloat SGRVerticalBarExtent = 48;

// Native Back occupies the first 48pt. Keep a second 48pt menu and an 8pt gap on
// either side when a complete bottom navigation row (48pt) still fits. In very short
// regions, navigation keeps one row and the optional entity menu yields its slot.
static inline CGFloat SGRVerticalBarTopReservation(CGFloat height) {
    if (height >= 160) return 112;
    return MIN(56, MAX(0, height - SGRVerticalBarExtent));
}

static inline CGRect SGRVerticalBarFrameIn(UIView *view, CGFloat extent) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 270100
    if (@available(iOS 27.1, *)) {
        UIWindow *window = [view isKindOfClass:UIWindow.class] ? (UIWindow *)view : view.window;
        if (!window) return CGRectNull;
        UIVerticalBarEdge edge = window.traitCollection.verticalBarEdge;
        if (edge != UIVerticalBarEdgeLeading && edge != UIVerticalBarEdgeTrailing) return CGRectNull;
        NSDirectionalRectEdge directional = edge == UIVerticalBarEdgeLeading ? NSDirectionalRectEdgeLeading : NSDirectionalRectEdgeTrailing;
        UIViewLayoutRegion *region = [UIViewLayoutRegion layoutRegionForBarOnDirectionalEdge:directional extent:extent];
        UIEdgeInsets insets = [window edgeInsetsForLayoutRegion:region];
        CGRect frame = UIEdgeInsetsInsetRect(window.bounds, insets);
        if (CGRectIsEmpty(frame)) return CGRectNull;
        return [view convertRect:frame fromView:window];
    }
#endif
    return CGRectNull;
}

// Spotify shortens the tab container when its native connection status band appears.
// The system rail region stays window-relative, so its bottom can land below the
// tab container's hit-test/clip bounds. Keep the rail inside every owning ancestor;
// this moves its bottom-aligned button group above the band without changing any
// native message, height, safe-area or connection-state behavior.
static inline CGRect SGRVerticalBarVisibleFrameIn(UIView *view, CGRect frame) {
    if (!view || CGRectIsNull(frame) || CGRectIsInfinite(frame)) return frame;
    CGFloat top = CGRectGetMinY(frame), bottom = CGRectGetMaxY(frame);
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        CGRect bounds = [view convertRect:ancestor.bounds fromView:ancestor];
        if (!isfinite(bounds.origin.y) || !isfinite(bounds.size.height)) return frame;
        top = MAX(top, CGRectGetMinY(bounds));
        bottom = MIN(bottom, CGRectGetMaxY(bounds));
        if ([ancestor isKindOfClass:UIWindow.class]) break;
    }
    return CGRectMake(CGRectGetMinX(frame), top, CGRectGetWidth(frame), MAX(0, bottom - top));
}

static inline UIEdgeInsets SGRVerticalBarContentInsets(UIView *view, CGFloat extent) {
    CGRect frame = SGRVerticalBarFrameIn(view, extent);
    if (CGRectIsNull(frame) || CGRectGetMinX(frame) >= CGRectGetMaxX(view.bounds)
        || CGRectGetMaxX(frame) <= CGRectGetMinX(view.bounds)) return UIEdgeInsetsZero;
    // The region is directional; use its resolved physical location so RTL follows UIKit too.
    if (CGRectGetMidX(frame) < CGRectGetMidX(view.bounds))
        return UIEdgeInsetsMake(0, MAX(0, CGRectGetMaxX(frame) - CGRectGetMinX(view.bounds)) + 8, 0, 0);
    return UIEdgeInsetsMake(0, 0, 0, MAX(0, CGRectGetMaxX(view.bounds) - CGRectGetMinX(frame)) + 8);
}
