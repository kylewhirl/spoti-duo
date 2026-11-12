// Temporary diagnostic candidate only. Numeric counters/geometry, no text, identifiers,
// view hierarchy, images, audio, input, tokens or network transmission. No behavioral fixes.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <stdatomic.h>
#import <mach/mach_time.h>
#import "Core/SGCore.h"

#ifndef SG_ARTIST_LAYOUT_DIAGNOSTICS
#define SG_ARTIST_LAYOUT_DIAGNOSTICS 0
#endif
#if SG_ARTIST_LAYOUT_DIAGNOSTICS
#ifndef SG_ARTIST_LAYOUT_DIAGNOSTIC_SECONDS
#define SG_ARTIST_LAYOUT_DIAGNOSTIC_SECONDS 180
#endif

enum { HeaderEnter, HeaderExit, ForegroundEnter, ForegroundExit, TemplateEnter,
       TemplateExit, BarEnter, BarExit, NavigationEnter, NavigationExit,
       TitleWrites, EqualTitleWrites, StandardWrites, EqualStandardWrites,
       EdgeWrites, EqualEdgeWrites, HeaderReentry, BarReentry, MainBeats, Count };
static _Atomic(uint64_t) counts[Count];
static _Atomic(int64_t) geometry[8];
static NSString *const names[Count] = {@"header_enter",@"header_exit",@"foreground_enter",@"foreground_exit",
 @"template_enter",@"template_exit",@"bar_enter",@"bar_exit",@"navigation_enter",@"navigation_exit",
 @"title_writes",@"equal_title_writes",@"standard_writes",@"equal_standard_writes",
 @"edge_writes",@"equal_edge_writes",@"header_reentry",@"bar_reentry",@"main_beats"};
static _Atomic(BOOL) active;
static BOOL started;
static NSUInteger headerDepth, barDepth;
static __weak UINavigationItem *trackedItem;
static __weak UINavigationController *trackedNavigation;
static dispatch_source_t timer;
static inline void tick(int key) { atomic_fetch_add_explicit(&counts[key], 1, memory_order_relaxed); }
static inline void number(int key, CGFloat n) {
 if (isfinite(n)) atomic_store_explicit(&geometry[key], llround(n*1000), memory_order_relaxed);
}
static void snapshotHeader(UIView *v) {
 number(0,v.bounds.size.width);number(1,v.bounds.size.height);
 number(2,v.safeAreaInsets.top);number(3,v.safeAreaInsets.bottom);
}
static BOOL artist(UIView *v) {
 for(;v;v=v.superview) if([v.accessibilityIdentifier isEqualToString:@"creator-page"])return YES;
 return NO;
}
static void begin(void) {
 if (started) return;
 started=YES;active=YES;
 dispatch_queue_t queue=dispatch_queue_create("com.kyle.spoti.artist-layout-diagnostic",DISPATCH_QUEUE_SERIAL);
 // Construct the app-owned local path on main, never access UIKit from the writer queue.
 NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
 NSURL *directory=[documents URLByAppendingPathComponent:@"SpotiDuoDiagnostics" isDirectory:YES];
 NSString *filename=[NSString stringWithFormat:@"artist-layout-%llu.jsonl",(unsigned long long)(NSDate.date.timeIntervalSince1970*1000)];
 NSURL *url=[directory URLByAppendingPathComponent:filename];
 timer=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,queue);
 dispatch_source_set_timer(timer,dispatch_time(DISPATCH_TIME_NOW,0),NSEC_PER_SEC,100*NSEC_PER_MSEC);
 const uint64_t began=mach_continuous_time();
 mach_timebase_info_data_t scale;mach_timebase_info(&scale);
 const long double ticksPerSecond=(long double)NSEC_PER_SEC*scale.denom/scale.numer;
 __block NSFileHandle *file;
 void (^stop)(void)=^{atomic_store_explicit(&active,NO,memory_order_relaxed);dispatch_source_cancel(timer);};
 dispatch_source_set_cancel_handler(timer,^{@try{[file closeFile];}@catch(__unused NSException *e){}file=nil;});
 dispatch_source_set_event_handler(timer,^{ @autoreleasepool {
  const uint64_t elapsed=mach_continuous_time()-began;
  if(elapsed/ticksPerSecond>=SG_ARTIST_LAYOUT_DIAGNOSTIC_SECONDS){stop();return;}
  if (!file) {
   if (![NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:nil]) {stop();return;}
   if (![NSFileManager.defaultManager createFileAtPath:url.path contents:nil attributes:nil]) {stop();return;}
   file=[NSFileHandle fileHandleForWritingAtPath:url.path];
   if (!file) {stop();return;}
  }
  NSMutableDictionary *row=[NSMutableDictionary dictionaryWithDictionary:@{@"schema":@1,@"build":@"artist-layout-diag-v1",@"seconds":@((double)(elapsed/ticksPerSecond))}];
  for (int i=0;i<Count;i++) row[names[i]]=@(atomic_load_explicit(&counts[i],memory_order_relaxed));
  NSMutableArray *g=[NSMutableArray new];
  for (int i=0;i<8;i++) [g addObject:@(atomic_load_explicit(&geometry[i],memory_order_relaxed)/1000.0)];
  row[@"geometry"] = g; // header width,height,safe top,bottom; nav-bar width,height,y; reserved.
  NSData *data=[NSJSONSerialization dataWithJSONObject:row options:NSJSONWritingSortedKeys error:nil];
  @try {if (data) {[file writeData:data];[file writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];}}
  @catch (__unused NSException *e) {stop();return;}
  // One outstanding heartbeat maximum, so a hung main thread cannot accumulate blocks.
  static _Atomic(BOOL) beatPending;
  if (!atomic_exchange_explicit(&beatPending,YES,memory_order_relaxed))
   dispatch_async(dispatch_get_main_queue(),^{tick(MainBeats);atomic_store_explicit(&beatPending,NO,memory_order_relaxed);});
 }});
 dispatch_resume(timer);
}
static void trackNavigation(UIView *v) {
 if (trackedNavigation) return;
 for (UIResponder *r=v.nextResponder;r;r=r.nextResponder) if ([r isKindOfClass:UIViewController.class]) {
  UINavigationController *nav=((UIViewController *)r).navigationController;
  if (nav) {trackedNavigation=nav;trackedItem=nav.topViewController.navigationItem;return;}
 }
}
static BOOL item(id obj) {return active && NSThread.isMainThread && (obj==trackedItem || headerDepth>0);}

