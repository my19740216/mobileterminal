#import "KeyboardTarget.h"

@implementation KeyboardTarget

- (id)initWithProcess:(SubProcess *)aProcess View:(UITextView *)view {
    if ((self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)])) {
        _shellProcess = aProcess;
        _controlKeyMode = NO;
        _textView = view;
    }
    return self;
}

- (BOOL)webView:(id)fp8 shouldDeleteDOMRange:(id)fp12
{
//  debug(@"deleting range: %i, %i", [fp12 startOffset], [fp12 endOffset]);

  //if(!_ignoreInsertText) {
    unichar delete_cstr = 0x7F;
    [_shellProcess writeData: [[NSString stringWithCharacters: &delete_cstr length: 1] dataUsingEncoding: NSASCIIStringEncoding]];
  //  }
  return NO;//[super webView:fp8 shouldDeleteDOMRange:fp12];
}

- (BOOL)webView:(id)fp8 shouldInsertText:(id)character replacingDOMRange:(id)fp16 givenAction:(int)fp20
{
  //debug(@"inserting.. %#x", [character characterAtIndex:0]);
 
/*  if(!_ignoreInsertText) {
    if([character length] > 1) return false;  //or just loop through
*/ 
    unichar cmd_char = [character characterAtIndex:0];
 
    if(!_controlKeyMode) {
      if([character characterAtIndex:0] == 0x2022) {
        //debug(@"ctrl key mode");
        _controlKeyMode = YES;
        return NO;
      }
    } else {
      // was in ctrl key mode, got another key
      //debug(@"sending ctrl key");
      if (cmd_char < 0x60 && cmd_char > 0x40) {
        //Uppercase
        cmd_char -= 0x40;      
      } else if (cmd_char < 0x7B && cmd_char > 0x61) {
        //Lowercase
        cmd_char -= 0x60;
      }
      _controlKeyMode = NO;
    }
    [_shellProcess writeData: [[NSString stringWithCharacters: &cmd_char length: 1] dataUsingEncoding: NSASCIIStringEncoding]];

    //[_shellProcess writeData: [character dataUsingEncoding: NSASCIIStringEncoding]];
    return NO;// [super webView:fp8 shouldInsertText:character
           // replacingDOMRange:fp16 givenAction:fp20];
}

- (BOOL)canResignFirstResponder { return NO; }

@end
