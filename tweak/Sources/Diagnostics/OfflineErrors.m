// Opt-in, local-only observation of the verified Spotify 9.1.94 event seam.
// Never logs payloads, owner, completion, NSError, or non-error-code proto fields.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import "SGOfflineErrorParser.h"
#include <stdlib.h>

typedef BOOL (*SGOfflineSendIMP)(id, SEL, id, id, id, id, NSError **);
static SGOfflineSendIMP sg_offlineOriginal;

#ifdef SG_OFFLINE_TESTING
static NSURL *sg_offlineTestDocuments;
#endif
static NSURL *SGOfflineDocuments(void) {
#ifdef SG_OFFLINE_TESTING
    return sg_offlineTestDocuments;
#else
    return [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
#endif
}

static void SGOfflineStatus(BOOL installed) {
    @synchronized (NSFileManager.class) {
        @try {
            NSURL *docs = SGOfflineDocuments();
            if (!docs) return;
            NSURL *dir = [docs URLByAppendingPathComponent:@"SpotiDuoDiagnostics" isDirectory:YES];
            NSURL *file = [dir URLByAppendingPathComponent:@"status.json"];
            for (NSURL *url in @[dir, file]) {
                NSDictionary *a = [NSFileManager.defaultManager attributesOfItemAtPath:url.path error:nil];
                if (a && ([a[NSFileType] isEqual:NSFileTypeSymbolicLink] || [a[NSFileSize] unsignedLongLongValue] > 65536)) return;
            }
            if (![NSFileManager.defaultManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil]) return;
            NSString *status = installed ? @"installed" : @"unsupported_runtime_signature";
            NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"status":status, @"monotonic_seconds":@(CACurrentMediaTime())} options:0 error:nil];
            if (data.length <= 512) [data writeToURL:file options:NSDataWritingAtomic error:nil];
        } @catch (__unused NSException *exception) { }
    }
}

static void SGOfflineRecord(int64_t code) {
    // Synchronous bounded work avoids retaining any incoming event objects.
    @synchronized (NSFileManager.class) {
        @try {
            NSURL *docs = SGOfflineDocuments();
            if (!docs) return;
            NSURL *dir = [docs URLByAppendingPathComponent:@"SpotiDuoDiagnostics" isDirectory:YES];
            NSURL *file = [dir URLByAppendingPathComponent:@"offline-errors.jsonl"];
            // Refuse symlinks and unexpected/oversized existing files rather than rewrite them.
            for (NSURL *url in @[dir, file]) {
                NSDictionary *a = [NSFileManager.defaultManager attributesOfItemAtPath:url.path error:nil];
                if (a && ([a[NSFileType] isEqual:NSFileTypeSymbolicLink] || [a[NSFileSize] unsignedLongLongValue] > 65536)) return;
            }
            NSData *existing = [NSData dataWithContentsOfURL:file];
            if (existing.length > 65536) return;
            NSUInteger lines = 0;
            const uint8_t *bytes = existing.bytes;
            for (NSUInteger i = 0; i < existing.length; i++) if (bytes[i] == '\n') lines++;
            if (lines >= 100 || (existing.length && bytes[existing.length - 1] != '\n')) return;
            NSData *line = [[NSString stringWithFormat:@"{\"monotonic_seconds\":%.6f,\"error_code\":%lld}\n", CACurrentMediaTime(), (long long)code] dataUsingEncoding:NSUTF8StringEncoding];
            if (existing.length + line.length > 65536) return;
            if (![NSFileManager.defaultManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil]) return;
            NSMutableData *output = [existing mutableCopy] ?: [NSMutableData data];
            [output appendData:line];
            [output writeToURL:file options:NSDataWritingAtomic error:nil];
        } @catch (__unused NSException *exception) { }
    }
}

static BOOL SGOfflineSend(id self, SEL cmd, id name, id data, id owner, id completion, NSError **error) {
    // Always forward once, preserving every object, callback, error pointer, and return value.
    @try {
        if ([name isKindOfClass:NSString.class] && [name isEqualToString:@"OfflineError"] && [data isKindOfClass:NSData.class]) {
            int64_t code;
            if (SGOfflineErrorCode([data bytes], [data length], &code)) SGOfflineRecord(code);
        }
    } @catch (__unused NSException *exception) { }
    return sg_offlineOriginal(self, cmd, name, data, owner, completion, error);
}

static BOOL SGOfflineInstallClass(Class cls) {
    SEL sel = NSSelectorFromString(@"sendEventWithName:data:overrideOwner:persistenceCompletion:error:");
    Method method = class_getInstanceMethod(cls, sel);
    const char *types = method ? method_getTypeEncoding(method) : NULL;
    if (!types || strcmp(types, "B56@0:8@16@24@32@?40^@48") != 0) return NO;
    if (sg_offlineOriginal) return YES;
    sg_offlineOriginal = (SGOfflineSendIMP)method_getImplementation(method);
    method_setImplementation(method, (IMP)SGOfflineSend);
    return YES;
}

static BOOL SGOfflineGate(NSString *bundle, const char *enabled) {
    return enabled && strcmp(enabled, "1") == 0 && [bundle isEqualToString:@"com.kyle.spotipw.duo"];
}

__attribute__((constructor)) static void SGOfflineInit(void) {
    @autoreleasepool {
        const char *enabled = getenv("SPOTI_DUO_DOWNLOAD_DIAGNOSTICS");
        if (!SGOfflineGate(NSBundle.mainBundle.bundleIdentifier, enabled)) return;
        SGOfflineStatus(SGOfflineInstallClass(NSClassFromString(@"INSEventSender")));
    }
}
