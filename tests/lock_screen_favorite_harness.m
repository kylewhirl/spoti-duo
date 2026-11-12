// Executes the production flag registry, preferences and favorite default against an
// in-memory NSUserDefaults stand-in. Never writes to Spotify or a real defaults suite.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Core/SGPrefs.h"
#import "Core/SGFlagForce.h"
#import "Shared/LockScreenFavorite/LockScreenFavorite.h"

@interface SGFavoriteTestDefaults : NSObject
@property(nonatomic, strong) NSMutableDictionary *values;
@end
@implementation SGFavoriteTestDefaults
- (id)objectForKey:(NSString *)key { return self.values[key]; }
- (BOOL)boolForKey:(NSString *)key { return [self.values[key] boolValue]; }
- (void)setObject:(id)value forKey:(NSString *)key { self.values[key] = value; }
- (void)setBool:(BOOL)value forKey:(NSString *)key { self.values[key] = @(value); }
- (void)removeObjectForKey:(NSString *)key { [self.values removeObjectForKey:key]; }
@end

static SGFavoriteTestDefaults *defaults;
static id testDefaults(id receiver, SEL selector) { return defaults; }
static void check(BOOL condition, NSString *message) {
    if (!condition) { fprintf(stderr, "%s\n", message.UTF8String); exit(1); }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        check(argc == 2, @"Pass one scenario");
        defaults = [SGFavoriteTestDefaults new];
        defaults.values = [NSMutableDictionary dictionary];
        method_setImplementation(class_getClassMethod(NSUserDefaults.class, @selector(standardUserDefaults)), (IMP)testDefaults);
        NSString *scenario = @(argv[1]);
        NSString *key = SGLockScreenFavoritePreferenceKey();
        check([key isEqualToString:[SGFlagOverridePrefix stringByAppendingString:SGLockScreenFavoriteFlag]], @"Must reuse the existing flag preference");
        if ([scenario isEqualToString:@"fresh"]) {
            check([SGForcedFlagValue(SGLockScreenFavoriteFlag) isEqual:@YES], @"Fresh installs enable the native control");
            check(defaults.values.count == 0, @"Default must not write preferences");
        } else if ([scenario isEqualToString:@"prior-off"]) {
            SGSetFlagOverride(SGLockScreenFavoriteFlag, @NO);
            check([SGForcedFlagValue(SGLockScreenFavoriteFlag) isEqual:@NO], @"Preserve explicit prior Off");
            check(!SGFlag(key, YES), @"Switch must show prior Off");
        } else if ([scenario isEqualToString:@"prior-on"]) {
            SGSetFlagOverride(SGLockScreenFavoriteFlag, @YES);
            check([SGForcedFlagValue(SGLockScreenFavoriteFlag) isEqual:@YES], @"Preserve explicit prior On");
            check(SGFlag(key, YES), @"Switch must show prior On");
        } else if ([scenario isEqualToString:@"toggle"]) {
            SGSetEnabled(key, NO);
            check([SGForcedFlagValue(SGLockScreenFavoriteFlag) isEqual:@NO], @"Switch Off must stay Off, not remove the override");
            check([SGFlagOverride(SGLockScreenFavoriteFlag) isEqual:@NO], @"All flags must reflect switch Off");
            SGSetEnabled(key, YES);
            check([SGForcedFlagValue(SGLockScreenFavoriteFlag) isEqual:@YES], @"Switch can enable again");
            check([SGFlagOverride(SGLockScreenFavoriteFlag) isEqual:@YES], @"All flags must reflect switch On");
        } else if ([scenario isEqualToString:@"auto"]) {
            SGSetFlagOverride(SGLockScreenFavoriteFlag, @NO);
            SGSetFlagOverride(SGLockScreenFavoriteFlag, nil);
            check([SGForcedFlagValue(SGLockScreenFavoriteFlag) isEqual:@YES], @"Auto returns to the mod default");
            check(SGFlag(key, YES), @"Switch must show Auto's effective default");
        } else if ([scenario isEqualToString:@"stock"]) {
            SGSetEnabled(SGKeyStock, YES);
            check(SGForcedFlagValue(SGLockScreenFavoriteFlag) == nil, @"Reset must restore Spotify defaults");
            check(!SGFlag(key, YES), @"Switch is unset/off after reset");
            SGSetEnabled(key, YES);
            check([SGForcedFlagValue(SGLockScreenFavoriteFlag) isEqual:@YES], @"User can opt in after reset");
        } else if ([scenario isEqualToString:@"isolation"]) {
            check(SGForcedFlagValue(@"ios-feature-lockscreen.skip_button_on_podcasts") == nil, @"Do not change unrelated flags");
            check(SGForcedFlagValue(nil) == nil, @"Nil query remains nil");
            BOOL beats = YES;
            check(SGLockedFlagValue(SGLockScreenFavoriteFlag, &beats) == nil && !beats, @"Default must not lock explicit controls");
        } else { check(NO, @"Unknown scenario"); }
        printf("PASS %s\n", scenario.UTF8String);
    }
    return 0;
}
