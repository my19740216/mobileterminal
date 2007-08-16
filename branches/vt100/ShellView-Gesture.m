#import "ShellView.h"
#import "ShellView-Gesture.h"
#import <UIKit/CDStructures.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIKit.h>

struct CGRect GSEventGetLocationInWindow(struct GSEvent *ev);

@implementation ShellView (Gesture)
#define ARROW_KEY_SLOP 75.0

BOOL isGesture;
CGPoint start;

- (BOOL)ignoresMouseEvents { return NO; }
- (int)canHandleGestures { return YES; }
- (void)gestureEnded:(struct GSEvent *)event { isGesture = NO; }
- (void)gestureStarted:(struct GSEvent *)event { isGesture = YES; }

- (void)mouseDown:(struct GSEvent *)event {
    CGRect rect = GSEventGetLocationInWindow(event);
    start = rect.origin;
}

- (void)mouseDragged:(struct GSEvent*)event {

}

- (void)mouseUp:(struct GSEvent*)event {
    CGRect rect = GSEventGetLocationInWindow(event);
    CGPoint vector;
    vector.x = rect.origin.x - start.x;
    vector.y = rect.origin.y - start.y;

    int abs_x = abs((int)vector.x);
    int abs_y = abs((int)vector.y);
    unichar characters[] = {0x1B, '[', 0}, charCount = 3;
    if (abs_x > abs_y) {
        if (vector.x > ARROW_KEY_SLOP) {
            characters[2] = 'C';
        } else if (vector.x < -ARROW_KEY_SLOP) {
            characters[2] = 'D';
        }
    } else {
        if (vector.y > ARROW_KEY_SLOP) {
            characters[2] = 'B';
        } else if (vector.y < -ARROW_KEY_SLOP) {
            characters[2] = 'A';
        }
    }
    if (characters[2] == 0) {
        characters[0] = 0x09;
        charCount = 1;
    }
    if (charCount != 0) {
        [_pty writeData: [[NSString stringWithCharacters: characters length: charCount] dataUsingEncoding: NSASCIIStringEncoding]];
    }
}

@end
