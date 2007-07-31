#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIPushButton.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UIImageAndTextTableCell.h>
#import <UIKit/UITextView.h>


@interface TermApplication : UIApplication {
    UIImageAndTextTableCell *pbCell;
    UITableCell *buttonCell;
    
    }
    
+(UITextView*) getOutputBox;

@end