// ShellView.h
#import <UIKit/UIKit.h>
#import <UIKit/UITextView.h>
#import "SubProcess.h"
#import "TextStorageTerminal.h"

@class ShellKeyboard;

@interface ShellView : UITextView {
  NSMutableString* _nextCommand;
  bool _ignoreInsertText;
  bool _controlKeyMode;
  ShellKeyboard* _keyboard;
  UIView *_mainView;
  SubProcess *_pty;
  id _heartbeatDelegate;
  SEL _heartbeatSelector;
  TextStorageTerminal *content;
}

- (id)initWithFrame:(struct CGRect)fp8;
- (void)setPty:(SubProcess *)pty;
- (void)setMainView:(UIView *) mainView;
- (void)setKeyboard:(ShellKeyboard*) keyboard;
- (BOOL)canBecomeFirstResponder;
- (void)forwardInvocation:(NSInvocation *)anInvocation;
- (void)stopCapture;
- (void)startCapture;
- (BOOL)respondsToSelector:(SEL)aSelector;
- (void)forwardInvocation:(NSInvocation *)anInvocation;
- (BOOL)webView:(id)fp8 shouldDeleteDOMRange:(id)fp12;
- (BOOL)webView:(id)fp8 shouldInsertText:(id)character
      replacingDOMRange:(id)fp16 givenAction:(int)fp20;
- (void)setRows:(int)r cols:(int)c;
- (TextStorageTerminal *)terminal;
- (void)scrollToBottom;
@end
