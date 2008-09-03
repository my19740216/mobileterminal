// MobileTerminal.h
#define DEBUG_METHOD_TRACE 0

#include "MobileTerminal.h"

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <QuartzCore/CoreAnimation.h>
#import <UIKit/UIScreen.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UIWindow.h>

#import "ColorMap.h"
#import "GestureView.h"
#import "Keyboard.h"
#import "MainViewController.h"
#import "Menu.h"
#import "PieView.h"
#import "Preferences.h"
#import "PTYTextView.h"
#import "Settings.h"
#import "SubProcess.h"
#import "VT100Screen.h"
#import "VT100Terminal.h"


@implementation MobileTerminal

@synthesize scrollers;
@synthesize activeTerminalIndex;

@synthesize landscape;
@synthesize controlKeyMode;
@synthesize menu;

@synthesize numTerminals;

+ (MobileTerminal *)application
{
    return [UIApplication sharedApplication];
}

+ (Menu *)menu
{
    return [[UIApplication sharedApplication] menu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)unused
{
    settings = [[Settings sharedInstance] retain];
    [settings registerDefaults];
    [settings readUserDefaults];

    menu = [[Menu menuWithArray:[settings menu]] retain];

    mainController = [[MainViewController alloc] init];

    // --------------------------------------------------------- setup terminals

    processes = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
    screens = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
    terminals = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];

    for (numTerminals = 0; numTerminals < ([settings multipleTerminals] ? MAXTERMINALS : 1); numTerminals++) {
        VT100Screen *screen = [[VT100Screen alloc] initWithIdentifier: numTerminals];
        [screens addObject: screen];

        VT100Terminal *terminal = [[VT100Terminal alloc] init];
        [terminals addObject:terminal];
        [screen setTerminal:terminal];
        [terminal setScreen:screen];
        [terminal release];

        SubProcess *process = [[SubProcess alloc] initWithDelegate:self identifier:numTerminals];
        [processes addObject:process];
        [process release];

        [mainController addViewForTerminalScreen:screen];
        [screen release];
    }

    // ------------------------------------------------------------- setup views
 
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [window addSubview:[mainController view]];
    [window makeKeyAndVisible];

    if (numTerminals > 1) {
        for (int i = numTerminals - 1; i >= 0; i--)
            [self setActiveTerminal:i];
    } else {
        [mainController updateFrames:YES];
    }
}

#pragma mark Application events methods

- (void)applicationResume:(GSEvent *)event
{
    // FIXME: why not set to activeTerminalIndex?
    //        why switch at all?
    [self setActiveTerminal:0];
}

- (void)applicationSuspend:(GSEvent *)event
{
    [settings writeUserDefaults];

    BOOL shouldQuit = YES;
    for (SubProcess *sp in processes) {
        if ([sp isRunning]) {
            shouldQuit = NO;
            break;
        }
    }

    if (shouldQuit) {
        exit(0);
    } else {
        // FIXME: seems to not handle statusbar correctly
        if (self.activeView != [mainController view]) // preferences active
            [self togglePreferences];

        for (int i = 0; i < MAXTERMINALS; i++)
            [self removeStatusBarImageNamed:
                 [NSString stringWithFormat:@"MobileTerminal%d", i]];
    }
}

