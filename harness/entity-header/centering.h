#import "Redesigned/Kit/SGRHeaderInfo.h"

// A real metadata collection supplies the cells. Detaching it models the interval
// where Spotify's offscreen source cells are unavailable, without changing its data.
static void entityMetadataChecks(UIView *page, UIView *host, UIView *trigger,
                                 NSUInteger *checks, NSUInteger *failures) {
 NSMutableArray<UIView *> *queue=[NSMutableArray arrayWithObject:host];
 UIView *row=nil,*hero=nil;
 UICollectionView *cells=nil;
 UILabel *sourceTitle=nil,*sourceCreator=nil;
 SGRHeaderInfo *info=nil;
 while(queue.count) {
  UIView *v=queue.lastObject; [queue removeLastObject];
  if([v.accessibilityIdentifier isEqualToString:@"Components.UI.MetadataRow"]) row=v;
  if([v.accessibilityIdentifier isEqualToString:@"CreativeWorkPlatform.Components.UI.TitleRow-internal"]) sourceTitle=(UILabel *)v;
  if([v isKindOfClass:UILabel.class]) {
   for(UIView *parent=v.superview;parent && parent!=host;parent=parent.superview)
    if([parent.accessibilityIdentifier isEqualToString:@"CreativeWorkPlatform.Components.UI.ParentRow"]) sourceCreator=(UILabel *)v;
  }
  if([v isKindOfClass:SGRHeaderInfo.class]) info=(SGRHeaderInfo *)v;
  if([NSStringFromClass(v.class) hasSuffix:@"Hero"]) hero=v;
  [queue addObjectsFromArray:v.subviews];
 }
 for(UIView *v in row.subviews) if([v isKindOfClass:UICollectionView.class]) cells=(UICollectionView *)v;
 if(!cells) return; // Artist has no cell-backed album metadata.
 NSArray *originalItems=[(NSObject *)cells.dataSource valueForKey:@"items"];
 NSString *originalTitle=sourceTitle.text,*originalCreator=sourceCreator.text;
 UILabel *title=nil,*length=nil;
 for(UIView *v in info.subviews) {
  if(![v isKindOfClass:UILabel.class]) continue;
  if(v.accessibilityTraits & UIAccessibilityTraitHeader) title=(UILabel *)v;
  if([((UILabel *)v).text isEqualToString:[originalItems componentsJoinedByString:@" "]]) length=(UILabel *)v;
 }
 void (^layout)(void)=^{
  for(NSUInteger pass=0;pass<4;pass++) {
   [page setNeedsLayout]; [page layoutIfNeeded];
   [trigger setNeedsLayout]; [trigger layoutIfNeeded];
   [host setNeedsLayout]; [host layoutIfNeeded];
   [info setNeedsLayout]; [info layoutIfNeeded];
  }
 };
 void (^check)(NSString *,BOOL)=^(NSString *name,BOOL ok) {
  (*checks)++; if(!ok) (*failures)++;
  NSLog(@"[harness] metadata %@ -- %@",name,ok?@"PASS":@"FAIL");
 };
 // Let the native header settle taller after cells have arrived, so an earlier
 // loading-time hero maximum cannot hide a later erroneous growth.
 CGRect originalHostFrame=host.frame, settled=host.frame;
 settled.size.height+=40; host.frame=settled;
 layout();
 CGFloat titleY=title.frame.origin.y, contentHeight=[info contentHeightForWidth:info.bounds.size.width];
 CGFloat heroHeight=hero.bounds.size.height;
 check(@"fixture",sourceTitle && sourceCreator && title && length && !length.hidden && hero);
 [cells removeFromSuperview]; layout();
 check(@"unavailable cells preserve title/content/hero",!length.hidden && fabs(title.frame.origin.y-titleY)<0.51 &&
  fabs([info contentHeightForWidth:info.bounds.size.width]-contentHeight)<0.51 && fabs(hero.bounds.size.height-heroHeight)<0.51);
 NSLog(@"[harness] metadata disappearance deltas title=%.1f content=%.1f hero=%.1f",
  title.frame.origin.y-titleY,[info contentHeightForWidth:info.bounds.size.width]-contentHeight,hero.bounds.size.height-heroHeight);
 [row addSubview:cells]; [cells layoutIfNeeded]; layout();
 check(@"reappearance",!length.hidden && fabs(title.frame.origin.y-titleY)<0.51 && fabs(hero.bounds.size.height-heroHeight)<0.51);
 host.frame=originalHostFrame; layout();
 [(NSObject *)cells.dataSource setValue:@[@"Single",@"•",@"2026"] forKey:@"items"];
 [cells reloadData]; [cells layoutIfNeeded]; layout();
 check(@"fresh values replace cache",[length.text isEqualToString:@"Single • 2026"]);
 [cells removeFromSuperview]; sourceTitle.text=@"Another album"; layout();
 check(@"title reuse clears cache",length.hidden);
 [row addSubview:cells]; [cells layoutIfNeeded]; layout();
 check(@"reused header accepts fresh values",[length.text isEqualToString:@"Single • 2026"] && !length.hidden);
 [cells removeFromSuperview]; sourceCreator.text=@"Another artist"; layout();
 check(@"creator reuse clears cache",length.hidden);
 // Empty reads are not identity changes; a creator's first arrival is not reuse.
 UIView *parentRow=sourceCreator.superview;
 while(parentRow && ![parentRow.accessibilityIdentifier isEqualToString:@"CreativeWorkPlatform.Components.UI.ParentRow"]) parentRow=parentRow.superview;
 NSString *parentAccessibility=parentRow.accessibilityLabel;
 [row addSubview:cells]; [cells layoutIfNeeded]; layout();
 [cells removeFromSuperview]; sourceTitle.text=nil; sourceCreator.text=nil; parentRow.accessibilityLabel=nil; layout();
 check(@"temporary empty identity preserves metadata",!length.hidden && [length.text isEqualToString:@"Single • 2026"]);
 sourceTitle.text=@"Initially incomplete album"; layout();
 check(@"new identity without metadata starts empty",length.hidden);
 [row addSubview:cells]; [cells layoutIfNeeded]; layout();
 [cells removeFromSuperview]; sourceCreator.text=@"Late arriving artist"; layout();
 check(@"first creator arrival preserves metadata",!length.hidden && [length.text isEqualToString:@"Single • 2026"]);
 // A new source row is a confirmed replacement, unlike one temporarily absent.
 UIView *rowParent=row.superview;
 UIView *replacement=[[UIView alloc] initWithFrame:row.frame];
 replacement.accessibilityIdentifier=row.accessibilityIdentifier;
 [row removeFromSuperview]; [rowParent addSubview:replacement]; layout();
 check(@"replacement row without metadata starts empty",length.hidden);
 [replacement addSubview:cells]; [cells layoutIfNeeded]; layout();
 check(@"replacement row accepts metadata",!length.hidden && [length.text isEqualToString:@"Single • 2026"]);
 [replacement removeFromSuperview]; [rowParent addSubview:row];
 parentRow.accessibilityLabel=parentAccessibility;
 sourceTitle.text=originalTitle; sourceCreator.text=originalCreator;
 [(NSObject *)cells.dataSource setValue:originalItems forKey:@"items"];
 [row addSubview:cells]; [cells reloadData]; [cells layoutIfNeeded]; layout();
 host.frame=originalHostFrame; layout();
}

