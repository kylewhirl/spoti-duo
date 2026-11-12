// Opt-in probe: geometry only. Never serialize view descriptions, text, labels or models.
#import <stdlib.h>

static NSDictionary *SGRLibraryDiagnosticItem(id item) {
    if (!item) return @{};
    return @{ @"class": NSStringFromClass([item class]),
              @"address": [NSString stringWithFormat:@"%p", (__bridge void *)item] };
}

static NSDictionary *SGRLibraryDiagnosticView(UIView *view, NSUInteger depth, NSUInteger *remaining) {
    if (!*remaining || depth > 100) return @{ @"truncated": @YES };
    --*remaining;
    NSMutableDictionary *node = [SGRLibraryDiagnosticItem(view) mutableCopy];
    node[@"identifier"] = view.accessibilityIdentifier ?: @"";
    node[@"frame"] = NSStringFromCGRect(view.frame);
    node[@"bounds"] = NSStringFromCGRect(view.bounds);
    node[@"center"] = NSStringFromCGPoint(view.center);
    node[@"windowFrame"] = NSStringFromCGRect([view convertRect:view.bounds toView:view.window]);
    node[@"safeAreaInsets"] = NSStringFromUIEdgeInsets(view.safeAreaInsets);
    node[@"transform"] = NSStringFromCGAffineTransform(view.transform);
    node[@"alpha"] = @(view.alpha);
    node[@"hidden"] = @(view.hidden);
    node[@"clipsToBounds"] = @(view.clipsToBounds);
    node[@"translatesAutoresizingMaskIntoConstraints"] = @(view.translatesAutoresizingMaskIntoConstraints);
    if ([view.nextResponder isKindOfClass:UIViewController.class]) {
        UIViewController *controller = (UIViewController *)view.nextResponder;
        NSMutableDictionary *owner = [SGRLibraryDiagnosticItem(controller) mutableCopy];
        owner[@"additionalSafeAreaInsets"] = NSStringFromUIEdgeInsets(controller.additionalSafeAreaInsets);
        owner[@"parent"] = SGRLibraryDiagnosticItem(controller.parentViewController);
        node[@"controller"] = owner;
    }
    if ([view isKindOfClass:UIScrollView.class]) {
        UIScrollView *scroll = (UIScrollView *)view;
        node[@"contentInset"] = NSStringFromUIEdgeInsets(scroll.contentInset);
        node[@"adjustedContentInset"] = NSStringFromUIEdgeInsets(scroll.adjustedContentInset);
        node[@"verticalScrollIndicatorInsets"] = NSStringFromUIEdgeInsets(scroll.verticalScrollIndicatorInsets);
        node[@"horizontalScrollIndicatorInsets"] = NSStringFromUIEdgeInsets(scroll.horizontalScrollIndicatorInsets);
        node[@"contentOffset"] = NSStringFromCGPoint(scroll.contentOffset);
        node[@"contentSize"] = NSStringFromCGSize(scroll.contentSize);
        node[@"contentInsetAdjustmentBehavior"] = @(scroll.contentInsetAdjustmentBehavior);
        if (@available(iOS 26.0, *)) {
            node[@"topEdgeHidden"] = @(scroll.topEdgeEffect.hidden);
            node[@"bottomEdgeHidden"] = @(scroll.bottomEdgeEffect.hidden);
            node[@"topEdgeSoft"] = @([scroll.topEdgeEffect.style isEqual:UIScrollEdgeEffectStyle.softStyle]);
            node[@"bottomEdgeSoft"] = @([scroll.bottomEdgeEffect.style isEqual:UIScrollEdgeEffectStyle.softStyle]);
        }
    }
    if ([view isKindOfClass:UICollectionView.class]) {
        UICollectionView *collection = (UICollectionView *)view;
        UICollectionViewLayout *layout = collection.collectionViewLayout;
        NSMutableDictionary *configuration = [SGRLibraryDiagnosticItem(layout) mutableCopy];
        configuration[@"delegate"] = SGRLibraryDiagnosticItem(collection.delegate);
        configuration[@"layoutContentSize"] = NSStringFromCGSize(layout.collectionViewContentSize);
        if ([layout isKindOfClass:UICollectionViewCompositionalLayout.class]) {
            UICollectionViewCompositionalLayoutConfiguration *config = ((UICollectionViewCompositionalLayout *)layout).configuration;
            configuration[@"contentInsetsReference"] = @(config.contentInsetsReference);
            configuration[@"scrollDirection"] = @(config.scrollDirection);
        }
        if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
            UICollectionViewFlowLayout *flow = (id)layout;
            configuration[@"itemSize"] = NSStringFromCGSize(flow.itemSize);
            configuration[@"estimatedItemSize"] = NSStringFromCGSize(flow.estimatedItemSize);
            configuration[@"sectionInset"] = NSStringFromUIEdgeInsets(flow.sectionInset);
            configuration[@"sectionInsetReference"] = @(flow.sectionInsetReference);
            configuration[@"scrollDirection"] = @(flow.scrollDirection);
        }
        NSMutableArray *items = [NSMutableArray array];
        id<UICollectionViewDelegateFlowLayout> delegate = (id)collection.delegate;
        for (NSIndexPath *index in collection.indexPathsForVisibleItems) {
            if (items.count >= 8) break;
            UICollectionViewLayoutAttributes *attributes = [layout layoutAttributesForItemAtIndexPath:index];
            NSMutableDictionary *item = [@{ @"section": @(index.section), @"item": @(index.item),
                @"layoutFrame": NSStringFromCGRect(attributes.frame) } mutableCopy];
            if ([delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)])
                item[@"delegateSize"] = NSStringFromCGSize([delegate collectionView:collection layout:layout sizeForItemAtIndexPath:index]);
            if ([delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)])
                item[@"delegateSectionInset"] = NSStringFromUIEdgeInsets([delegate collectionView:collection layout:layout insetForSectionAtIndex:index.section]);
            [items addObject:item];
        }
        configuration[@"visibleItems"] = items;
        node[@"collectionLayout"] = configuration;
    }
    NSMutableArray *constraints = [NSMutableArray array];
    for (NSLayoutConstraint *constraint in view.constraints) {
        [constraints addObject:@{ @"firstItem": SGRLibraryDiagnosticItem(constraint.firstItem),
            @"secondItem": SGRLibraryDiagnosticItem(constraint.secondItem),
            @"firstAttribute": @(constraint.firstAttribute), @"secondAttribute": @(constraint.secondAttribute),
            @"relation": @(constraint.relation), @"constant": @(constraint.constant),
            @"multiplier": @(constraint.multiplier), @"priority": @(constraint.priority),
            @"active": @(constraint.active) }];
    }
    node[@"constraints"] = constraints;
    NSMutableArray *guides = [NSMutableArray array];
    for (UILayoutGuide *guide in view.layoutGuides) {
        NSMutableDictionary *entry = [SGRLibraryDiagnosticItem(guide) mutableCopy];
        entry[@"frame"] = NSStringFromCGRect(guide.layoutFrame);
        [guides addObject:entry];
    }
    node[@"layoutGuides"] = guides;
    NSMutableArray *children = [NSMutableArray array];
    for (UIView *child in view.subviews) {
        if (!*remaining) { node[@"childrenTruncated"] = @YES; break; }
        [children addObject:SGRLibraryDiagnosticView(child, depth + 1, remaining)];
    }
    node[@"children"] = children;
    return node;
}