%hook _TtC35CreativeWorkPlatform_ImageHeaderKit15ImageHeaderView
- (void)layoutSubviews {
 if(!started && artist((UIView *)self))begin();
 if(!active){%orig;return;}
 trackNavigation((UIView *)self);tick(HeaderEnter);if (headerDepth++)tick(HeaderReentry);
 if (active) snapshotHeader((UIView *)self);
 %orig;
 headerDepth--;tick(HeaderExit);
}
%end
%hook _TtC28EncoreConsumerMobile_BaseKit20HeaderForegroundView
- (void)layoutSubviews {if(active)tick(ForegroundEnter);%orig;if(active)tick(ForegroundExit);}
%end
%hook _TtC32CreativeWorkPlatform_TemplateKit12TemplateView
- (void)layoutSubviews {if(active)tick(TemplateEnter);%orig;if(active)tick(TemplateExit);}
%end
%hook SPNavigationBar
- (void)layoutSubviews {
 UIView *view=(UIView *)self;BOOL tracked=active && (id)self==trackedNavigation.navigationBar;
 if(tracked){tick(BarEnter);if(barDepth++)tick(BarReentry);number(4,view.bounds.size.width);number(5,view.bounds.size.height);number(6,view.frame.origin.y);}
 %orig;
 if(tracked){barDepth--;tick(BarExit);}
}
%end
%hook SPNavigationController
- (void)viewDidLayoutSubviews {BOOL tracked=active && (id)self==trackedNavigation;if(tracked)tick(NavigationEnter);%orig;if(tracked)tick(NavigationExit);}
%end
%hook UINavigationItem
- (void)setTitle:(NSString *)value {if(item(self)){trackedItem=self;tick(TitleWrites);if(self.title==value || [self.title isEqualToString:value])tick(EqualTitleWrites);}%orig;}
- (void)setStandardAppearance:(UINavigationBarAppearance *)value {if(item(self)){tick(StandardWrites);if(self.standardAppearance==value || [self.standardAppearance isEqual:value])tick(EqualStandardWrites);}%orig;}
- (void)setScrollEdgeAppearance:(UINavigationBarAppearance *)value {if(item(self)){tick(EdgeWrites);if(self.scrollEdgeAppearance==value || [self.scrollEdgeAppearance isEqual:value])tick(EqualEdgeWrites);}%orig;}
%end
%ctor {if(SGRedesignedUI()){%init;}}
#endif
