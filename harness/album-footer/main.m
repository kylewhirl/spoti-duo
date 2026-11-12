#import <UIKit/UIKit.h>
#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRKit.h"
#import "Redesigned/Album/Album.h"
// No override of preferredLayoutAttributesFittingAttributes: UIKit supplies %orig.
// The optional reuse-reset fixture models an original implementation that changes state;
// it is not an assertion about which defaults Spotify currently chooses on reuse.
static char kNativeReuseResetKey;
static void nativeReuseReset(UICollectionViewCell *cell) {
 if(![objc_getAssociatedObject(cell,&kNativeReuseResetKey) boolValue]) return;
 cell.contentView.autoresizingMask=UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin;
 cell.contentView.hidden=NO; cell.clipsToBounds=NO; cell.accessibilityElementsHidden=NO;
}
@interface NativeReuseControlCell : UICollectionViewCell @end
@implementation NativeReuseControlCell
- (void)prepareForReuse { [super prepareForReuse]; nativeReuseReset(self); }
@end
@interface _TtC12Element_List18CollectionViewCell : UICollectionViewCell @end
@implementation _TtC12Element_List18CollectionViewCell
- (void)prepareForReuse { [super prepareForReuse]; nativeReuseReset(self); }
@end
@interface MockAlbum_PageImpl20FooterStructuredDataView : UIView @end
@implementation MockAlbum_PageImpl20FooterStructuredDataView @end
BOOL SGRedesignedUI(void) { return YES; }
void SGRequireClasses(NSArray<NSString *> *classes) {}
UIColor *SGRTertiary(void) { return UIColor.grayColor; }
UIView *SGRAlbumPageOf(UIView *v) { for(;v;v=v.superview) if([v.accessibilityIdentifier isEqualToString:@"fixture-page"]) return v; return nil; }
UIView *SGRFindByIdentifier(UIView *root,NSString *identifier,const void *key) {
 if([root.accessibilityIdentifier isEqualToString:identifier]) return root;
 for(UIView *child in root.subviews) { UIView *found=SGRFindByIdentifier(child,identifier,key); if(found)return found; }
 return nil;
}
static UICollectionViewCell *makeCell(UIView *page,BOOL hooked,BOOL constraints,BOOL kept) {
 Class cls=hooked ? _TtC12Element_List18CollectionViewCell.class : NativeReuseControlCell.class;
 UICollectionViewCell *cell=[[cls alloc] initWithFrame:CGRectMake(0,0,320,40)];
 [page addSubview:cell];
 UIView *root=[[MockAlbum_PageImpl20FooterStructuredDataView alloc] initWithFrame:cell.contentView.bounds];
 if(kept) root.accessibilityIdentifier=@"Album.Copyright";
 [cell.contentView addSubview:root];
 UILabel *label=[[UILabel alloc] initWithFrame:CGRectInset(root.bounds,8,8)];
 label.text=@"Copyright example with enough words to occupy several lines in a constrained footer.";
 label.numberOfLines=0; label.font=[UIFont systemFontOfSize:14]; [root addSubview:label];
 if(constraints) {
  root.translatesAutoresizingMaskIntoConstraints=NO; label.translatesAutoresizingMaskIntoConstraints=NO;
  [NSLayoutConstraint activateConstraints:@[
   [root.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
   [root.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor],
   [root.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
   [root.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
   [label.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:8],
   [label.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-8],
   [label.topAnchor constraintEqualToAnchor:root.topAnchor constant:8],
   [label.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-8]]];
 } else root.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
 return cell;
}
static NSUInteger checks,failures;
static void check(BOOL ok,NSString *name) { checks++; if(!ok)failures++; NSLog(@"CHECK %@ %@",ok?@"PASS":@"FAIL",name); }
static UILabel *labelOf(UICollectionViewCell *cell) { return (UILabel *)cell.contentView.subviews.firstObject.subviews.firstObject; }
static UICollectionViewLayoutAttributes *attributes(CGSize size) {
 UICollectionViewLayoutAttributes *a=[UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
 a.frame=(CGRect){CGPointZero,size}; return a;
}
static void apply(UICollectionViewCell *cell,UICollectionViewLayoutAttributes *a) {
 [cell applyLayoutAttributes:a]; cell.frame=a.frame; [cell setNeedsLayout]; [cell layoutIfNeeded];
}
static void run(UIView *page) {
 for(NSUInteger constrained=0;constrained<2;constrained++) for(NSUInteger kept=0;kept<2;kept++) {
  UICollectionViewCell *control=makeCell(page,NO,constrained,kept),*hook=makeCell(page,YES,constrained,kept);
  UICollectionViewLayoutAttributes *ca=attributes(control.bounds.size),*ha=attributes(hook.bounds.size);
  for(NSUInteger pass=0;pass<12;pass++) {
   if(pass==4 || pass==8) {
    CGFloat width=pass==4 ? 180 : 420;
    CGSize cs=ca.size,hs=ha.size; cs.width=width; hs.width=width; ca.size=cs; ha.size=hs;
    NSString *text=pass==4 ? @"A changed copyright message with substantially more text that must expand across multiple lines at the narrower width." : @"Short text";
    labelOf(control).text=text; labelOf(hook).text=text;
   }
   apply(control,ca); apply(hook,ha);
   CGFloat incoming=ha.size.height;
   UICollectionViewLayoutAttributes *native=[control preferredLayoutAttributesFittingAttributes:[ca copy]];
   UICollectionViewLayoutAttributes *actual=[hook preferredLayoutAttributesFittingAttributes:[ha copy]];
   NSString *phase=[NSString stringWithFormat:@"constraints=%lu kept=%lu pass=%lu",(unsigned long)constrained,(unsigned long)kept,(unsigned long)pass];
   check(fabs(actual.size.height-(kept ? native.size.height : 0))<0.01,[phase stringByAppendingString:@" preferred height"]);
   if(kept) {
    check(CGRectEqualToRect(hook.contentView.frame,control.contentView.frame),[phase stringByAppendingString:@" native content frame"]);
    check(!hook.contentView.hidden && !hook.accessibilityElementsHidden,[phase stringByAppendingString:@" visible/accessibility"]);
    check([labelOf(hook).textColor isEqual:SGRTertiary()],[phase stringByAppendingString:@" style retained"]);
   } else check(hook.contentView.hidden && hook.clipsToBounds && hook.accessibilityElementsHidden,[phase stringByAppendingString:@" dropped concealed"]);
   NSLog(@"NUMERIC constraints=%lu kept=%lu pass=%lu input=%.3f native=%.3f hook=%.3f",(unsigned long)constrained,(unsigned long)kept,(unsigned long)pass,incoming,native.size.height,actual.size.height);
   ca=[native copy]; ha=[actual copy];
  }
  [control removeFromSuperview]; [hook removeFromSuperview];
 }
 // Reuse both with and without prepareForReuse; the preferred-fit guard must restore stale
 // dropped state before UIKit measures the replacement kept/nonfooter content.
 for(NSUInteger constrained=0;constrained<2;constrained++) for(NSUInteger prepare=0;prepare<2;prepare++) for(NSUInteger footer=0;footer<2;footer++) {
  UICollectionViewCell *hook=makeCell(page,YES,constrained,NO);
  [hook preferredLayoutAttributesFittingAttributes:attributes(hook.bounds.size)];
  if(prepare) [hook prepareForReuse];
  UIView *root=hook.contentView.subviews.firstObject;
  if(footer) root.accessibilityIdentifier=@"Album.Copyright";
  else {
   // Keep the same subtree/constraints but use the class of plain nonfooter content.
   object_setClass(root,UIView.class);
  }
  UICollectionViewCell *control=makeCell(page,NO,constrained,footer);
  CGRect frame=CGRectMake(0,0,240,55); hook.frame=frame; control.frame=frame;
  UICollectionViewLayoutAttributes *ha=attributes(frame.size),*ca=attributes(frame.size);
  for(NSUInteger pass=0;pass<3;pass++) {
   apply(hook,ha); apply(control,ca);
   UICollectionViewLayoutAttributes *actual=[hook preferredLayoutAttributesFittingAttributes:[ha copy]],*native=[control preferredLayoutAttributesFittingAttributes:[ca copy]];
   NSString *phase=[NSString stringWithFormat:@"reuse constraints=%lu prepare=%lu footer=%lu pass=%lu",(unsigned long)constrained,(unsigned long)prepare,(unsigned long)footer,(unsigned long)pass];
   check(fabs(actual.size.height-native.size.height)<0.01,[phase stringByAppendingString:@" native height"]);
   check(!hook.contentView.hidden && !hook.accessibilityElementsHidden,[phase stringByAppendingString:@" restored visibility"]);
   check(fabs(hook.contentView.frame.origin.y-control.contentView.frame.origin.y)<0.01,[phase stringByAppendingString:@" native origin"]);
   ha=[actual copy]; ca=[native copy];
  }
  [hook removeFromSuperview]; [control removeFromSuperview];
 }
 // Recovery before UIKit applies fresh nonzero attributes: both cells remain zero-height.
 // Include native nondefault state; compare the same call sequence, not assumed defaults.
 for(NSUInteger constrained=0;constrained<2;constrained++) for(NSUInteger prepare=0;prepare<2;prepare++)
 for(NSUInteger footer=0;footer<2;footer++) for(NSUInteger custom=0;custom<2;custom++) {
  UICollectionViewCell *hook=makeCell(page,YES,constrained,NO),*control=makeCell(page,NO,constrained,NO);
  if(custom) for(UICollectionViewCell *cell in @[hook,control]) {
   cell.contentView.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
   cell.contentView.hidden=YES; cell.clipsToBounds=YES; cell.accessibilityElementsHidden=YES;
  }
  [hook preferredLayoutAttributesFittingAttributes:attributes(hook.bounds.size)];
  [control preferredLayoutAttributesFittingAttributes:attributes(control.bounds.size)];
  apply(hook,attributes(CGSizeMake(320,0))); apply(control,attributes(CGSizeMake(320,0)));
  if(prepare) { [hook prepareForReuse]; [control prepareForReuse]; }
  for(UICollectionViewCell *cell in @[hook,control]) {
   UIView *root=cell.contentView.subviews.firstObject;
   if(footer) root.accessibilityIdentifier=@"Album.Copyright"; else object_setClass(root,UIView.class);
  }
  check(hook.bounds.size.height==0 && control.bounds.size.height==0,@"zero-height recovery fixture");
  UICollectionViewLayoutAttributes *ha=attributes(CGSizeMake(320,55)),*ca=[ha copy];
  for(NSUInteger pass=0;pass<3;pass++) {
   UICollectionViewLayoutAttributes *actual=[hook preferredLayoutAttributesFittingAttributes:[ha copy]],*native=[control preferredLayoutAttributesFittingAttributes:[ca copy]];
   NSString *phase=[NSString stringWithFormat:@"zero recovery constraints=%lu prepare=%lu footer=%lu custom=%lu pass=%lu",(unsigned long)constrained,(unsigned long)prepare,(unsigned long)footer,(unsigned long)custom,(unsigned long)pass];
   check(fabs(actual.size.height-native.size.height)<0.01,[phase stringByAppendingString:@" native height"]);
   check(CGRectEqualToRect(hook.contentView.frame,control.contentView.frame),[phase stringByAppendingString:@" native content frame"]);
   check(hook.contentView.autoresizingMask==control.contentView.autoresizingMask,[phase stringByAppendingString:@" native autoresizing"]);
   check(hook.contentView.hidden==control.contentView.hidden,[phase stringByAppendingString:@" native visibility"]);
   check(hook.clipsToBounds==control.clipsToBounds,[phase stringByAppendingString:@" native clipping"]);
   check(hook.accessibilityElementsHidden==control.accessibilityElementsHidden,[phase stringByAppendingString:@" native accessibility"]);
   NSLog(@"ZERO RECOVERY constraints=%lu prepare=%lu footer=%lu custom=%lu pass=%lu native=%.3f hook=%.3f",(unsigned long)constrained,(unsigned long)prepare,(unsigned long)footer,(unsigned long)custom,(unsigned long)pass,native.size.height,actual.size.height);
   ha=[actual copy]; ca=[native copy]; apply(hook,ha); apply(control,ca);
  }
  [hook removeFromSuperview]; [control removeFromSuperview];
 }
 // An original prepareForReuse that resets flags must have final say after cleanup.
 for(NSUInteger constrained=0;constrained<2;constrained++) for(NSUInteger footer=0;footer<2;footer++) {
  UICollectionViewCell *hook=makeCell(page,YES,constrained,NO),*control=makeCell(page,NO,constrained,NO);
  for(UICollectionViewCell *cell in @[hook,control]) {
   cell.contentView.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
   cell.contentView.hidden=YES; cell.clipsToBounds=YES; cell.accessibilityElementsHidden=YES;
   objc_setAssociatedObject(cell,&kNativeReuseResetKey,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  [hook preferredLayoutAttributesFittingAttributes:attributes(hook.bounds.size)];
  [control preferredLayoutAttributesFittingAttributes:attributes(control.bounds.size)];
  apply(hook,attributes(CGSizeMake(320,0))); apply(control,attributes(CGSizeMake(320,0)));
  [hook prepareForReuse]; [control prepareForReuse];
  for(UICollectionViewCell *cell in @[hook,control]) {
   UIView *root=cell.contentView.subviews.firstObject;
   if(footer) root.accessibilityIdentifier=@"Album.Copyright"; else object_setClass(root,UIView.class);
  }
  UICollectionViewLayoutAttributes *actual=[hook preferredLayoutAttributesFittingAttributes:attributes(CGSizeMake(320,55))];
  UICollectionViewLayoutAttributes *native=[control preferredLayoutAttributesFittingAttributes:attributes(CGSizeMake(320,55))];
  check(fabs(actual.size.height-native.size.height)<0.01,@"native reuse reset preserves fitting");
  check(hook.contentView.autoresizingMask==control.contentView.autoresizingMask,@"native reuse reset wins autoresizing");
  check(hook.contentView.hidden==control.contentView.hidden,@"native reuse reset wins visibility");
  check(hook.clipsToBounds==control.clipsToBounds,@"native reuse reset wins clipping");
  check(hook.accessibilityElementsHidden==control.accessibilityElementsHidden,@"native reuse reset wins accessibility");
  [hook removeFromSuperview]; [control removeFromSuperview];
 }
 NSLog(@"FOOTER SIZING CHECKS: %lu checks, %lu failures -- %@",(unsigned long)checks,(unsigned long)failures,failures?@"FAIL":@"PASS");
}
@interface App:UIResponder<UIApplicationDelegate,UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation App
- (UISceneConfiguration *)application:(UIApplication *)app configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
 UISceneConfiguration *c=[[UISceneConfiguration alloc] initWithName:@"Footer" sessionRole:session.role]; c.delegateClass=self.class; return c;
}
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
 self.window=[[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
 UIViewController *vc=[UIViewController new]; vc.view.accessibilityIdentifier=@"fixture-page";
 self.window.rootViewController=vc; [self.window makeKeyAndVisible];
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{run(vc.view);});
}
@end
int main(int argc,char **argv) { @autoreleasepool {return UIApplicationMain(argc,argv,nil,NSStringFromClass(App.class));} }
