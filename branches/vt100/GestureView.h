#import <Foundation/Foundation.h>
#import <UIKit/UIResponder.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIImageView.h>
#import "PieView.h"
#import "SubProcess.h"

@interface GestureView : UIView {
    SubProcess *_shellProcess;
    PieView *_pie;
}
-initWithProcess:(SubProcess *)aProcess Frame:(struct CGRect)rect Pie:(PieView *)pie;
@end
