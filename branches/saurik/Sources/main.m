// main.m
#import <UIKit/UIKit.h>
#import "MobileTerminal.h"
#import "Settings.h"
#include <objc/runtime.h>

void UIApplicationUseLegacyEvents(BOOL use);

int main(int argc, char **argv)
{
  [[NSAutoreleasePool alloc] init];
  
  if (argc >= 2) 
  {
    NSLog(@"argc %d", argc);
    NSString* args = @"";
    int i ;
    for (i = 1; i < argc; i++) 
    {      
      if (i != 1) 
      {
        args = [args stringByAppendingString:@" "];
      }
      
      args = [args stringByAppendingFormat:@"%s", argv[i]];

      NSLog(@"args [%d] %s args %@", i, argv[i], args);
    }
    
    [[Settings sharedInstance] setArguments:args];
  }

  UIApplicationUseLegacyEvents(1);
  return UIApplicationMain(argc, argv, [MobileTerminal class]);
}
