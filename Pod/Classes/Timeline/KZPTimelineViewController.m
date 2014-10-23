//
//  Created by Krzysztof Zabłocki(http://twitter.com/merowing_) on 19/10/14.
//
//
//


#import "KZPTimelineViewController.h"
#import "KZPSnapshotView.h"
#import "KZPPlayground.h"
@import ObjectiveC.runtime;

#import <objc/runtime.h>

static const NSInteger kVerticalMargin = 10;
static const NSInteger kHorizontalMargin = 10;
static const NSInteger kInfoButtonMargin = 10;

static const void *kSnapshotViewKey = &kSnapshotViewKey;

static KZPTimelineViewController *_singleton = nil;

@interface KZPTimelineViewController ()
@property(weak, nonatomic) IBOutlet UILabel *tickLabel;
@property(nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property(nonatomic, strong) NSMutableArray *snapshotViews;
@property(nonatomic, strong) UIPopoverController *currentPopoverController;
@end

@implementation KZPTimelineViewController

+ (KZPTimelineViewController *)sharedInstance
{
  NSAssert(_singleton, @"KZPTimelineViewController has to be loaded before it's active instance is referenced.");
  return _singleton;
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  _singleton = self;
  self.snapshotViews = [NSMutableArray new];
}

- (void)addView:(UIView *)view
{
  if(!view) {
    KZPShow(@"nil argument");
    return;
  }
  
  //! TODO: layouting will be in separate pass inside run when I add dynamic-resizing timeline
  UIView *lastView = [self.snapshotViews lastObject];
  CGFloat maxY = CGRectGetMaxY(lastView.frame);
  CGFloat width = CGRectGetWidth(view.bounds);
  if (width < 1) {
    KZPShow(@"View size %@", NSStringFromCGSize(view.bounds.size));
    return;
  }
  
  CGFloat height = CGRectGetHeight(view.bounds);
  CGFloat limitedWidth = MIN(width, [self maxWidthForSnapshotView]);
  CGFloat aspectAdjustment = limitedWidth / width;
  height *= aspectAdjustment;
  CGRect frame = CGRectMake(self.widthForSnapshotColumn * 0.5f - limitedWidth * 0.5f, maxY + kVerticalMargin, limitedWidth, height);
  view.frame = CGRectIntegral(frame);
  [self.scrollView addSubview:view];
  [self.snapshotViews addObject:view];

  if ([view conformsToProtocol:@protocol(KZPSnapshotView)]) {
    UIView <KZPSnapshotView> *snapshot = (UIView <KZPSnapshotView> *)view;
    if (snapshot.hasExtraInformation) {
      [self.scrollView addSubview:[self extraInfoButtonForSnapshotView:snapshot]];
    }
  }
}

- (UIButton *)extraInfoButtonForSnapshotView:(UIView <KZPSnapshotView> *)snapshot
{
  UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
  objc_setAssociatedObject(infoButton, kSnapshotViewKey, snapshot, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  CGFloat buttonHeight = CGRectGetHeight(infoButton.bounds);
  CGFloat buttonWidth = CGRectGetWidth(infoButton.bounds);
  infoButton.frame = CGRectIntegral(CGRectMake(CGRectGetWidth(self.scrollView.bounds) - buttonWidth - kInfoButtonMargin, CGRectGetMidY(snapshot.frame) - buttonHeight * 0.5f, buttonWidth, buttonHeight));
  [infoButton addTarget:self action:@selector(showExtraInfoFromButton:) forControlEvents:UIControlEventTouchUpInside];
  return infoButton;
}


- (void)showExtraInfoFromButton:(UIButton *)button
{
  UIView <KZPSnapshotView> *snapshot = objc_getAssociatedObject(button, kSnapshotViewKey);

  self.currentPopoverController = [[UIPopoverController alloc] initWithContentViewController:snapshot.extraInfoController];
  CGRect buttonRect = [self.view convertRect:button.frame fromView:button.superview];
  [self.currentPopoverController presentPopoverFromRect:buttonRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
}

- (void)reset
{
  [self updateTicker];

  [self.currentPopoverController dismissPopoverAnimated:NO];
  [self.snapshotViews removeAllObjects];
  [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)updateTicker
{
  static NSInteger tick = -1;
  tick++;
  self.tickLabel.text = [NSString stringWithFormat:@"KZPlayground Tick %@", @(tick)];
}

- (void)playgroundDidRun
{
  UIView *lastView = [self.snapshotViews lastObject];
  CGFloat y = CGRectGetMaxY(lastView.frame);
  self.scrollView.contentSize = CGSizeMake(0, y);
}

#pragma mark - Helpers

- (CGFloat)maxWidthForSnapshotView
{
  return [self widthForSnapshotColumn] - kHorizontalMargin * 2;
}

- (CGFloat)widthForSnapshotColumn
{
  static const int infoButtonSize = 22;
  return CGRectGetWidth(self.view.bounds) - (infoButtonSize + kInfoButtonMargin * 2);
}

@end