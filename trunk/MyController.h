/* MyController */

#import <Cocoa/Cocoa.h>
#import "PTYTask.h"

@interface MyController : NSObject
{
    IBOutlet id inputBox;
    IBOutlet id outputBox;
	
	PTYTask * SHELL;
	int taskRunning;
}
- (int)runBash;
- (IBAction)EscKey:(id)sender;
- (IBAction)CrtlKey:(id)sender;
- (IBAction)EnterKey:(id)sender;
- (void)writeTask:(NSData *)data;
// PTYTask delagats;
- (void)readTask:(char *)buf length:(int)length;
- (void)brokenPipe;
@end
