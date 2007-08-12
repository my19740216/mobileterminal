// MobileTerminal.m
#import "MobileTerminal.h"

#import <Foundation/Foundation.h>
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

@implementation MobileTerminal

- (void) applicationDidFinishLaunching: (id) unused
{
  // Terminal size based on the font size below
  SubProcess* shellProcess = [[SubProcess alloc] initWithRows:19 columns:41];

  UIWindow *window = [[UIWindow alloc] initWithContentRect: [UIHardware 
    fullScreenApplicationContentRect]];
  [window orderFront: self];
  [window makeKey: self];

  NSBundle *bundle = [NSBundle mainBundle];
  NSString *defaultPath = [bundle pathForResource:@"Default" ofType:@"png"];
  NSString *barPath = [bundle pathForResource:@"bar" ofType:@"png"];

  UIImage *theDefault = [[UIImage alloc]initWithContentsOfFile:defaultPath];
  UIImage *bar = [[UIImage alloc]initWithContentsOfFile:barPath];
  UIImageView *barView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 405.0f, 320.0f, 480.0f)];
  UIImageView *workaround = [[UIImageView alloc] init];
  [workaround setImage:theDefault];
  [barView setImage:bar];
  [barView setAlpha:1.0];

  PTYTextView* view =
    [[PTYTextView alloc] initWithFrame:CGRectMake(0.0f, 0.0, 320.0f, 245.0f)];
 
  ShellKeyboard* keyboard = [[ShellKeyboard alloc]
    initWithFrame: CGRectMake(0.0f, 245.0, 320.0f, 480.0f)];
//  [keyboard show:view];
//  [view setKeyboard:keyboard];

  // Captures keyboard input, but isn't shown
  UIView* input =
    [[ShellIO alloc] init:[shellProcess fileDescriptor] withView:view];

  struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
  rect.origin.x = rect.origin.y = 0.0f;

  UIView *mainView = [[UIView alloc] initWithFrame: rect];
  [mainView addSubview:workaround];
  [mainView addSubview:view];
  [mainView addSubview:input];
  [mainView addSubview:barView];
  [mainView addSubview:keyboard];
  
  [window setContentView: mainView];
  [input becomeFirstResponder];
}

@end
