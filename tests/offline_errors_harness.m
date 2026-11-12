#import <Foundation/Foundation.h>
#import <assert.h>
#define SG_OFFLINE_TESTING 1
#import "../tweak/Sources/Diagnostics/OfflineErrors.m"
static BOOL originalReturn; static unsigned calls; static id wantName, wantData, wantOwner, wantCompletion; static NSError *__autoreleasing *wantError;
static BOOL original(id self, SEL cmd, id name, id data, id owner, id completion, NSError **error) {
    assert(name == wantName && data == wantData && owner == wantOwner && completion == wantCompletion && error == wantError);
    calls++; return originalReturn;
}
static void parseTests(void) {
    int64_t code = 123;
    uint8_t fixture7028[] = {8,244,54};
    assert(SGOfflineErrorCode(fixture7028,sizeof fixture7028,&code) && code==7028);
    uint8_t good[] = {8, 42, 18, 6, 's','e','c','r','e','t', 26, 2, 'i','d', 34, 3, 'p','i','i'};
    assert(SGOfflineErrorCode(good, sizeof good, &code) && code == 42);
    uint8_t negative[] = {8,255,255,255,255,255,255,255,255,255,1};
    assert(SGOfflineErrorCode(negative,sizeof negative,&code) && code == -1);
    uint8_t minimum[] = {8,128,128,128,128,128,128,128,128,128,1};
    assert(SGOfflineErrorCode(minimum,sizeof minimum,&code) && code == INT64_MIN);
    uint8_t duplicate[] = {8,1,8,2}, wrong[] = {10,1,0}, overflow[] = {8,255,255,255,255,255,255,255,255,255,2};
    uint8_t truncated[] = {8,1,18,3,'x'}, noCode[] = {18,1,'x'}, group[] = {8,1,19};
    assert(!SGOfflineErrorCode(duplicate,sizeof duplicate,&code));
    assert(!SGOfflineErrorCode(wrong,sizeof wrong,&code));
    assert(!SGOfflineErrorCode(overflow,sizeof overflow,&code));
    assert(!SGOfflineErrorCode(truncated,sizeof truncated,&code));
    assert(!SGOfflineErrorCode(noCode,sizeof noCode,&code));
    assert(!SGOfflineErrorCode(group,sizeof group,&code));
    assert(!SGOfflineErrorCode(negative,sizeof negative-1,&code));
    assert(!SGOfflineErrorCode(NULL,0,&code));
    uint8_t *huge = calloc(65537,1); assert(!SGOfflineErrorCode(huge,65537,&code)); free(huge);
    code=876; assert(!SGOfflineErrorCode(truncated,sizeof truncated,&code) && code==876);
}
int main(void) { @autoreleasepool {
    parseTests();
    // No such class in this standalone process: fail closed on ABI discovery.
    assert(!SGOfflineInstallClass(Nil));
    Class fake = objc_allocateClassPair(NSObject.class, "INSEventSender", 0);
    SEL selector = NSSelectorFromString(@"sendEventWithName:data:overrideOwner:persistenceCompletion:error:");
    class_addMethod(fake, selector, (IMP)original, "v16@0:8");
    objc_registerClassPair(fake);
    assert(!SGOfflineInstallClass(fake));
    assert(SGOfflineGate(@"com.kyle.spotipw.duo", "1"));
    assert(!SGOfflineGate(@"com.spotify.client", "1"));
    assert(!SGOfflineGate(@"com.kyle.spotipw.duo.extra", "1"));
    assert(!SGOfflineGate(nil, "1"));
    for (NSString *bundle in @[@"com.kyle.spotipw.duo", @"com.spotify.client"]) {
        assert(!SGOfflineGate(bundle, NULL));
        assert(!SGOfflineGate(bundle, ""));
        assert(!SGOfflineGate(bundle, "0"));
        assert(!SGOfflineGate(bundle, "true"));
        assert(!SGOfflineGate(bundle, "1 "));
    }
    Class valid = objc_allocateClassPair(NSObject.class, "SGTestValidEventSender", 0);
    class_addMethod(valid, selector, (IMP)original, "B56@0:8@16@24@32@?40^@48");
    objc_registerClassPair(valid);
    assert(SGOfflineInstallClass(valid));
    SGOfflineSendIMP installed = (SGOfflineSendIMP)class_getMethodImplementation(valid, selector);
    assert(installed == SGOfflineSend && sg_offlineOriginal == original);
    id receiver = [valid new];
    wantOwner = [NSObject new]; wantCompletion = [^{ abort(); } copy];
    NSError *__autoreleasing sentinel = [NSError errorWithDomain:@"test" code:7 userInfo:nil];
    wantError = &sentinel;
    wantName = @"OfflineError"; wantData = [NSData dataWithBytes:"\x08\x80" length:2];
    BOOL result = installed(receiver, selector, wantName, wantData, wantOwner, wantCompletion, wantError);
    assert(!result && calls==1 && sentinel.code==7);
    wantName = @"UnrelatedEvent"; wantData = [NSData dataWithBytes:"\x08\x01" length:2];
    originalReturn = YES;
    result = installed(receiver,selector,wantName,wantData,wantOwner,wantCompletion,wantError);
    assert(result && calls==2 && sentinel.code==7);
    NSURL *temp = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString] isDirectory:YES];
    sg_offlineTestDocuments = temp;
    SGOfflineStatus(NO);
    NSURL *statusURL = [temp URLByAppendingPathComponent:@"SpotiDuoDiagnostics/status.json"];
    NSDictionary *status = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:statusURL] options:0 error:nil];
    assert(status.count == 2 && [status[@"status"] isEqual:@"unsupported_runtime_signature"]);
    SGOfflineStatus(YES);
    status = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:statusURL] options:0 error:nil];
    assert(status.count == 2 && [status[@"status"] isEqual:@"installed"] && [status[@"monotonic_seconds"] doubleValue] > 0);
    for (int i=0;i<105;i++) SGOfflineRecord(7028);
    NSString *lines = [NSString stringWithContentsOfURL:[temp URLByAppendingPathComponent:@"SpotiDuoDiagnostics/offline-errors.jsonl"] encoding:NSUTF8StringEncoding error:nil];
    NSArray *records = [lines componentsSeparatedByString:@"\n"];
    assert(records.count == 101);
    for (NSUInteger i=0;i<100;i++) {
        NSDictionary *record = [NSJSONSerialization JSONObjectWithData:[records[i] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        assert(record.count == 2 && [record[@"error_code"] longLongValue] == 7028 && record[@"monotonic_seconds"]);
    }
    [NSFileManager.defaultManager removeItemAtURL:temp error:nil];
    puts("Offline error parser + forwarding + persistence tests passed");
} }
