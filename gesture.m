#import <Foundation/Foundation.h>
#import <Foundation/NSAutoReleasePool.h>
typedef void* CVImageBufferRef;
#import <SpringBoard/SpringBoard.h>
#import <CaptainHook/CaptainHook.h>

CHDeclareClass(UIStatusBar);

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

CHOptimizedMethod(1, super, id, UIStatusBar, initWithFrame, CGRect, frame)
{
  self = CHSuper(1, UIStatusBar, initWithFrame, frame);
  if (self != nil) {
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
    recognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:recognizer];
    [recognizer release];

    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    recognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:recognizer];
    [recognizer release];
  }

  return self;
}

CHOptimizedMethod(2, super, id, UIStatusBar, initWithFrame, CGRect, frame, showForegroundView, BOOL, view)
{
  self = CHSuper(2, UIStatusBar, initWithFrame, frame, showForegroundView, view);
  if (self != nil) {
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
    recognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:recognizer];
    [recognizer release];

    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    recognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:recognizer];
    [recognizer release];
  }

  return self;
}

CHConstructor
{
  NSLog(@"Gesture injected!!!");

  CHLoadLateClass(UIStatusBar);

  //- (id)initWithFrame:(CGRect)frame showForegroundView:(BOOL)view;
  //- (id)initWithFrame:(CGRect)frame; 
  CHHook(1, UIStatusBar, initWithFrame);
  CHHook(2, UIStatusBar, initWithFrame, showForegroundView);
}
