// MobileTermina.h
#import <UIKit/UIKit.h>

@interface MobileTerminal : UIApplication {
}

- (void)deviceOrientationChanged:(struct GSEvent *)event;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

@end
