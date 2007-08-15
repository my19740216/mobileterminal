// MobileTermina.h
#import <UIKit/UIApplication.h>

@interface MobileTerminal : UIApplication {
}

- (void)deviceOrientationChanged:(struct GSEvent *)event;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

@end
