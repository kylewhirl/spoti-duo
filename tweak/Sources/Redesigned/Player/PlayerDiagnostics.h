// Temporary, opt-in geometry/action probe. No view descriptions, labels, models or text.
#import "Redesigned/Library/LibraryDiagnostics.h"
#import <objc/runtime.h>
#import <string.h>

static NSDictionary *SGRPlayerGestureMetadata(id object, NSUInteger depth) {
    NSMutableDictionary *entry = [SGRLibraryDiagnosticItem(object) mutableCopy];
    if (!object || depth > 2) return entry;
    NSMutableArray *ivars = [NSMutableArray array];
    for (Class cls = [object class]; cls && cls != NSObject.class; cls = class_getSuperclass(cls)) {
        unsigned count = 0;
        Ivar *list = class_copyIvarList(cls, &count);
        for (unsigned i = 0; i < count; i++) {
            Ivar ivar = list[i];
            const char *type = ivar_getTypeEncoding(ivar);
            NSString *name = @(ivar_getName(ivar));
            NSMutableDictionary *field = [@{@"name": name, @"type": @(type)} mutableCopy];
            if (type[0] == ':') {
                SEL selector = NULL;
                memcpy(&selector, (const char *)(__bridge void *)object + ivar_getOffset(ivar), sizeof(selector));
                if (selector) field[@"selector"] = NSStringFromSelector(selector);
            } else if (type[0] == '@' && [name.lowercaseString containsString:@"target"]) {
                id target = object_getIvar(object, ivar);
                if ([target isKindOfClass:NSArray.class]) {
                    NSMutableArray *targets = [NSMutableArray array];
                    for (id value in target) [targets addObject:SGRPlayerGestureMetadata(value, depth + 1)];
                    field[@"targets"] = targets;
                } else {
                    field[@"target"] = SGRLibraryDiagnosticItem(target);
                }
            }
            [ivars addObject:field];
        }
        free(list);
    }
    entry[@"runtimeIvars"] = ivars;
    return entry;
}

static NSDictionary *SGRPlayerControlMetadata(UIView *source, BOOL descend) {
    NSMutableDictionary *entry = [SGRLibraryDiagnosticItem(source) mutableCopy];
    NSMutableArray *events = [NSMutableArray array];
    if ([source isKindOfClass:UIControl.class]) {
        UIControl *control = (UIControl *)source;
        entry[@"allControlEvents"] = @(control.allControlEvents);
        [control enumerateEventHandlers:^(UIAction *action, id target, SEL selector, UIControlEvents mask, BOOL *stop) {
            [events addObject:@{@"events": @(mask), @"target": SGRLibraryDiagnosticItem(target),
                               @"selector": selector ? NSStringFromSelector(selector) : @"",
                               @"actionClass": action ? NSStringFromClass(action.class) : @""}];
        }];
    }
    entry[@"controlHandlers"] = events;
    NSMutableArray *gestures = [NSMutableArray array];
    for (UIGestureRecognizer *gesture in source.gestureRecognizers)
        [gestures addObject:SGRPlayerGestureMetadata(gesture, 0)];
    entry[@"gestures"] = gestures;
    NSMutableArray *children = [NSMutableArray array];
    if (descend) for (UIView *child in source.subviews) [children addObject:SGRPlayerControlMetadata(child, YES)];
    entry[@"children"] = children;
    return entry;
}

static NSDictionary *SGRPlayerDiagnosticViewState(UIView *view) {
    if (!view) return @{};
    NSMutableDictionary *entry = [SGRLibraryDiagnosticItem(view) mutableCopy];
    entry[@"frame"] = NSStringFromCGRect(view.frame);
    entry[@"bounds"] = NSStringFromCGRect(view.bounds);
    entry[@"windowFrame"] = NSStringFromCGRect([view convertRect:view.bounds toView:view.window]);
    entry[@"alpha"] = @(view.alpha);
    entry[@"hidden"] = @(view.hidden);
    entry[@"userInteractionEnabled"] = @(view.userInteractionEnabled);
    entry[@"clipsToBounds"] = @(view.clipsToBounds);
    if ([view.nextResponder isKindOfClass:UIViewController.class])
        entry[@"controller"] = SGRLibraryDiagnosticItem(view.nextResponder);
    return entry;
}

static NSArray *SGRPlayerDiagnosticViewChain(UIView *view) {
    NSMutableArray *chain = [NSMutableArray array];
    for (UIView *ancestor = view; ancestor && chain.count < 100; ancestor = ancestor.superview)
        [chain addObject:SGRPlayerDiagnosticViewState(ancestor)];
    return chain;
}

