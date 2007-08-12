// main.m
#import <UIKit/UIKit.h>
#import "MobileTerminal.h"

void objc_msgSend_fpret(int x) { return; }

int main(int argc, char **argv)
{
    [[NSAutoreleasePool alloc] init];
    return UIApplicationMain(argc, argv, [MobileTerminal class]);
}
