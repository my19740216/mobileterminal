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
  [SCREEN initScreenWithWidth:TERMINAL_WIDTH Height:TERMINAL_HEIGHT];

  id parent = [super initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];

  // Spawn a background thread that reads from the subprocess
  [NSThread detachNewThreadSelector:@selector(startIOThread:)
                           toTarget:self
                         withObject:self];
  return parent;
}

// Output of shell process -> Screen

// This background thread blocks until output is available from the subprocess,
// 
// then pushes tokens to the screen.
- (void)startIOThread:(id)ignored
{
  [[NSAutoreleasePool alloc] init];
  const int kBufSize = 1024;
  char buf[kBufSize];
  int nread;
  while (1) {
    nread = read(_fd, buf, kBufSize);
    if (nread == -1) {
      perror("read");
      return exit(1);
    } if (nread == 0) {
      NSLog(@"Unexpected EOF from child process");
      return exit(1);
    }
    [TERMINAL putStreamData:buf length:nread];

    // Now that we've got the raw data from the sub process, write it to the
    // terminal.  We get back tokens to display on the screen and pass the
    // update in the main thread.
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
    }

    [_textView performSelectorOnMainThread:@selector(setNeedsDisplay)
                                withObject:nil
                             waitUntilDone:NO];
  }
}

//
// Input from keyboard -> Shell Process
//

- (BOOL)webView:(id)fp8 shouldDeleteDOMRange:(id)fp12
{
  // This captures the delete button and sends it to the SubProcess.  It will
  // get reflected on the screen when the output is read back from the
  // SubProcess.
  const char delete_cstr = 0x08;
  if (write(_fd, &delete_cstr, 1) == -1) {
   perror("write");
   exit(1);
  }
  // See if the shell echo'd back what we just wrote
  return NO;
}



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
  // See if the shell echo'd back what we just wrote
  return NO;
}


@end