static void SGRLibraryWriteDiagnostic(UIWindow *window, NSString *filename) {
    if (!window) return;
    NSUInteger remaining = 20000;
    NSDictionary *snapshot = SGRLibraryDiagnosticView(window, 0, &remaining);
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:snapshot options:NSJSONWritingPrettyPrinted error:&error];
    NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *directory = [documents URLByAppendingPathComponent:@"SpotiDuoDiagnostics" isDirectory:YES];
    if (data && [NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:&error]) {
        [data writeToURL:[directory URLByAppendingPathComponent:filename] options:NSDataWritingAtomic error:&error];
    }
    SGLog(@"library geometry probe: %@ %@", filename, error ? error.localizedDescription : @"written");
}

static inline void SGRLibraryScheduleDiagnostic(UIView *page) {
    static BOOL scheduled;
    const char *enabled = getenv("SPOTI_DUO_DIAGNOSTICS");
    if (scheduled || !enabled || !*enabled || !page.window) return;
    scheduled = YES;
    __weak UIWindow *window = page.window;
    // Leave the current layout stack before traversing; one bounded follow-up catches coalesced layout.
    dispatch_async(dispatch_get_main_queue(), ^{
        SGRLibraryWriteDiagnostic(window, @"library-initial.json");
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        SGRLibraryWriteDiagnostic(window, @"library.json");
    });
}
