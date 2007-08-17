// MobileTermina.h
#import <UIKit/UIApplication.h>
#import "ANSIDefaultLineFilter.h"
#import "XTermDefaultLineFilter.h"
#import "GSAttributedString-HTML.h"
#import "KeyboardTarget.h"
#import "GestureView.h"
@class ShellView, SubProcess;

@interface MobileTerminal : UIApplication {
  SubProcess* _shellProcess;
  ShellView* _view;
  GestureView* _gestureView;
  CharacterLineFilter *filter;
  NSMutableString *scrollback;
  int scrollbackbytes;
  KeyboardTarget *keyTarget;
}

@end
