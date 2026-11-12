#import "Core/SGCore.h"
#import "SGRQueueConfirmation.h"

// All classes/selectors are present in cached Spotify 9.1.94. The native presenter
// continues to position/animate the snackbar against its own bottom layout guide,
// including a side tab bar, keyboard, modal presentation and connection indicator.
%hook SPTSnackbarView
- (void)layoutSubviews {
    %orig;
    SGRRefreshQueueConfirmation((UIView *)self);
}
- (void)didMoveToWindow {
    %orig;
    if (![(UIView *)self window]) SGRReleaseQueueConfirmation((UIView *)self);
    [(UIView *)self setNeedsLayout];
}
- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    %orig;
    [(UIView *)self setNeedsLayout];
}
%end

%hook SPTSnackbarTextButtonContentViewModel
- (void)bindView:(UIView *)view {
    // A fresh model can bind the same native view/button without detaching it.
    // This is a new presentation, so Open must not inherit the prior tap guard.
    // Restore our previous presentation BEFORE native binding: bindView: owns
    // any new alpha/accessibility state and must not have it overwritten after.
    for (UIView *ancestor = view.superview; ancestor; ancestor = ancestor.superview) {
        if (![NSStringFromClass(ancestor.class) isEqualToString:@"SPTSnackbarView"]) continue;
        SGRReleaseQueueConfirmation(ancestor);
        break;
    }
    %orig;
    // Native binding may reparent the content, so resolve its current owner.
    for (UIView *ancestor = view.superview; ancestor; ancestor = ancestor.superview) {
        if (![NSStringFromClass(ancestor.class) isEqualToString:@"SPTSnackbarView"]) continue;
        [ancestor setNeedsLayout];
        break;
    }
}
%end

%ctor {
    if (!SGRedesignedUI()) return;
    %init;
    SGRequireClasses(@[@"SPTSnackbarView", @"SPTSnackbarWithActionView", @"SPTSnackbarTextButtonContentViewModel"]);
}
