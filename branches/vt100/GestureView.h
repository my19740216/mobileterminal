#import <Foundation/Foundation.h>
#import <UIKit/UIResponder.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIView-Hierarchy.h>
#import "SubProcess.h"

@interface GestureView : UIView {
    SubProcess *_shellProcess;
}
-initWithProcess:(SubProcess *)aProcess Frame:(struct CGRect)rect;
@end
