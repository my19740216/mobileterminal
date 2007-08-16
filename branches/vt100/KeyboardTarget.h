#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UITextView.h>
#import "SubProcess.h"

@interface KeyboardTarget : UITextView {
  SubProcess *_shellProcess;
  bool _controlKeyMode;
  UITextView *_textView;
}

- (id)initWithProcess:(SubProcess *)aProcess View:(UITextView *)view;
- (BOOL)webView:(id)fp8 shouldInsertText:(id)character
                       replacingDOMRange:(id)fp16
                             givenAction:(int)fp20;
@end
