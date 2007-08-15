
#import "MobileTerminal.h"

#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIKeyboard.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIWindow.h>
#import "Common.h"
#import "ShellKeyboard.h"
#import "PTYTextView.h"
#import "SubProcess.h"
#import "ShellIO.h"
#import "VT100Terminal.h"

struct CGRect GSEventGetLocationInWindow(struct GSEvent *ev);

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

- (void)gestureStarted:(struct GSEvent *)event
{
  isGesture = YES;
}

- (void)mouseDown:(struct GSEvent*)event
{
  // Save the start position of the mouse down event, which is later used
  // to determine which way the cursor moved.
  CGRect rect = GSEventGetLocationInWindow(event);
  start = rect.origin;
}

- (void)mouseDragged:(struct GSEvent*)event
{
/*
  // TODO: Arrow key is held down, do multiple key presses
  CGRect rect = GSEventGetLocationInWindow(event);
  NSLog(@"mouseDragged %f,%f %f,%f", rect.origin.x, rect.origin.y,
        rect.size.width, rect.size.height);
*/
}

- (void)mouseUp:(struct GSEvent*)event
{
  CGRect rect = GSEventGetLocationInWindow(event);
  CGPoint vector;
  vector.x = start.x - rect.origin.x;
  vector.y = start.y - rect.origin.y;

  // Only allow one arrow key to be pressed with one mouse event.  See which
  // direction was moved the most first, then move the arrow key in that
  // direction.
  VT100Terminal* term = [shell terminal];
  NSData* data = nil;
  int abs_x = abs((int)vector.x);
  int abs_y = abs((int)vector.y);
  if (abs_x > abs_y) {
    if (vector.x > 75) {
      data = [term keyArrowLeft:0];
    } else if (vector.x < -75) {
      data = [term keyArrowRight:0];
    }
  } else {
    if (vector.y > 75) {
      data = [term keyArrowUp:0];
    } else if (vector.y < -75) {
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

- (void)deviceOrientationChanged:(struct GSEvent *)event
{
  NSLog(@"orientation");
}

- (void) applicationDidFinishLaunching:(NSNotification*)unused
{
  NSLog(@"o=%d", [UIHardware deviceOrientation: YES]);

  SubProcess* shellProcess =
    [[SubProcess alloc] initWithWidth:TERMINAL_WIDTH Height:TERMINAL_HEIGHT];

  UIWindow *window = [[UIWindow alloc] initWithContentRect: [UIHardware 
    fullScreenApplicationContentRect]];

  NSBundle *bundle = [NSBundle mainBundle];
  NSString *defaultPath = [bundle pathForResource:@"Default" ofType:@"png"];
  NSString *barPath = [bundle pathForResource:@"bar" ofType:@"png"];

  UIImage *theDefault = [[UIImage alloc]initWithContentsOfFile:defaultPath];
  UIImage *bar = [[UIImage alloc]initWithContentsOfFile:barPath];
  UIImageView *barView =
    [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 405.0f, 320.0f,
                                                  480.0f)];
  UIImageView *workaround = [[UIImageView alloc] init];
  [workaround setImage:theDefault];
  [barView setImage:bar];
  [barView setAlpha:1.0];

  PTYTextView* view =
    [[PTYTextView alloc] initWithFrame:CGRectMake(0.0f, 0.0, 320.0f, 245.0f)];
 
  ShellKeyboard* keyboard = [[ShellKeyboard alloc]
    initWithFrame: CGRectMake(0.0f, 245.0, 320.0f, 480.0f)];

  // Captures keyboard input, but isn't shown
  shell = [[ShellIO alloc] init:[shellProcess fileDescriptor] withView:view];

  struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
  rect.origin.x = rect.origin.y = 0.0f;

  UIView *mainView = [[UIView alloc] initWithFrame: rect];
  [mainView addSubview:workaround];
  [mainView addSubview:shell];
  [mainView addSubview:view];
  [mainView addSubview:barView];
  [mainView addSubview:keyboard];
  
  [window orderFront: self];
  [window makeKey: self];
  [window setContentView: mainView];
  [window _setHidden:NO];
  [shell becomeFirstResponder];
}

@end
