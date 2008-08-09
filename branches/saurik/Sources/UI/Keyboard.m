// Keyboard.m
#import "Keyboard.h"
#include <objc/runtime.h>
#import <UIKit/UIDefaultKeyboardInput.h>

/* iPhoneOS 2.0 Compatibility {{{ */
#ifdef __OBJC2__
@interface UICGColor : NSObject {
}

- (id) initWithCGColor:(CGColorRef)color;
@end

@interface UIFont {
}

- (UIFont *) fontWithSize:(CGFloat)size;
@end

@interface NSObject (iPhoneOS)
- (CGColorRef) cgColor;
- (CGColorRef) CGColor;
- (void) set;
@end

@implementation NSObject (iPhoneOS)

- (CGColorRef) cgColor {
    return [self CGColor];
}

- (CGColorRef) CGColor {
    return (CGColorRef) self;
}

- (void) set {
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

@interface UITextInputTraits
- (void)setAutocorrectionType:(int)type;
- (void)setAutocapitalizationType:(int)type;
- (void)setEnablesReturnKeyAutomatically:(BOOL)val;
@end
#endif
/* }}} */

@interface TextInputHandler : UIDefaultKeyboardInput
{
  ShellKeyboard* shellKeyboard;
}

- (id)initWithKeyboard:(ShellKeyboard*)keyboard;

@end

@implementation TextInputHandler

- (id)initWithKeyboard:(ShellKeyboard*)keyboard;
{
  self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
  if ( self ) {
      shellKeyboard = keyboard;
      [[self textInputTraits] setAutocorrectionType:1];
      [[self textInputTraits] setAutocapitalizationType:0];
      [[self textInputTraits] setEnablesReturnKeyAutomatically:NO];
  }
  return self;
}

#if 0
- (BOOL)webView:(id)fp8 shouldDeleteDOMRange:(id)fp12
{
  [shellKeyboard handleKeyPress:0x08];
  return false;
}

#endif

- (void)deleteBackward
{
    [shellKeyboard handleKeyPress:0x08];
}

- (void)insertText:(id)character
{
  if ([character length] != 1) {
    [NSException raise:@"Unsupported" format:@"Unhandled multi-char insert!"];
  }
  [shellKeyboard handleKeyPress:[character characterAtIndex:0]];
}

#if 0 // for Debugging
- (NSMethodSignature *) methodSignatureForSelector:(SEL)selector {
    fprintf(stderr, "[%s]S-%s\n", class_getName(self->isa), sel_getName(selector));
    return [super methodSignatureForSelector:selector];
}

- (BOOL) respondsToSelector:(SEL)selector {
    fprintf(stderr, "[%s]R-%s\n", class_getName(self->isa), sel_getName(selector));
    return [super respondsToSelector:selector];
}
#endif

@end

// ShellKeyboard

@implementation ShellKeyboard

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if ( self ) {
      handler = [[TextInputHandler alloc] initWithKeyboard:self];
  }
  return self;
}

- (void)setInputDelegate:(id)delegate;
{
  inputDelegate = delegate;
}

- (void)handleKeyPress:(unichar)c
{
  [inputDelegate handleKeyPress:c];
}

- (void)enable
{
    [self activate];
    [[UIKeyboardImpl activeInstance] setDelegate:handler];
}

- (void)dealloc
{
    [handler release];

    [super dealloc];
}

@end
