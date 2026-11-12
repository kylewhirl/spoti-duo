#import <UIKit/UIKit.h>
// Retains the exact native Dark color; Light uses Spotify's base action surface.
BOOL SGRPrepareShareActionPalette(void);
UIColor *SGRShareActionDiscColor(UIColor *nativeDark);
BOOL SGRInstallShareActionPalette(void);
#ifdef SGR_SHARE_CONTROLS_TESTING
void SGRShareTestMarkImage(UIImage *source,UIImage *light);
UIImage *SGRShareTestCrop(UIGraphicsImageRenderer *renderer,void (^actions)(UIGraphicsImageRendererContext *));
#endif
