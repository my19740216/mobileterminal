#import <Foundation/Foundation.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIImageView.h>

@interface PieView : UIImageView {
    CGRect visibleFrame, hiddenFrame;
    BOOL _visible;
}
-(void)show;
-(void)hide;
-(void)hideSlow:(BOOL)slow;
@end
