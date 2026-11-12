#import "Core/SGCore.h"
#import "SGRShareControls.h"
#import <dlfcn.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <objc/message.h>

// 9.1.94 OnPlatformDestinationView icon-only builder: 0x107609f48.
// Its explicit dark.invertedDark.background.press becomes SwiftUI.Color(UIColor).
// Facepile/UIImage branches and all other Color.value callers remain native.
// Encore.Color is a four-byte value; value returns an owned Objective-C reference.
typedef UIColor * __attribute__((swiftcall, ns_returns_retained)) (*NativeColorValue)(uint32_t);
static NativeColorValue nativeColorValue;
static uintptr_t iconColorReturnPC;
static UIColor *lightActionSurface;

BOOL SGRPrepareShareActionPalette(void) {
    Class theme=NSClassFromString(@"SPTEncoreColorTheme");
    @try {
        id light=((id(*)(id,SEL))objc_msgSend)(theme,NSSelectorFromString(@"light"));
        id value=[light valueForKeyPath:@"base.background.press.value"];
        if(![value isKindOfClass:UIColor.class]) return NO;
        lightActionSurface=value;
    } @catch(NSException *exception) { return NO; }
    return YES;
}
UIColor *SGRShareActionDiscColor(UIColor *nativeDark) {
    if (!nativeDark || !lightActionSurface) return nativeDark;
    UIColor *light=lightActionSurface;
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        return traits.userInterfaceStyle==UIUserInterfaceStyleLight ? light : nativeDark;
    }];
}
static UIColor * __attribute__((swiftcall, ns_returns_retained, noinline)) shareColorValue(uint32_t color) {
    uintptr_t caller=(uintptr_t)__builtin_return_address(0);
    UIColor *source=nativeColorValue(color);
    return SGRedesignedUI() && caller==iconColorReturnPC ? SGRShareActionDiscColor(source) : source;
}
// Copy link is rasterized twice by native code: Encore's glyph compositor, then
// Share_ECMKit's circular crop. Carry provenance on the exact source image, not a
// thread-local "next image" flag. Only a stack-scoped, proven native crop may collect it.
// The static extension metatype uses swiftself/x20. This implementation does not
// read it, but forward it unchanged rather than rely on that implementation detail.
// Icon/UIColor inputs are borrowed; UIImage result is +1.
typedef UIImage * __attribute__((swiftcall, ns_returns_retained)) (*NativeImage)(void *, CGSize, CGSize, uint8_t, UIColor *, UIColor *, CGPoint, void * __attribute__((swift_context)));
typedef void ** __attribute__((swiftcall)) (*IconAddressor)(void);
static NativeImage nativeImage;
static void *chainIcon;
static uintptr_t imageReturnPC,cropReturnPC;
static char kShareLightImage;
static UIImage *(*originalRender)(id,SEL,void (^)(UIGraphicsImageRendererContext *));
static void (*originalDraw)(id,SEL,CGRect);
typedef struct ShareCropFrame { struct ShareCropFrame *previous; BOOL sawMarked; BOOL light; } ShareCropFrame;
static _Thread_local ShareCropFrame *cropFrame;
static UIImage *adaptiveImages(UIImage *dark,UIImage *light) {
    if(!dark || !light) return dark;
    UIImageAsset *asset=[UIImageAsset new];
    UITraitCollection *(^traits)(UIUserInterfaceStyle,CGFloat)=^UITraitCollection *(UIUserInterfaceStyle style,CGFloat scale) {
        return [UITraitCollection traitCollectionWithTraitsFromCollections:@[
            [UITraitCollection traitCollectionWithUserInterfaceStyle:style],
            [UITraitCollection traitCollectionWithDisplayScale:scale]]];
    };
    [asset registerImage:dark withTraitCollection:traits(UIUserInterfaceStyleDark,dark.scale)];
    [asset registerImage:light withTraitCollection:traits(UIUserInterfaceStyleLight,light.scale)];
    UIImage *result=[asset imageWithTraitCollection:traits(SGRedesignAppearanceStyle(),dark.scale)];
    return result?:dark;
}
static UIImage * __attribute__((swiftcall, ns_returns_retained, noinline)) shareNativeImage(void *icon,CGSize iconSize,CGSize imageSize,uint8_t glyphSize,UIColor *ink,UIColor *backing,CGPoint offset,void *context __attribute__((swift_context))) {
    uintptr_t caller=(uintptr_t)__builtin_return_address(0);
    UIImage *source=nativeImage(icon,iconSize,imageSize,glyphSize,ink,backing,offset,context);
    if(!SGRedesignedUI() || caller!=imageReturnPC || icon!=chainIcon || !source ||
       !CGSizeEqualToSize(iconSize,CGSizeMake(24,24)) || !CGSizeEqualToSize(imageSize,CGSizeMake(56,56)) ||
       glyphSize!=2 || !CGPointEqualToPoint(offset,CGPointZero)) return source;
    Class theme=NSClassFromString(@"SPTEncoreColorTheme");
    UIColor *lightInk;
    @try { lightInk=[((id(*)(id,SEL))objc_msgSend)(theme,NSSelectorFromString(@"light")) valueForKeyPath:@"base.text.base.value"]; }
    @catch(NSException *exception) { return source; }
    if(![lightInk isKindOfClass:UIColor.class] || !lightActionSurface) return source;
    // Same native compositor, sizes, glyph and offsets. No template tint over the
    // composite bitmap and no modification of the native Dark result.
    UIImage *light=nativeImage(icon,iconSize,imageSize,glyphSize,lightInk,lightActionSurface,offset,context);
    if(light) objc_setAssociatedObject(source,&kShareLightImage,light,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return source;
}
static void shareDraw(id image,SEL selector,CGRect rect) {
    UIImage *light=cropFrame?objc_getAssociatedObject(image,&kShareLightImage):nil;
    if(light) cropFrame->sawMarked=YES;
    originalDraw(light && cropFrame->light?light:image,selector,rect);
}
static UIImage *renderMarkedCrop(id renderer,SEL selector,void (^actions)(UIGraphicsImageRendererContext *)) {
    ShareCropFrame frame={cropFrame,NO,NO};cropFrame=&frame;
    UIImage *dark,*light;
    @try {
        dark=originalRender(renderer,selector,actions);
        if(!frame.sawMarked) return dark;
        frame.light=YES;
        light=originalRender(renderer,selector,actions);
    } @finally { cropFrame=frame.previous; }
    return adaptiveImages(dark,light);
}
static UIImage * __attribute__((noinline)) shareRender(id renderer,SEL selector,void (^actions)(UIGraphicsImageRendererContext *)) {
    uintptr_t caller=(uintptr_t)__builtin_return_address(0);
    if(!SGRedesignedUI() || caller!=cropReturnPC) return originalRender(renderer,selector,actions);
    return renderMarkedCrop(renderer,selector,actions);
}
#ifdef SGR_SHARE_CONTROLS_TESTING
// Fixture-only seam exercises production provenance/flattening without weakening
// the installer UUID/instruction/binding checks in any build.
void SGRShareTestMarkImage(UIImage *source,UIImage *light) {objc_setAssociatedObject(source,&kShareLightImage,light,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
UIImage *SGRShareTestCrop(UIGraphicsImageRenderer *renderer,void (^actions)(UIGraphicsImageRendererContext *)) {
    if(!originalRender) originalRender=(void *)class_getMethodImplementation(UIGraphicsImageRenderer.class,@selector(imageWithActions:));
    if(!originalDraw) { Method draw=class_getInstanceMethod(UIImage.class,@selector(drawInRect:));originalDraw=(void *)method_getImplementation(draw);method_setImplementation(draw,(IMP)shareDraw); }
    return renderMarkedCrop(renderer,@selector(imageWithActions:),actions);
}
#endif
static BOOL rangeInSegment(const struct mach_header_64 *header, intptr_t slide, uintptr_t address, size_t length, const char *name) {
    const struct load_command *command=(const void *)(header+1);
    for(uint32_t i=0;i<header->ncmds;i++,command=(const void *)((const char *)command+command->cmdsize)) {
        if(command->cmd!=LC_SEGMENT_64) continue;
        const struct segment_command_64 *segment=(const void *)command;
        uintptr_t start=(uintptr_t)slide+segment->vmaddr;
        if(!strcmp(segment->segname,name) && address>=start && length<=segment->vmsize && address-start<=segment->vmsize-length) return YES;
    }
    return NO;
}
static BOOL slotProtectionFailure;
static BOOL replaceBoundSlot(void **slot,void *expected,void *replacement) {
    uintptr_t slotAddress=(uintptr_t)slot;
    if(*slot!=expected) return NO;
    vm_address_t region=slotAddress;vm_size_t regionSize=0;
    vm_region_basic_info_data_64_t info;mach_msg_type_number_t count=VM_REGION_BASIC_INFO_COUNT_64;mach_port_t object=MACH_PORT_NULL;
    kern_return_t result=vm_region_64(mach_task_self(),&region,&regionSize,VM_REGION_BASIC_INFO_64,(vm_region_info_t)&info,&count,&object);
    if(object!=MACH_PORT_NULL) mach_port_deallocate(mach_task_self(),object);
    if(result!=KERN_SUCCESS || region>slotAddress || regionSize<sizeof(void *) || slotAddress-region>regionSize-sizeof(void *) || !(info.protection&VM_PROT_READ)) return NO;
    vm_address_t page=slotAddress&~((uintptr_t)vm_page_size-1);
    if(vm_protect(mach_task_self(),page,vm_page_size,FALSE,info.protection|VM_PROT_WRITE|VM_PROT_COPY)!=KERN_SUCCESS) return NO;
    *slot=replacement;
    if(vm_protect(mach_task_self(),page,vm_page_size,FALSE,info.protection)!=KERN_SUCCESS) {
        *slot=expected;
        if(vm_protect(mach_task_self(),page,vm_page_size,FALSE,info.protection)!=KERN_SUCCESS) {
            slotProtectionFailure=YES;SGLog(@"share: import page protection restore failed, retry disabled");
        }
        return NO;
    }
    return YES;
}
BOOL SGRInstallShareActionPalette(void) {
    static BOOL installed,failedPartial;
    if(installed) return YES;
    if(failedPartial || slotProtectionFailure) return NO;
    if(!SGRedesignedUI() || !NSThread.isMainThread) return NO;
    const struct mach_header_64 *header=NULL;intptr_t slide=0;
    for(uint32_t i=0;i<_dyld_image_count();i++) {
        const struct mach_header *candidate=_dyld_get_image_header(i);
        if(candidate->magic==MH_MAGIC_64 && candidate->filetype==MH_EXECUTE) {header=(const void *)candidate;slide=_dyld_get_image_vmaddr_slide(i);break;}
    }
    if(!header) return NO;
    static const uint8_t expectedUUID[16]={0x1d,0xfd,0xdf,0xa1,0x39,0xc0,0x37,0x35,0xb9,0xa5,0xfd,0xfa,0x47,0x5f,0x47,0x00};
    BOOL matches=NO;const struct load_command *command=(const void *)(header+1);
    for(uint32_t i=0;i<header->ncmds;i++,command=(const void *)((const char *)command+command->cmdsize))
        if(command->cmd==LC_UUID) matches=!memcmp(((const struct uuid_command *)command)->uuid,expectedUUID,16);
    if(!matches) return NO;
    uintptr_t call=(uintptr_t)slide+0x107609f80,stub=(uintptr_t)slide+0x10a3d1094,slotAddress=(uintptr_t)slide+0x10d5f39d8;
    if(!rangeInSegment(header,slide,call,8,"__TEXT") || !rangeInSegment(header,slide,stub,12,"__TEXT") ||
       !rangeInSegment(header,slide,slotAddress,sizeof(void *),"__DATA_CONST")) return NO;
    const uint32_t expectedCall[]={0x94b71c45,0x94b72988};
    const uint32_t expectedStub[]={0xd0019110,0xf944ee10,0xd61f0200};
    if(memcmp((void *)call,expectedCall,sizeof(expectedCall)) || memcmp((void *)stub,expectedStub,sizeof(expectedStub))) return NO;
    void *expected=dlsym(RTLD_DEFAULT,"$s16EncoreFoundation0A0O5ColorV0A8_CoreKitE5valueSo7UIColorCvg");
    void **slot=(void **)slotAddress;
    // This proven stub uses plain BR x16, not an authenticated branch. Reject any
    // unfamiliar binding rather than attempting to strip/sign an unknown pointer.
    if(!expected || *slot!=expected) return NO;
    if(!SGRPrepareShareActionPalette()) return NO;
    uintptr_t imageCall=(uintptr_t)slide+0x1007dd0d0,imageStub=(uintptr_t)slide+0x10a3d713c;
    uintptr_t imageSlotAddress=(uintptr_t)slide+0x10d5f4538,cropCall=(uintptr_t)slide+0x1007dd31c;
    const uint32_t imageStubWords[]={0xb00190f0,0xf9429e10,0xd61f0200};
    if(!rangeInSegment(header,slide,imageCall,8,"__TEXT") || !rangeInSegment(header,slide,cropCall,8,"__TEXT") ||
       !rangeInSegment(header,slide,imageStub,12,"__TEXT") || !rangeInSegment(header,slide,imageSlotAddress,sizeof(void *),"__DATA_CONST") ||
       *(uint32_t *)imageCall!=0x95d168dc || *(uint32_t *)cropCall!=0x95d155fa ||
       memcmp((void *)imageStub,imageStubWords,sizeof(imageStubWords))) return NO;
    void *imageExpected=dlsym(RTLD_DEFAULT,"$sSo7UIImageC14Encore_CoreKitE5image4icon0F4Size0eG005glyphG05color15backgroundColor6offsetAB0B10Foundation0B0O4IconCSg_So6CGSizeVAsP05GlyphG0OSgSo7UIColorCAXSo7CGPointVtFZ");
    IconAddressor chain=(IconAddressor)dlsym(RTLD_DEFAULT,"$s16EncoreFoundation0A0O4IconC5chainAEvau");
    void **imageSlot=(void **)imageSlotAddress;
    Method rendererMethod=class_getInstanceMethod(UIGraphicsImageRenderer.class,@selector(imageWithActions:));
    Method drawMethod=class_getInstanceMethod(UIImage.class,@selector(drawInRect:));
    if(!imageExpected || *imageSlot!=imageExpected || !chain || !rendererMethod || !drawMethod) return NO;
    void **chainStorage=chain();if(!chainStorage || !*chainStorage) return NO;
    nativeColorValue=(NativeColorValue)expected;iconColorReturnPC=call+4;
    nativeImage=(NativeImage)imageExpected;imageReturnPC=imageCall+4;cropReturnPC=cropCall+4;chainIcon=*chainStorage;
    if(!replaceBoundSlot(slot,expected,(void *)shareColorValue)) return NO;
    if(!replaceBoundSlot(imageSlot,imageExpected,(void *)shareNativeImage)) {
        if(!replaceBoundSlot(slot,(void *)shareColorValue,expected)) {
            // Keep the original callable target alive for the surviving wrapper;
            // never retry and overwrite its trampoline after an uncertain rollback.
            failedPartial=YES;SGLog(@"share: partial install; palette rollback failed, retry disabled");
        }
        return NO;
    }
    originalRender=(void *)method_getImplementation(rendererMethod);
    originalDraw=(void *)method_getImplementation(drawMethod);
    method_setImplementation(rendererMethod,(IMP)shareRender);
    method_setImplementation(drawMethod,(IMP)shareDraw);
    installed=YES;return YES;
}
// Installation is deliberately explicit until retained-SwiftUI rendering validation completes.
