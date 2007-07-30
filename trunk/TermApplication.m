#import "TermApplication.h"
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UITextView.h>
#import <UIKit/UIKeyboard.h>

@implementation TermApplication
NSString *sharedString;

void *read_term(int fd, UITextView *view)
{
	char buf[255];
  int nread;
  while ((nread = read(fd, buf, 254)) > 0) {
    int i;
    for (i = 0; i < nread; i++) {
      putchar(buf[i]);
      
       	NSString* existing = [view text];
  		NSString* out = [NSString stringWithCString:buf
          encoding:[NSString defaultCStringEncoding]];
        sharedString = [sharedString stringByAppendingString: out];
        
        
        
   
    }
    
  }
  
}

- (void) applicationDidFinishLaunching: (id) unused
{
    UIWindow *window = [[UIWindow alloc] initWithContentRect: [UIHardware 
        fullScreenApplicationContentRect]];
    [window orderFront: self];
    [window makeKey: self];
    [window _setHidden: NO];
 
    UITextView* view = [[UITextView alloc]
        initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
    [view setEditable:NO];  // don't mess up my pretty output
	 

      pthread_t thread1;

     int  iret1;

    /* Create independent threads each of which will execute function */

 
  
  int fd;
  pid_t pid = forkpty(&fd, NULL, NULL, NULL);
  if (pid == -1) {
    perror("forkpty");
    return 1;
  } else if (pid == 0) {
    if (execlp("/bin/sh", "sh", (void*)0) == -1) {
      perror("execlp");
    }
    fprintf(stderr, "program exited.\n");
    return 1;
  }
  printf("Child process: %d\n", pid);
  printf("master fd: %d\n", fd);

  const char* cmd = "ls -l \n";
  if (write(fd, cmd, strlen(cmd)) == -1) {
    perror("write");
    return 1;
  }
  
  
  iret1 = pthread_create( &thread1, NULL, read_term, fd, view);
  //pthread_join( thread1, NULL);
  printf("did we get here?");
  	NSString* existing = [view text];
	[view setText:[existing stringByAppendingString: sharedString]]; 
          
   
   
    UIKeyboard* keyboard = [[UIKeyboard alloc]
        initWithFrame: CGRectMake(0.0f, 240.0, 320.0f, 480.0f)];

    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;
    UIView *mainView;
    mainView = [[UIView alloc] initWithFrame: rect];
    [mainView addSubview: view]; 
    [mainView addSubview: keyboard];

    [window setContentView: mainView]; 
}

@end
