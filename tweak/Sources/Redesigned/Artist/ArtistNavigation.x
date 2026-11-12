// Artist scroll feedback on UIKit 27: native ImageHeader layout alternates an
// empty/nonempty UINavigationItem title while its alpha already performs the
// fade. Removing that title changes the bar/scroll inset by 58pt on Duo, which
// changes header progress back across the title threshold, indefinitely.
// Keep only the title's layout presence stable during this exact native header
// pass. No appearance, alpha, safe-area, scroll offset or global bar changes.
#import "Core/SGCore.h"
#import "Artist.h"
#import "ArtistNavigationTitle.h"
#import "Redesigned/Kit/SGRBarGeometry.h"

static __weak UINavigationItem *artistLayoutItem;
static BOOL artistLayoutHasRail;

// The title still needs its layout slot to prevent the native 58pt feedback
// loop, but Duo already puts Back and More in its right rail. Remove only the
// horizontal background paint while preserving the artist title, never the bar or its geometry.
static UINavigationBarAppearance *railAppearance(UINavigationItem *item, UINavigationBarAppearance *appearance) {
    if (!NSThread.isMainThread || item != artistLayoutItem || !artistLayoutHasRail || !appearance) return appearance;
    UINavigationBarAppearance *copy = [appearance copy];
    copy.backgroundColor = UIColor.clearColor;
    copy.backgroundEffect = nil;
    copy.backgroundImage = nil;
    copy.shadowColor = UIColor.clearColor;
    copy.shadowImage = nil;
    return copy;
}

static UINavigationItem *itemForArtistHeader(UIView *header) {
    if (!NSThread.isMainThread) return nil;
    if (@available(iOS 27.0, *)) {
        UIView *root = SGRArtistPageOf(header);
        if (!root) return nil;
        for (UIResponder *r = header.nextResponder; r; r = r.nextResponder) {
            if (![r isKindOfClass:UIViewController.class]) continue;
            UINavigationController *navigation = ((UIViewController *)r).navigationController;
            UIViewController *page = navigation.topViewController;
            UIView *pageView = page.viewIfLoaded;
            if (pageView && (pageView == root || [root isDescendantOfView:pageView])) return page.navigationItem;
        }
    }
    return nil;
}

%hook _TtC35CreativeWorkPlatform_ImageHeaderKit15ImageHeaderView
- (void)layoutSubviews {
    if (!NSThread.isMainThread) { %orig; return; }
    UINavigationItem *previous = artistLayoutItem;
    BOOL previousRail = artistLayoutHasRail;
    artistLayoutItem = itemForArtistHeader((UIView *)self);
    artistLayoutHasRail = artistLayoutItem && !CGRectIsNull(SGRVerticalBarFrameIn((UIView *)self, SGRVerticalBarExtent));
    @try { %orig; }
    @finally { artistLayoutItem = previous; artistLayoutHasRail = previousRail; }
}
%end

%hook UINavigationItem
- (void)setTitle:(NSString *)title {
    if (NSThread.isMainThread && self == artistLayoutItem) title = SGRArtistStableNavigationTitle(title);
    %orig(title);
}
- (void)setStandardAppearance:(UINavigationBarAppearance *)appearance { %orig(railAppearance(self, appearance)); }
- (void)setScrollEdgeAppearance:(UINavigationBarAppearance *)appearance { %orig(railAppearance(self, appearance)); }
- (void)setCompactAppearance:(UINavigationBarAppearance *)appearance { %orig(railAppearance(self, appearance)); }
- (void)setCompactScrollEdgeAppearance:(UINavigationBarAppearance *)appearance { %orig(railAppearance(self, appearance)); }
%end

%ctor {
    if (!SGRedesignedUI()) return;
    %init;
    SGRequireClasses(@[@"_TtC35CreativeWorkPlatform_ImageHeaderKit15ImageHeaderView"]);
}
