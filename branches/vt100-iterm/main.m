// main.m
#import <UIKit/UIKit.h>
#import "MobileTerminal.h"

// TODO: This is a workaround to fix a link error; not sure what the
// consequences will be.
void objc_msgSend_fpret(int x) { return; }

int main(int argc, char **argv)
{
    [[NSAutoreleasePool alloc] init];
    return UIApplicationMain(argc, argv, [MobileTerminal class]);
}
