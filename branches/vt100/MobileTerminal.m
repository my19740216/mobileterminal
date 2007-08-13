// MobileTerminal.m
#import "MobileTerminal.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIWindow.h>
#import "Common.h"
#import "Cleanup.h"
#import "ShellKeyboard.h"
#import "ShellView.h"
#import "SubProcess.h"
#import "NSTextStorageTerminal.h"

#include <stdio.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

@implementation MobileTerminal

UIApplication *UIApp;

- (void) terminalScreen: (TextStorageTerminal *)terminal scrollsOffText: (NSAttributedString *)text {

}

- (void) terminalScreen: (TextStorageTerminal *)terminal sendsReportData: (NSData *)data {
    [_shellProcess writeData: data];
}

- (void) ptyTaskCompleted: (SubProcess *)pty {
    [UIApp terminate];
}

- (void) dataArrivedFromPty: (SubProcess *)pty {
    //NSString *out = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
    //if ([out length] == 1) {
    //  debug(@"length 1, char code %u", [out characterAtIndex:0]);
    //} else {
    //  debug(@"length of %d", [out length]);
    //  int i;
    //  for (i = 0; i < [out length]; i++) {
    //    debug(@"char %d: code %u", i, [out characterAtIndex:i]);
    //  }
    //}

    // seems like if i read out a empty buffer with errno = EAGAIN it means exit
    //if (![out length]) {
    //  //doesn't zoom out, is there a UIApplication method?
    //  exit(1);
    //}
    //if ([out length] == 3) {
    //  if ([out characterAtIndex:0] == 0x08 &&
    //      [out characterAtIndex:1] == 0x20 &&
    //      [out characterAtIndex:2] == 0x08) {
    //    // delete sequence, don't output
    //    //debug(@"delete");
    //    return;
    //  }
    //}
//
    filter = [filter processData: [_shellProcess availableData]];

    //fflush(stdout);fflush(stderr);
    [[[_view _webView] webView] moveToEndOfDocument:self];
    [_view stopCapture];
    [_view setHTML: [[[_view terminal] textStorage] html]];
    [_view startCapture];
    NSRange aRange;
    int x, y;
    [[_view terminal] cursorLocationX: &x Y: &y];
    aRange.location = [[[_view terminal] textStorage] ensureRow: y hasColumn: x]+5;
    aRange.length = 0;
    [_view setSelectionRange:aRange];
    [_view scrollToMakeCaretVisible:YES];
}

- (void) applicationDidFinishLaunching: (id) unused
{
  const int rows = 15, cols = 45;
  // Terminal size based on the font size below
  _shellProcess = [[SubProcess alloc] init];
  [_shellProcess setRows:rows columns:cols];
  [_shellProcess setDelegate: self];
  [_shellProcess setExecutablePath: @"/bin/login"];
  [_shellProcess setArguments: [NSArray arrayWithObjects: @"login", @"-p", @"-f", @"root", nil]];
  [_shellProcess setEnvironment: [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"xterm-color", @"TERM",
                                    nil]];
  UIWindow *window = [[UIWindow alloc] initWithContentRect: [UIHardware 
    fullScreenApplicationContentRect]];
  [window orderFront: self];
  [window makeKey: self];
  float backcomponents[4] = {0, 0, 0, 0};
  #ifndef GREENTEXT
    float textcomponents[4] = {1, 1, 1, 1};
  #else
    float textcomponents[4] = {.1, .9, .1, 1};
  #endif // !GREENTEXT
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *defaultPath = [bundle pathForResource:@"Default" ofType:@"png"];
  NSString *barPath = [bundle pathForResource:@"bar" ofType:@"png"];

  UIImage *theDefault = [[UIImage alloc]initWithContentsOfFile:defaultPath];
  UIImage *bar = [[UIImage alloc]initWithContentsOfFile:barPath];
  UIImageView *barView = [[UIImageView alloc] initWithFrame: CGRectMake(0.0f, 405.0f, 320.0f, 480.0f)];
  UIImageView *workaround = [[UIImageView alloc] init];
  [workaround setImage:theDefault];
  [barView setImage:bar];
  [barView setAlpha:1.0];

  ShellView* view =
    [[ShellView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
  [view setPty:_shellProcess];
  [view setText:@""];
  // Don't change the font size or style without updating the window size below
  [view setTextSize:11];
  [view setTextFont:@"Monaco"];
  [view setRows: rows cols: cols];
  [[view terminal] setDelegate: self];
  
  filter = [[XTermDefaultLineFilter alloc] initWithTerminal: [view terminal]];

  [view setTextColor: CGColorCreate( colorSpace, textcomponents)];
  [view setBackgroundColor: CGColorCreate( colorSpace, backcomponents)];
  [view setEditable:YES]; // don't mess up my pretty output
  [view setAllowsRubberBanding:YES];
  [view displayScrollerIndicators];
  [view setOpaque:NO];
  [view setBottomBufferHeight:(5.0f)];
  _view = view;
 
  ShellKeyboard* keyboard = [[ShellKeyboard alloc]
    initWithFrame: CGRectMake(0.0f, 240.0, 320.0f, 480.0f)];

  [view setKeyboard:keyboard];

  [keyboard setTapDelegate:view];

  struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
  rect.origin.x = rect.origin.y = 0.0f;
  UIView *mainView;
  mainView = [[UIView alloc] initWithFrame: rect];

  [view setMainView:mainView];
  [keyboard show:view];

//  [view setHeartbeatDelegate:self];

  [mainView addSubview: workaround];
  [mainView addSubview: view];
  [mainView addSubview: barView];
  [mainView addSubview: keyboard];
  
  [view becomeFirstResponder];
  [window setContentView: mainView];

  [_shellProcess launchTask];
  [self dataArrivedFromPty: _shellProcess]; 
}

@end
