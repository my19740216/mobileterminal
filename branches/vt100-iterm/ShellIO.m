// ShellIO.h
#import "ShellIO.h"

#include <stdio.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#import "Cleanup.h"
#import "Common.h"
#import "PTYTextView.h"
#import "VT100Screen.h"
#import "VT100Terminal.h"

@implementation ShellIO

- (id)init:(int)fd withView:(PTYTextView*)view
{
  _fd = fd;
  _controlKeyMode = NO;
  _textView = view;

  TERMINAL = [[VT100Terminal alloc] init];
  SCREEN = [[VT100Screen alloc] init];
  [_textView setDataSource:SCREEN];
  [TERMINAL setScreen:SCREEN];
  [SCREEN setTerminal:TERMINAL];
// TODO: ugly, heights and widths allllll over the place
  [_textView setLineHeight:15];
  [_textView setLineWidth:320];
  [SCREEN initScreenWithWidth:41 Height:19];

  id parent = [super initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
  [parent startHeartbeat:@selector(heartbeatCallback:) inRunLoopMode:nil];
  return parent;
}

// Output of shell process -> Screen

// The heartbeatCallback is invoked by the UI occasionally. It does a
// non-blocking read of the background shell process, and also checks for
// input from the user. When it detects the user has pressed return, it
// sends the command to the background shell.
- (void)heartbeatCallback:(id)ignored
{
//  NSLog(@"heartbeat");

  char buf[255];
  int nread;
  while (1) {
    nread = read(_fd, buf, 254);
    if (nread == -1) {
      if (errno == EAGAIN) {
        // No input was available, try reading again on next heartbeat
        return;
      }
      perror("read");
      return exit(1);
    } if (nread == 0) {
      NSLog(@"End of file from child process");
      return exit(1);
    }
    buf[nread] = '\0';
    NSString* out =
      [[NSString stringWithCString:buf
          encoding:[NSString defaultCStringEncoding]] retain];

    const char* buf =
      [out cStringUsingEncoding:[NSString defaultCStringEncoding]];
    int length = [out length];
    [TERMINAL putStreamData:buf length:length];

    // Now that we've got the raw data from the sub process, write it to the
    // terminal.  We get back tokens to display on the screen.
    VT100TCC token;
    while((token = [TERMINAL getNextToken]),
          token.type != VT100_WAIT && token.type != VT100CC_NULL) {
      // process token
      if (token.type != VT100_SKIP) {
        if (token.type == VT100_NOTSUPPORT) {
          NSLog(@"%s(%d):not support token", __FILE__ , __LINE__);
        } else {
          [SCREEN putToken:token];
	}
      } 
    } // end token processing loop
    [_textView setNeedsDisplay];

  }
}

//
// Input from keyboard -> Shell Process
//

- (BOOL)webView:(id)fp8 shouldInsertText:(id)character replacingDOMRange:(id)fp16 givenAction:(int)fp20
{
  debug(@"inserting.. %#x", [character characterAtIndex:0]);
  if([character length] != 1) {
    debug(@"Unhandled multiple character insert!");
    return false;  //or just loop through
  }

  char cmd_char = [character characterAtIndex:0];

  if (!_controlKeyMode) {
    if ([character characterAtIndex:0] == 0x2022) {
      //debug(@"ctrl key mode");
      _controlKeyMode = YES;
      return NO;
    }
  } else {
    // was in ctrl key mode, got another key
    //debug(@"sending ctrl key");
    if (cmd_char < 0x60 && cmd_char > 0x40) {
      // Uppercase
      cmd_char -= 0x40;      
    } else if (cmd_char < 0x7B && cmd_char > 0x61) {
      // Lowercase
      cmd_char -= 0x60;
    }
    _controlKeyMode = NO;
  }
 
  debug(@"writing char: %#x", cmd_char);
  if (write(_fd, &cmd_char, 1) == -1) {
   perror("write");
   exit(1);
  }
  return NO;
}


@end
