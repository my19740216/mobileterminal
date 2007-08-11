// Cleanup.h
// 
// Cleanup of UIKit headers
#import <UIKit/UITextView.h>
#import <UIKit/UIView.h>

@interface UITextView (CleanWarnings)
-(UIView*) webView;
@end

@interface UIView (CleanWarnings)
- (void) moveToEndOfDocument:(id)inVIew;
- (void) insertText: (id)ourText;
@end

