#import "GestureView.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/CDStructures.h>

struct CGRect GSEventGetLocationInWindow(struct __GSEvent *ev);

@implementation GestureView
-initWithProcess:(SubProcess *)aProcess Frame:(struct CGRect)rect{
    if ((self = [super initWithFrame: rect])) {
        _shellProcess = aProcess;
    }
    return self;
}

#define ARROW_KEY_SLOP 75.0

BOOL isGesture;
CGPoint start;

- (BOOL)ignoresMouseEvents { return NO; }
- (int)canHandleGestures { return YES; }
- (void)gestureEnded:(struct __GSEvent *)event { isGesture = NO; }
- (void)gestureStarted:(struct __GSEvent *)event { isGesture = YES; }

- (void)mouseDown:(struct __GSEvent *)event {
    CGRect rect = GSEventGetLocationInWindow(event);
    start = rect.origin;
}

- (void)mouseDragged:(struct __GSEvent*)event {

}

- (void)mouseUp:(struct __GSEvent*)event {
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
        [_shellProcess writeData: [[NSString stringWithCharacters: characters length: charCount] dataUsingEncoding: NSASCIIStringEncoding]];
    }
}

-(BOOL)canBecomeFirstResponder { return NO; }
-(BOOL)isOpaque { return NO; }
-(void)drawRect: (CGRect *)rect { }
@end
