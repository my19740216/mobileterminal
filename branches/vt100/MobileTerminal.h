// MobileTermina.h
#import <UIKit/UIApplication.h>
#import "ANSIDefaultLineFilter.h"
#import "XTermDefaultLineFilter.h"
#import "GSAttributedString-HTML.h"
#import "KeyboardTarget.h"
#import "GestureView.h"
#import "PieView.h"

@class ShellView, SubProcess;

CGRect pieVisibleFrame, pieHiddenFrame;

@interface MobileTerminal : UIApplication {
  SubProcess* _shellProcess;
  ShellView* _view;
  GestureView* _gestureView;
  CharacterLineFilter *filter;
  NSMutableString *scrollback;
  int scrollbackbytes;
  KeyboardTarget *keyTarget;
  PieView *pieView;
}

@end
