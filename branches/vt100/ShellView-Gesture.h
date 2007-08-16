#import <Foundation/Foundation.h>
#import "ShellView.h"

@interface ShellView (Gesture)
- (BOOL)ignoresMouseEvents;
- (int)canHandleGestures;
- (void)gestureEnded:(struct GSEvent *)event;
- (void)gestureStarted:(struct GSEvent *)event;
- (void)mouseDown:(struct GSEvent *)event;
- (void)mouseDragged:(struct GSEvent *)event;
- (void)mouseUp:(struct GSEvent *)event;
@end
