// No upstream update links or nonfunctional switches in the source-only Duo candidate.
#import "Core/SGCore.h"
#import "About.h"
UIViewController *SGUpdatePage(void) {
    return [[SGModPage alloc] initWithTitle:@"Updates"
        intro:@"Duo updates are not configured. Automatic checks are off. A Duo-specific release feed is not available yet."
        sections:@[] footer:nil];
}
