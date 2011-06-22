#import <SpringBoard/SpringBoard.h>
#import <CaptainHook/CaptainHook.h>

CHDeclareClass(UIStatusBar);

enum TWTweetComposeViewControllerResult {
  TWTweetComposeViewControllerResultCancelled,
  TWTweetComposeViewControllerResultDone
};
typedef enum TWTweetComposeViewControllerResult TWTweetComposeViewControllerResult;
typedef void (^TWTweetComposeViewControllerCompletionHandler)(TWTweetComposeViewControllerResult result);

@interface TWTweetComposeViewController : UIViewController
@property(nonatomic, copy) TWTweetComposeViewControllerCompletionHandler completionHandler;
@end

// press home button
CHDeclareMethod(0, void, UIStatusBar, swipeLeft)
{
  struct GSEventRecord record;
  memset(&record, 0, sizeof(record));
  record.type = kGSEventMenuButtonDown;
  record.timestamp = GSCurrentEventTimestamp();
  GSSendSystemEvent(&record);
  record.type = kGSEventMenuButtonUp;
  GSSendSystemEvent(&record);
}

// press home button twice
CHDeclareMethod(0, void, UIStatusBar, swipeRight)
{
  [self performSelector:@selector(swipeLeft) withObject:nil afterDelay:0.05f];
  [self performSelector:@selector(swipeLeft) withObject:nil afterDelay:0.10f];
}

// tweet
static UIWindow *_sharedTweetWindow = nil;
CHDeclareMethod(1, void, UIStatusBar, doubleTapped, UIGestureRecognizer *, recognizer)
{
  if (recognizer.state == UIGestureRecognizerStateEnded) {
    if (_sharedTweetWindow == nil) {
      _sharedTweetWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    } 

    if (_sharedTweetWindow.rootViewController == nil) {
      TWTweetComposeViewController *tweetController = [[TWTweetComposeViewController alloc] init];
      tweetController.completionHandler = ^(TWTweetComposeViewControllerResult result) {
        [_sharedTweetWindow resignFirstResponder];
        _sharedTweetWindow.hidden = YES;
        _sharedTweetWindow.rootViewController = nil;
      };
      _sharedTweetWindow.rootViewController = tweetController;
      [tweetController release];
    }

    // update orientation
    int orientation = CHIvar(self, _orientation, int);
    [_sharedTweetWindow _updateToInterfaceOrientation:orientation animated:NO];

    // do not make key window or table view won't scroll again when status bar touched
    [_sharedTweetWindow becomeFirstResponder];
    _sharedTweetWindow.hidden = NO;
  }
}

CHDeclareMethod(0, void, UIStatusBar, setGesture)
{
  // double tap
  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] init];
  tapRecognizer.numberOfTapsRequired = 2;
  tapRecognizer.delaysTouchesBegan = YES;
  tapRecognizer.delaysTouchesEnded = YES;
  [tapRecognizer addTarget:self action:@selector(doubleTapped:)];
  [self addGestureRecognizer:tapRecognizer];
  [tapRecognizer release];

  // swipe left
  UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] init];
  swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
  swipeLeftRecognizer.delaysTouchesBegan = YES;
  swipeLeftRecognizer.delaysTouchesEnded = YES;
  [swipeLeftRecognizer addTarget:self action:@selector(swipeLeft)];
  [self addGestureRecognizer:swipeLeftRecognizer];
  [swipeLeftRecognizer release];

  // swipe right
  UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] init];
  swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
  swipeRightRecognizer.delaysTouchesBegan = YES;
  swipeRightRecognizer.delaysTouchesEnded = YES;
  [swipeRightRecognizer addTarget:self action:@selector(swipeRight)];
  [self addGestureRecognizer:swipeRightRecognizer];
  [swipeRightRecognizer release];
}

CHOptimizedMethod(1, super, id, UIStatusBar, initWithFrame, CGRect, frame)
{
  CHSuper(1, UIStatusBar, initWithFrame, frame);
  [self performSelector:@selector(setGesture) withObject:nil];

  return self;
}

CHOptimizedMethod(2, super, id, UIStatusBar, initWithFrame, CGRect, frame, showForegroundView, UIView, view)
{
  CHSuper(2, UIStatusBar, initWithFrame, frame, showForegroundView, view);
  [self performSelector:@selector(setGesture) withObject:nil];

  return self;
}

CHConstructor
{
  CHLoadLateClass(UIStatusBar);

  CHHook(1, UIStatusBar, initWithFrame);
  CHHook(2, UIStatusBar, initWithFrame, showForegroundView);
}
