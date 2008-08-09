/**
 * iPhoneOS 1.1.x/2.x Compatibility
 */

#ifdef __OBJC2__ // For iPhone OS 2.x

# import <QuartzCore/CoreAnimation.h>
# define LKAnimation CAAnimation
# define LKTimingFunction CAMediaTimingFunction
# define LKTransition CATransition

# import <Foundation/NSObject.h>
# import <UIKit/UITextView.h>
# import <UIKit/UIDefaultKeyboardInput.h>
# import <UIKit/UIViewController.h>

// --------------------------------------------------------------- new classes

@interface UITextInputTraits
- (void)setAutocorrectionType:(int)type;
- (void)setAutocapitalizationType:(int)type;
- (void)setEnablesReturnKeyAutomatically:(BOOL)val;
@end

@interface UIColor
+ (UIColor *)clearColor;
@end

@interface UICGColor : NSObject
{}
- (id) initWithCGColor:(CGColorRef)color;
@end

@interface UIFont
- (UIFont *) fontWithSize:(CGFloat)size;
@end

// ---------------------------------------------------------- extended classes

@interface NSObject (iPhoneOS)
- (CGColorRef) cgColor;
- (CGColorRef) CGColor;
- (void) set;
@end

@implementation NSObject (iPhoneOS)

- (CGColorRef)cgColor
{
    return [self CGColor];
}

- (CGColorRef)CGColor
{
    return (CGColorRef) self;
}

- (void) set
{
    [[[[objc_getClass("UICGColor") alloc] initWithCGColor:[self CGColor]] autorelease] set];
}

@end

@interface UITextView (iPhoneOS)
- (void) setTextSize:(float)size;
@end

@implementation UITextView (iPhoneOS)
- (void) setTextSize:(float)size {
    [self setFont:[[self font] fontWithSize:size]];
}
@end

@interface UIDefaultKeyboardInput (iPhoneOS)
- (id)textInputTraits;
@end

@interface UIViewController (iPhoneOS)
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle;
@end

#else // For iPhoneOS 1.1.x

# import <LayerKit/LKAnimation.h>

#endif

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
