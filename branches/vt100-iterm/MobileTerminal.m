
#import "MobileTerminal.h"

#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import "Common.h"
#import "ShellKeyboard.h"
#import "PTYTextView.h"
#import "SubProcess.h"
#import "ShellIO.h"
#import "VT100Terminal.h"
#import "ColorMap.h"

// TODO: Clean up, use some singletons?
ShellIO* shell;

//
// Mouse control handling, Example: Swipe left: arrow key left
//

@implementation PTYTextView (MouseEvents)

// Amount of movement before detecting an arrow key
#define ARROW_KEY_SLOP 75.0

BOOL isGesture;
CGPoint start;

- (BOOL)ignoresMouseEvents
{
  return NO;
}

- (int)canHandleGestures
{
  return YES;
}

- (void)gestureEnded:(struct GSEvent *)event
{
  isGesture = NO;
}

- (void)gestureStarted:(GSEvent *)event
{
  isGesture = YES;
}

- (void)mouseDown:(GSEvent*)event
{
  // Save the start position of the mouse down event, which is later used
  // to determine which way the cursor moved.
  CGPoint point = GSEventGetLocationInWindow(event);
  start = point;
}

- (void)mouseDragged:(GSEvent*)event
{
/*
  // TODO: If the arrow key is held down, do multiple key presses?
*/
}

- (void)mouseUp:(GSEvent*)event
{
  CGPoint point = GSEventGetLocationInWindow(event);
  CGPoint vector;
  vector.x = start.x - point.x;
  vector.y = start.y - point.y;

  // Only allow one arrow key to be pressed with one mouse event.  See which
  // direction was moved the most first, then move the arrow key in that
  // direction.
  VT100Terminal* term = [shell terminal];
  NSData* data = nil;
  int abs_x = abs((int)vector.x);
  int abs_y = abs((int)vector.y);
  if (abs_x > abs_y) {
    if (vector.x > ARROW_KEY_SLOP) {
      data = [term keyArrowLeft:0];
    } else if (vector.x < (0 - ARROW_KEY_SLOP)) {
      data = [term keyArrowRight:0];
    }
  } else {
    if (vector.y > ARROW_KEY_SLOP) {
      data = [term keyArrowUp:0];
    } else if (vector.y < (0 - ARROW_KEY_SLOP)) {
      data = [term keyArrowDown:0];
    }
  }
  if (data != nil) {
    const char* d = [data bytes];
    [shell writeData:d length:[data length]];
  }
}

@end

@implementation MobileTerminal

- (void) applicationDidFinishLaunching:(NSNotification*)unused
{
  [ColorMap sharedInstance];

  SubProcess* shellProcess =
    [[SubProcess alloc] initWithWidth:TERMINAL_WIDTH Height:TERMINAL_HEIGHT];

  UIWindow *window = [[UIWindow alloc] initWithContentRect: [UIHardware 
    fullScreenApplicationContentRect]];

  PTYTextView* view =
    [[PTYTextView alloc] initWithFrame:CGRectMake(0.0f, 0.0, 320.0f, 245.0f)];
 
  ShellKeyboard* keyboard = [[ShellKeyboard alloc]
    initWithFrame: CGRectMake(0.0f, 245.0, 320.0f, 480.0f)];

  // Captures keyboard input, but isn't shown
  shell = [[ShellIO alloc] init:[shellProcess fileDescriptor] withView:view];

  struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
  rect.origin.x = rect.origin.y = 0.0f;

  UIView *mainView = [[UIView alloc] initWithFrame: rect];
  [mainView addSubview:shell];
  [mainView addSubview:view];
  [mainView addSubview:keyboard];
  
  [window orderFront: self];
  [window makeKey: self];
  [window setContentView: mainView];
  [window _setHidden:NO];
  [shell becomeFirstResponder];
}

@end
