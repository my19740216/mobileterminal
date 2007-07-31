#import "TermApplication.h"
#import "MyController.h"
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UITextView.h>
#import <UIKit/UIKeyboard.h>


@implementation TermApplication

	UITextView* view;



- (void) applicationDidFinishLaunching: (id) unused
{
    UIWindow *window = [[UIWindow alloc] initWithContentRect: [UIHardware 
        fullScreenApplicationContentRect]];
    [window orderFront: self];
    [window makeKey: self];
    [window _setHidden: NO];
 
    view = [[UITextView alloc]
        initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 200.0f)];
    [view setEditable:NO];  // don't mess up my pretty output
	UITextView* input = [[UITextView alloc]initWithFrame: CGRectMake(0.0f, 200.0f, 320.0f, 240.0f)];
	[input setText:@"$"];

    /* Create independent threads each of which will execute function */

 	MyController* Controller = [[MyController alloc] init];
 	[Controller runBash];
  

  
  


          
   
   
    UIKeyboard* keyboard = [[UIKeyboard alloc]
        initWithFrame: CGRectMake(0.0f, 240.0, 320.0f, 480.0f)];

    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;
    UIView *mainView;
    mainView = [[UIView alloc] initWithFrame: rect];
    [mainView addSubview: view]; 
    [mainView addSubview: input]; 
    [mainView addSubview: keyboard];

    [window setContentView: mainView];
    
}

- (UITextView*) getOutputBox
	{
		return view;
	}
	
@end
