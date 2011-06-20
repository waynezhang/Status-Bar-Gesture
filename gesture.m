typedef void* CVImageBufferRef;
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

CHDeclareMethod(0, void, UIStatusBar, swipeRight)
{
  [self performSelector:@selector(swipeLeft) withObject:nil afterDelay:0.05f];
  [self performSelector:@selector(swipeLeft) withObject:nil afterDelay:0.10f];
}

static UIWindow *_sharedTweetWindow = nil;
CHDeclareMethod(0, void, UIStatusBar, doubleTapped)
{
  if (_sharedTweetWindow == nil) {
    _sharedTweetWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];  
  } 
  if (_sharedTweetWindow.rootViewController == nil) {
    TWTweetComposeViewController *tweetController = [[TWTweetComposeViewController alloc] init];
    tweetController.completionHandler = ^(TWTweetComposeViewControllerResult result) {
      [_sharedTweetWindow resignKeyWindow];
      _sharedTweetWindow.hidden = YES;

      _sharedTweetWindow.rootViewController = nil;
    };
    _sharedTweetWindow.rootViewController = tweetController;
    [tweetController release];
  }

  [_sharedTweetWindow makeKeyAndVisible];
  _sharedTweetWindow.hidden = NO;
}

BOOL eventHandled;
CGPoint oldPoint;

CHOptimizedMethod(2, super, void, UIStatusBar, touchesBegan, NSSet *, touches, withEvent, UIEvent *, event)
{
  eventHandled = NO;
  oldPoint = [[touches anyObject] locationInView:self];

	CHSuper(2, UIStatusBar, touchesBegan, touches, withEvent, event);
}

#define DELTA 50.0f
CHOptimizedMethod(2, super, void, UIStatusBar, touchesMoved, NSSet *, touches, withEvent, UIEvent *, event)
{
  if (!eventHandled) {
    CGPoint point = [[touches anyObject] locationInView:self];
    float deltaX = point.x - oldPoint.x;
    float deltaY = point.y - oldPoint.y;
    if (deltaX * deltaX > deltaY * deltaY) {
      if (deltaX > DELTA) {
        eventHandled = YES;
        [self performSelector:@selector(swipeRight) withObject:nil];
      } else if (deltaX < -DELTA) {
        eventHandled = YES;
        [self performSelector:@selector(swipeLeft) withObject:nil];
      }
    }
  }

  CHSuper(2, UIStatusBar, touchesMoved, touches, withEvent, event);
}

CHOptimizedMethod(2, super, void, UIStatusBar, touchesEnded, NSSet *, touches, withEvent, UIEvent *, event)
{
  if (!eventHandled) {
    if ([[touches anyObject] tapCount] == 2) {
      [self performSelector:@selector(doubleTapped) withObject:nil];
    }
  }

	CHSuper(2, UIStatusBar, touchesEnded, touches, withEvent, event);
}

CHConstructor
{
  CHLoadLateClass(UIStatusBar);

  CHHook(2, UIStatusBar, touchesBegan, withEvent);
  CHHook(2, UIStatusBar, touchesMoved, withEvent);
  CHHook(2, UIStatusBar, touchesEnded, withEvent);
}
