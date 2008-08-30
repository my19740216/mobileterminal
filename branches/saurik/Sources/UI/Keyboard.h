// ShellKeyboard.h

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKeyboard.h>


@protocol KeyboardInputProtocol

- (void)handleKeyPress:(unichar)c;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface ShellKeyboard : UIKeyboard<KeyboardInputProtocol>
{
    id inputDelegate;
    id handler;
    BOOL visible;
}

@property(nonatomic, assign) id inputDelegate;
@property(nonatomic, readonly, getter=isVisible) BOOL visible;

- (id)initWithDefaultRect;
- (void)handleKeyPress:(unichar)c;
- (void)setEnabled:(BOOL)enabled;
- (void)setVisible:(BOOL)visible animated:(BOOL)animated;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
