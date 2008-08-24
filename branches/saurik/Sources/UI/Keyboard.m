// Keyboard.m

#import "Keyboard.h"

#include <objc/runtime.h>
#import <UIKit/UIDefaultKeyboardInput.h>

@interface TextInputHandler : UIDefaultKeyboardInput
{
    ShellKeyboard *shellKeyboard;
}

- (id)initWithKeyboard:(ShellKeyboard *)keyboard;

@end

@implementation TextInputHandler

- (id)initWithKeyboard:(ShellKeyboard *)keyboard;
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

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation ShellKeyboard

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self ) {
        handler = [[TextInputHandler alloc] initWithKeyboard:self];
    }
    return self;
}

- (void)dealloc
{
    [handler release];
    [super dealloc];
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

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