static NSDictionary *SGRPlayerDiagnosticHitTests(UIWindow *window, UIView *host) {
    __block UIView *proxy = nil;
    SGForEachView(window, ^(UIView *view) {
        if ([view.accessibilityIdentifier isEqualToString:@"spotifyglass.player.sidebar-more"]) proxy = view;
    });
    NSMutableArray *samples = [NSMutableArray array];
    if (proxy) {
        CGRect b = proxy.bounds;
        CGFloat inset = 2;
        NSArray<NSValue *> *points = @[
            [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(b), CGRectGetMidY(b))],
            [NSValue valueWithCGPoint:CGPointMake(CGRectGetMinX(b) + inset, CGRectGetMinY(b) + inset)],
            [NSValue valueWithCGPoint:CGPointMake(CGRectGetMaxX(b) - inset, CGRectGetMinY(b) + inset)],
            [NSValue valueWithCGPoint:CGPointMake(CGRectGetMinX(b) + inset, CGRectGetMaxY(b) - inset)],
            [NSValue valueWithCGPoint:CGPointMake(CGRectGetMaxX(b) - inset, CGRectGetMaxY(b) - inset)]];
        NSArray *names = @[@"center", @"topLeft", @"topRight", @"bottomLeft", @"bottomRight"];
        for (NSUInteger i = 0; i < points.count; i++) {
            CGPoint local = points[i].CGPointValue;
            CGPoint at = [proxy convertPoint:local toView:window];
            UIView *hit = [window hitTest:at withEvent:nil];
            [samples addObject:@{@"sample": names[i], @"proxyPoint": NSStringFromCGPoint(local),
                @"windowPoint": NSStringFromCGPoint(at), @"hit": SGRPlayerDiagnosticViewState(hit),
                @"reachesProxy": @(hit == proxy || [hit isDescendantOfView:proxy]),
                @"hitViewChain": SGRPlayerDiagnosticViewChain(hit)}];
        }
    }
    NSMutableArray *responders = [NSMutableArray array];
    for (UIResponder *responder = host; responder && responders.count < 100; responder = responder.nextResponder) {
        NSMutableDictionary *entry = [SGRLibraryDiagnosticItem(responder) mutableCopy];
        if ([responder isKindOfClass:UIViewController.class]) {
            UIViewController *controller = (UIViewController *)responder;
            entry[@"parent"] = SGRLibraryDiagnosticItem(controller.parentViewController);
            entry[@"presenting"] = SGRLibraryDiagnosticItem(controller.presentingViewController);
            entry[@"presented"] = SGRLibraryDiagnosticItem(controller.presentedViewController);
            entry[@"view"] = SGRPlayerDiagnosticViewState(controller.viewIfLoaded);
        }
        [responders addObject:entry];
    }
    return @{@"selectedHost": SGRPlayerDiagnosticViewState(host),
             @"hostViewChain": SGRPlayerDiagnosticViewChain(host),
             @"hostResponderChain": responders, @"proxyFound": @(proxy != nil),
             @"proxyViewChain": SGRPlayerDiagnosticViewChain(proxy), @"samples": samples};
}

static void SGRPlayerScheduleDiagnostic(UIView *host) {
    static BOOL scheduled;
    const char *enabled = getenv("SPOTI_DUO_DIAGNOSTICS");
    if (scheduled || !enabled || !*enabled || !host.window) return;
    __block UIView *source = nil;
    SGForEachView(host, ^(UIView *view) {
        if ([view.accessibilityIdentifier isEqualToString:@"Context menu"]) source = view;
    });
    if (!source) {
        __block UIView *sidebar = nil;
        SGForEachView(host.window, ^(UIView *view) {
            if ([view.accessibilityIdentifier isEqualToString:@"spotifyglass.player.sidebar-more"]) sidebar = view;
        });
        SGForEachView(sidebar, ^(UIView *view) {
            if ([view.accessibilityIdentifier isEqualToString:@"Context menu"]) source = view;
        });
    }
    if (!source) return;
    scheduled = YES;
    __weak UIWindow *window = host.window;
    __weak UIView *weakSource = source;
    __weak UIView *weakHost = host;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!window || !weakSource || !weakHost) return;
        NSUInteger remaining = 20000;
        NSMutableArray *ancestors = [NSMutableArray array];
        for (UIView *view = weakSource.superview; view; view = view.superview)
            [ancestors addObject:SGRPlayerControlMetadata(view, NO)];
        NSDictionary *snapshot = @{@"geometry": SGRLibraryDiagnosticView(window, 0, &remaining),
                                   @"menuControl": SGRPlayerControlMetadata(weakSource, YES), @"menuAncestors": ancestors,
                                   @"proxyHitTests": SGRPlayerDiagnosticHitTests(window, weakHost)};
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:snapshot options:NSJSONWritingPrettyPrinted error:&error];
        NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        NSURL *directory = [documents URLByAppendingPathComponent:@"SpotiDuoDiagnostics" isDirectory:YES];
        if (data && [NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:&error])
            [data writeToURL:[directory URLByAppendingPathComponent:@"player.json"] options:NSDataWritingAtomic error:&error];
        SGLog(@"player geometry/action probe: %@", error ? error.localizedDescription : @"written");
    });
}