- (void)applicationExited:(GSEvent *)event
{
    [settings writeUserDefaults];

    for (SubProcess *sp in processes)
        [sp close];

    for (int i = 0; i < MAXTERMINALS; i++)
        [self removeStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal%d", i]];
}

#pragma mark IO handling methods

// Process output from the shell and pass it to the screen
- (void)handleStreamOutput:(const char *)c length:(unsigned int)len identifier:(int)tid
{
    if (tid < 0 || tid >= [terminals count]) {
        return;
    }

    VT100Terminal *terminal = [terminals objectAtIndex: tid];
    VT100Screen *screen = [screens objectAtIndex: tid];

    [terminal putStreamData:c length:len];

    // Now that we've got the raw data from the sub process, write it to the
    // terminal. We get back tokens to display on the screen and pass the
    // update in the main thread.
    VT100TCC token;
    while((token = [terminal getNextToken]),
            token.type != VT100_WAIT && token.type != VT100CC_NULL) {
        // process token
        if (token.type != VT100_SKIP) {
            if (token.type == VT100_NOTSUPPORT) {
                NSLog(@"%s(%d):not support token", __FILE__ , __LINE__);
            } else {
                [screen putToken:token];
            }
        } else {
            NSLog(@"%s(%d):skip token", __FILE__ , __LINE__);
        }
    }

    if (tid == activeTerminalIndex) {
        [[mainController activeTextView] performSelectorOnMainThread:@selector(updateAndScrollToEnd)
                                          withObject:nil
                                       waitUntilDone:NO];
    }
}

// Process input from the keyboard
- (void)handleKeyPress:(unichar)c
{
    if (!controlKeyMode) {
        if (c == 0x2022) {
            controlKeyMode = YES;
            return;
        } else if (c == 0x0a) // LF from keyboard RETURN
        {
            c = 0x0d; // convert to CR
        }
    } else {
        // was in ctrl key mode, got another key
        if (c < 0x60 && c > 0x40) {
            // Uppercase
            c -= 0x40;
        } else if (c < 0x7B && c > 0x60) {
            // Lowercase
            c -= 0x60;
        }
        [self setControlKeyMode:NO];
    }
    // Not sure if this actually matches anything. Maybe support high bits later?
    if ((c & 0xff00) != 0) {
        NSLog(@"Unsupported unichar: %x", c);
        return;
    }
    char simple_char = (char)c;

    [[self activeProcess] write:&simple_char length:1];
}

#pragma mark StatusBar methods

- (void)setStatusBarHidden:(BOOL)hidden duration:(double)duration
{
    [self setStatusBarMode:(hidden ? 104 : 0) duration:duration];
    [self setStatusBarHidden:hidden animated:NO];
}

- (void)statusBarMouseUp:(GSEvent *)event
{
    if (numTerminals > 1) {
        CGPoint pos = GSEventGetLocationInWindow(event).origin;
        float width = landscape ? window.frame.size.height : window.frame.size.width;
        if (pos.x > width/2 && pos.x < width *3/4) {
            [self prevTerminal];
        } else if (pos.x > width *3/4) {
            [self nextTerminal];
        } else {
            if (self.activeView == [mainController view])
                [self togglePreferences];
        }
    } else {
        if (self.activeView == [mainController view])
            [self togglePreferences];
    }
}

#pragma mark Gesture view methods

- (CGPoint)viewPointForWindowPoint:(CGPoint)point
{
    return [window convertPoint:point toView:self.activeView];
}

#pragma mark MenuView delegate methods

- (void)hideMenu
{
    [[MenuView sharedInstance] hide];
}

- (void)showMenu:(CGPoint)point
{
    [[MenuView sharedInstance] showAtPoint:point];
}

- (void)handleInputFromMenu:(NSString *)input
{
    if (input == nil) return;

    if ([input isEqualToString:@"[CTRL]"]) {
        if (![[MobileTerminal application] controlKeyMode])
            [[MobileTerminal application] setControlKeyMode:YES];
    } else if ([input isEqualToString:@"[KEYB]"]) {
        [[MobileTerminal application] toggleKeyboard];
    } else if ([input isEqualToString:@"[NEXT]"]) {
        [[MobileTerminal application] nextTerminal];
    } else if ([input isEqualToString:@"[PREV]"]) {
        [[MobileTerminal application] prevTerminal];
    } else if ([input isEqualToString:@"[CONF]"]) {
        [[MobileTerminal application] togglePreferences];
    } else {
        [[self activeProcess] write:[input UTF8String] length:[input length]];
    }
}

- (void)toggleKeyboard
{
    [mainController toggleKeyboard];
}

- (void)setControlKeyMode:(BOOL)mode
{
    controlKeyMode = mode;
    [[mainController activeTextView] refreshCursorRow];
}

#pragma mark Terminal methods

- (void)setActiveTerminal:(int)terminal
{
    [self setActiveTerminal:terminal direction:0];
}

- (void)setActiveTerminal:(int)terminal direction:(int)direction
{
    activeTerminalIndex = terminal;
    [mainController switchToTerminal:terminal direction:direction];
}

- (void)prevTerminal
{
    if (numTerminals > 1) {
        int active = activeTerminalIndex - 1;
        if (active < 0)
            active = numTerminals-1;
        [self setActiveTerminal:active direction:-1];
    }
}

- (void)nextTerminal
{
    if (numTerminals > 1) {
        int active = activeTerminalIndex + 1;
        if (active >= numTerminals)
            active = 0;
        [self setActiveTerminal:active direction:1];
    }
}

- (void)createTerminals
{
    for (numTerminals = 1; numTerminals < MAXTERMINALS; numTerminals++) {
        VT100Terminal *terminal = [[VT100Terminal alloc] init];
        VT100Screen *screen = [[VT100Screen alloc] initWithIdentifier: numTerminals];
        SubProcess *process = [[SubProcess alloc] initWithDelegate:self identifier: numTerminals];

        [screens addObject: screen];
        [terminals addObject: terminal];
        [processes addObject: process];
        // FIXME: why was this being added twice? necessary?
        //[processes addObject: process];

        [screen setTerminal:terminal];
        [terminal setScreen:screen];

        [mainController addViewForTerminalScreen:screen];
        [screen release];
    }

    [self addStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal0"] removeOnAbnormalExit:YES];
}

- (void)destroyTerminals
{
    [self setActiveTerminal:0];

    [self removeStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal0"]];

    for (numTerminals = MAXTERMINALS; numTerminals > 1; numTerminals--) {
        SubProcess *process = [processes lastObject];
        [process closeSession];

        [screens removeLastObject];
        [terminals removeLastObject];
        [processes removeLastObject];
        [mainController removeViewForLastTerminal];
    }
}

#pragma mark App/Preferences switching methods

#if 0
- (void)togglePreferences
{
    if (activeView == [mainController view]) {
        preferencesController = [[PreferencesController alloc] init];
        //if (landscape) [self setOrientation:0];
        [contentView transition:0 toView:[preferencesController view]];
        activeView = [preferencesController view];
        //[keyboardView setEnabled:NO];
    } else {
        [contentView transition:0 toView:[mainController view]];
        activeView = [mainController view];

        [settings writeUserDefaults];
        [mainController updateColors];
        //[gestureView setNeedsDisplay];

        if (numTerminals > 1 && ![settings multipleTerminals]) {
            [self destroyTerminals];
        } else if (numTerminals == 1 && [settings multipleTerminals]) {
            [self createTerminals];
        }

        //[keyboardView setEnabled:YES];
    }

    CAAnimation *animation = [CATransition animation];
    [animation performSelector:@selector(setType:) withObject:@"oglFlip"];
    [animation performSelector:@selector(setSubtype:) withObject:(activeView == [mainController view]) ? @"fromRight" : @"fromLeft"];
    [animation performSelector:@selector(setTransitionFlags:) withObject:[NSNumber numberWithInt:3]];
    [animation setTimingFunction: [CAMediaTimingFunction functionWithName: @"easeInEaseOut"]];
    [animation setSpeed: 0.25f];
    [contentView addAnimation:(id)animation forKey:@"flip"];
}
#endif

- (void)togglePreferences
{
    if (self.activeView == [mainController view]) {
        preferencesController = [[PreferencesController alloc] init];
        if ([self orientation] % 180 != 0) {
            viewWasLandscape_ = [self statusBarOrientation];
            [self setStatusBarOrientation:1 animated:YES];
        }
    } else {
        if (viewWasLandscape_) {
            [self setStatusBarOrientation:viewWasLandscape_ animated:YES];
            viewWasLandscape_ = 0;
        }
    }

#define fromRight 1
#define fromLeft 2

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.75f];
    [UIView setAnimationTransition:((self.activeView == [mainController view]) ? fromRight : fromLeft)
                           forView:window cache:YES];
    [UIView setAnimationDelegate:self];

    if (self.activeView == [mainController view]) {
        [[mainController view] removeFromSuperview];
        [window addSubview:[preferencesController view]];
    } else {
        [[preferencesController view] removeFromSuperview];
        [window addSubview:[mainController view]];
    }

	[UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if ([window contentView] == [mainController view]) {
        // The Preferences view has just been closed, release it
        [preferencesController release];
        preferencesController = nil;

        // FIXME: put this in preferences
        [settings writeUserDefaults];

        // reload settings
        [mainController updateColors];
        //[gestureView setNeedsDisplay];

        if (numTerminals > 1 && ![settings multipleTerminals])
            [self destroyTerminals];
        else if (numTerminals == 1 && [settings multipleTerminals])
            [self createTerminals];
    }
}

#pragma mark Properties

- (SubProcess *)activeProcess
{
    return [processes objectAtIndex:activeTerminalIndex];
}

- (VT100Screen *)activeScreen
{
    return [screens objectAtIndex:activeTerminalIndex];
}

- (VT100Terminal *)activeTerminal
{
    return [terminals objectAtIndex:activeTerminalIndex];
}

- (UIView *)activeView
{
    return [[window subviews] objectAtIndex:0];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
