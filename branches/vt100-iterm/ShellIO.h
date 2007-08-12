// ShellIO.h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UITextView.h>

@class PTYTextView, VT100Screen, VT100Terminal;

@interface ShellIO : UITextView {
  int _fd;
  bool _controlKeyMode;
  PTYTextView* _textView;

  // TODO: rename
  VT100Screen* SCREEN;
  VT100Terminal* TERMINAL;
}

- (id)init:(int)fd withView:(PTYTextView*)view;
- (BOOL)webView:(id)fp8 shouldInsertText:(id)character
                       replacingDOMRange:(id)fp16
                             givenAction:(int)fp20;

@end
