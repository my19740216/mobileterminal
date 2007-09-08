// main.m
#import <UIKit/UIKit.h>
#import "MobileTerminal.h"
#import <strings.h>

NSString *startPath;

int main(int argc, char **argv)
{
    [[NSAutoreleasePool alloc] init];
    if (argc >= 2)
        startPath = [NSString stringWithCString: argv[1]];
    else
        startPath = nil;
    return UIApplicationMain(argc, argv, [MobileTerminal class]);
}
