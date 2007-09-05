// MobileTermina.h
#import <UIKit/UIKit.h>

@class PTYTextView;
@class ShellKeyboard;
@class SubProcess;
@class VT100Screen;
@class VT100Terminal;

@interface MobileTerminal : UIApplication
// TODO?
//<KeyboardInputProtocol, InputDelegateProtocol>
{
  UIWindow* window;
  PTYTextView* textView;
  UIScroller* textScroller;
  ShellKeyboard* keyboardView;

  SubProcess* process;
  VT100Screen* screen;
  VT100Terminal* terminal;

  BOOL controlKeyMode;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

- (void)handleStreamOutput:(const char*)c length:(unsigned int)len;
- (void)handleKeyPress:(unichar)c;

@end
