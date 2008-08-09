// ShellKeyboard.h
#import <UIKit/UIKit.h>
#import <UIKit/UITextView.h>

@protocol KeyboardInputProtocol
- (void)handleKeyPress:(unichar)c;
@end

@interface ShellKeyboard : UIKeyboard<KeyboardInputProtocol>
{
  id inputDelegate;
  id handler;
}

- (id)initWithFrame:(CGRect)frame;
- (void)setInputDelegate:(id)delegate;
- (void)handleKeyPress:(unichar)c;
- (void)enable;

@end