// Runs production album/artist hooks, not a duplicate of their frame calculation.
// Expected column comes independently from UIKit's page safe-area layout guide.
static void entityHeaderChecks(UIView *page, UIView *host, UIView *trigger) {
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.4*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
  UIWindow *window = page.window;
  CGRect original = window.frame, originalHost = host.frame;
  BOOL duo = window.safeAreaInsets.right > 60 || window.safeAreaInsets.left > 60;
  NSUInteger checks=0, failures=0;
  BOOL checkedHero=NO;
  NSArray *sizes = duo ? @[@466,@669,@951,@466] : @[@320,@402,@466,@320];
  for (NSNumber *width in sizes) {
   window.frame = CGRectMake(original.origin.x, original.origin.y, width.doubleValue, 678);
   window.rootViewController.view.frame = window.bounds;
   page.frame = window.bounds;
   for (UIView *ancestor=host.superview;ancestor && ancestor!=page;ancestor=ancestor.superview) {
    CGRect f=ancestor.frame; f.size.width=width.doubleValue; ancestor.frame=f;
   }
   [window layoutIfNeeded]; [page layoutIfNeeded];
   CGRect column = duo ? page.safeAreaLayoutGuide.layoutFrame : page.bounds;
   for (NSUInteger mode=0;mode<3;mode++) for (NSUInteger state=0;state<3;state++) {
    // A full-width host, a translated host, and one already inset to the rows.
    CGRect region = mode==2 ? column : page.bounds;
    if (mode==1) { region.origin.x += 13; region.size.width -= 13; }
    CGRect local = [host.superview convertRect:region fromView:page];
    host.frame = CGRectMake(local.origin.x, state==1 ? -200 : state==2 ? 30 : 0,
                            region.size.width, state==1 ? 220 : 568);
    for (NSUInteger pass=0;pass<4;pass++) {
     [page setNeedsLayout]; [page layoutIfNeeded];
     [trigger setNeedsLayout]; [trigger layoutIfNeeded];
     [host setNeedsLayout]; [host layoutIfNeeded];
    }
    UIView *info=nil;
    for (UIView *child in host.subviews) if ([NSStringFromClass(child.class) isEqualToString:@"SGRHeaderInfo"]) info=child;
    [info setNeedsLayout]; [info layoutIfNeeded];
    CGRect expected = duo ? CGRectIntersection(column,region) : region;
    CGRect actual = [page convertRect:info.bounds fromView:info];
    BOOL ok = info && fabs(actual.origin.x-expected.origin.x)<0.51 && fabs(actual.size.width-expected.size.width)<0.51;
    NSUInteger texts=0, buttons=0;
    CGRect controls=CGRectNull;
    for (UIView *child in info.subviews) {
     if (child.hidden) continue;
     CGRect f=[page convertRect:child.bounds fromView:child];
     BOOL text=[child isKindOfClass:UILabel.class] && ((UILabel *)child).textAlignment==NSTextAlignmentCenter;
     BOOL play=[NSStringFromClass(child.class) isEqualToString:@"SGRPlayCapsule"];
     BOOL button=play || [NSStringFromClass(child.class) isEqualToString:@"SGRMirrorButton"];
     if(text || play) ok &= fabs(CGRectGetMidX(f)-CGRectGetMidX(expected))<0.51;
     if(text) texts++;
     if(button) { buttons++; controls=CGRectUnion(controls,f); }
    }
    ok &= texts>=2 && buttons==3 && CGRectGetMinX(controls)>=CGRectGetMinX(expected) && CGRectGetMaxX(controls)<=CGRectGetMaxX(expected);
    if (!checkedHero) {
     checkedHero=YES;
     UIView *hero=nil; UILabel *title=nil;
     for (UIView *child in host.subviews) if ([NSStringFromClass(child.class) hasSuffix:@"Hero"]) hero=child;
     for (UIView *child in info.subviews) if ([child isKindOfClass:UILabel.class] && (child.accessibilityTraits & UIAccessibilityTraitHeader)) title=(UILabel *)child;
     CGFloat narrow=[title sizeThatFits:CGSizeMake(info.bounds.size.width-40,CGFLOAT_MAX)].height;
     CGFloat full=[title sizeThatFits:CGSizeMake(host.bounds.size.width-40,CGFLOAT_MAX)].height;
     BOOL heroOK=hero && title && fabs(hero.frame.size.width-host.bounds.size.width)<0.51
       && fabs(hero.frame.size.height-round(CGRectGetMinY(title.frame)+56))<0.51;
     if(duo) heroOK &= narrow > full;
     checks++; if(!heroOK) failures++;
     NSLog(@"[harness] wrapping hero narrow=%.1f full=%.1f hero=%.1f titleY=%.1f -- %@",narrow,full,hero.frame.size.height,title.frame.origin.y,heroOK?@"PASS":@"FAIL");
    }
    checks++; if(!ok) failures++;
    NSLog(@"[harness] entity centering width=%@ mode=%lu state=%lu info=%@ expected=%@ -- %@",width,(unsigned long)mode,(unsigned long)state,NSStringFromCGRect(actual),NSStringFromCGRect(expected),ok?@"PASS":@"FAIL");
   }
  }
  // Drive the existing UIScrollView, not merely three disconnected header frames.
  // Each 1pt sweep passes the quarter-scroll area, fully hides the header, and returns.
  UIScrollView *scroll=nil;
  for (UIView *v=host.superview;v;v=v.superview) {
   if ([v isKindOfClass:UIScrollView.class]) { scroll=(UIScrollView *)v; break; }
  }
  // Album's kind/date are collection cells, not durable model fields. Recycle them
  // mid-scroll without changing their data source, then let UIKit recreate them.
  UICollectionView *metadataCells=nil;
  NSMutableArray<UIView *> *queue=[NSMutableArray arrayWithObject:host];
  while (queue.count) {
   UIView *view=queue.lastObject; [queue removeLastObject];
   if ([view.accessibilityIdentifier isEqualToString:@"Components.UI.MetadataRow"]) {
    for (UIView *child in view.subviews) if ([child isKindOfClass:UICollectionView.class]) metadataCells=(UICollectionView *)child;
   }
   [queue addObjectsFromArray:view.subviews];
  }
  UIView *metadataContainer=metadataCells.superview;
  CGPoint oldOffset=scroll.contentOffset;
  CGFloat oldAlpha=host.alpha;
  NSUInteger scrollChecks=0, scrollFailures=0;
  for (NSNumber *width in sizes) for (NSUInteger collapse=0;collapse<2;collapse++) {
   window.frame=CGRectMake(original.origin.x,original.origin.y,width.doubleValue,678);
   window.rootViewController.view.frame=window.bounds;
   page.frame=window.bounds;
   for (UIView *v=host.superview;v && v!=page;v=v.superview) {
    CGRect frame=v.frame; frame.size.width=page.bounds.size.width; v.frame=frame;
   }
   host.frame=CGRectMake(0,0,page.bounds.size.width,568);
   CGRect baseline=CGRectNull;
   CGFloat heroHeight=0;
   CGSize contentSize=scroll.contentSize;
   UIEdgeInsets contentInset=scroll.contentInset;
   for (NSInteger step=0;step<=1800;step++) {
    CGFloat offset=step<=900 ? step : 1800-step;
    CGFloat shrink=collapse ? MIN(offset,488) : 0;
    scroll.contentOffset=CGPointMake(0,offset);
    host.alpha=MAX(0,1-offset/200);
    if (offset>=200) [metadataCells removeFromSuperview];
    else if(metadataCells && !metadataCells.superview) [metadataContainer addSubview:metadataCells];
    [metadataCells layoutIfNeeded];
    CGRect frame=host.frame; frame.size.height=568-shrink; host.frame=frame;
    // Let UIKit deliver deferred safe-area/layout updates as well as synchronous passes.
    if (step%30==0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    [window layoutIfNeeded];
    [page setNeedsLayout]; [page layoutIfNeeded];
    [trigger setNeedsLayout]; [trigger layoutIfNeeded];
    [host setNeedsLayout]; [host layoutIfNeeded];
    UIView *info=nil,*hero=nil;
    for (UIView *v in host.subviews) {
     if ([NSStringFromClass(v.class) isEqualToString:@"SGRHeaderInfo"]) info=v;
     if ([NSStringFromClass(v.class) hasSuffix:@"Hero"]) hero=v;
    }
    [info setNeedsLayout]; [info layoutIfNeeded];
    UILabel *title=nil;
    for (UIView *v in info.subviews) {
     if ([v isKindOfClass:UILabel.class] && (v.accessibilityTraits & UIAccessibilityTraitHeader)) title=(UILabel *)v;
    }
    CGRect actual=[host convertRect:title.bounds fromView:title];
    if (step==0) { baseline=actual; heroHeight=hero.bounds.size.height; }
    BOOL ok=scroll && info && title && hero
      && fabs(actual.origin.x-baseline.origin.x)<0.51
      && fabs(actual.size.width-baseline.size.width)<0.51
      && fabs(actual.size.height-baseline.size.height)<0.51
      && fabs(actual.origin.y-(baseline.origin.y-shrink))<0.51
      && fabs(hero.bounds.size.height-heroHeight)<0.51
      && fabs(scroll.contentOffset.y-offset)<0.51
      && CGSizeEqualToSize(scroll.contentSize,contentSize)
      && UIEdgeInsetsEqualToEdgeInsets(scroll.contentInset,contentInset);
    scrollChecks++;
    if (!ok) {
     scrollFailures++;
     if (scrollFailures<6) NSLog(@"[harness] scroll width=%@ collapse=%lu offset=%.0f safe=%@ title=%@ baseline=%@ hero=%.1f/%.1f -- FAIL",
       width,(unsigned long)collapse,offset,NSStringFromUIEdgeInsets(host.safeAreaInsets),
       NSStringFromCGRect(actual),NSStringFromCGRect(baseline),hero.bounds.size.height,heroHeight);
    }
   }
  }
  if(metadataCells && !metadataCells.superview) [metadataContainer addSubview:metadataCells];
  [metadataCells layoutIfNeeded];
  scroll.contentOffset=oldOffset;
  host.alpha=oldAlpha;
  checks+=scrollChecks; failures+=scrollFailures;
  NSLog(@"[harness] continuous scroll: %lu cases, %lu failures -- %@",
    (unsigned long)scrollChecks,(unsigned long)scrollFailures,scrollFailures?@"FAIL":@"PASS");
  entityMetadataChecks(page,host,trigger,&checks,&failures);
  window.frame=original; host.frame=originalHost;
  NSLog(@"[harness] entity centering checks: %lu cases, %lu failures -- %@",(unsigned long)checks,(unsigned long)failures,failures?@"FAIL":@"PASS");
 });
}
