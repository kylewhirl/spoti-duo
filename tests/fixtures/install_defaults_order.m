#import <Foundation/Foundation.h>
__attribute__((constructor)) static void feature(void) { @autoreleasepool { NSCAssert([NSUserDefaults.standardUserDefaults integerForKey:@"spotifyglass.redesign.appearance"] == 2, @"default must precede feature constructor"); } }
int main(void) { @autoreleasepool { [NSUserDefaults.standardUserDefaults removePersistentDomainForName:NSProcessInfo.processInfo.processName]; puts("PASS constructor ordering"); } }
