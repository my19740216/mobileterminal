#import "MainViewController.h"

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIColor.h>
#import <UIKit/UIScreen.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>

#import "ColorMap.h"
#import "GestureView.h"
#import "Keyboard.h"
#import "Menu.h"
#import "MobileTerminal.h"
#import "PieView.h"
#import "PTYTextView.h"
#import "Settings.h"
#import "SubProcess.h"
#import "VT100Screen.h"
#import "VT100Terminal.h"

#define WidthSizable 2
#define HeightSizable 16


@implementation MainViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        application = [MobileTerminal application];
        textviews = [[NSMutableArray alloc] initWithCapacity:MAXTERMINALS];
    }
    return self;
}
    
- (void)loadView
{
    // ---------------------------------------------------------------- keyboard
 
    keyboardView = [[ShellKeyboard alloc] initWithDefaultRect];
    [keyboardView setInputDelegate:application];
    [keyboardView setAnimationDelegate:self];

    // ------------------------------------------------------- gesture indicator

    pieView = [PieView sharedInstance];
    [pieView hide];

    // ----------------------------------------------------------- gesture frame

    gestureView = [[GestureView alloc] initWithFrame:CGRectMake(0, 0, 240.0f, 250.0f)
        delegate:self];
    [gestureView setBackgroundColor:[UIColor clearColor]];

    // -------------------------------------------------------------- popup menu

    menuView = [MenuView sharedInstance];
    [menuView setCenter:CGPointMake(160.0f, 142.0f)];
    [menuView setActivated:YES];

    // --------------------------------------------------------------- main view
 
    mainView = [[UIView alloc]
        initWithFrame:[[UIScreen mainScreen] bounds]];
    [mainView setAutoresizingMask:WidthSizable|HeightSizable];

    // NOTE: the order of the views is important, as they overlap
    [mainView addSubview:keyboardView];
    [mainView addSubview:pieView];
    [mainView addSubview:gestureView];
    [mainView addSubview:menuView];
    [self setView:mainView];

    // Shows momentarily and hides so the user knows its there
    [menuView hideSlow:YES];

    // Enable the keyboard
    [keyboardView setEnabled:YES];
}

- (void)dealloc
{
    [mainView release];
    [gestureView release];
    [keyboardView release];

    [textviews release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewDidDisappear:(BOOL)animated
{
}

- (void)applicationWillSuspend
{
    //[keyboardView setEnabled:NO];
}

- (void)applicationDidResume
{
    // NOTE: sometimes when resuming, the views are out-of-order
    [mainView bringSubviewToFront:gestureView];
    [mainView bringSubviewToFront:menuView];

    [keyboardView setEnabled:YES];
}

#pragma mark Other

- (void)updateColors
{
    for (int i = 0; i < application.numTerminals; i++) {
        TerminalConfig *config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:i];
        for (int c = 0; c < NUM_TERMINAL_COLORS; c++)
            [[ColorMap sharedInstance] setTerminalColor:config.colors[c] atIndex:c termid:i];
        // FIXME: this does not appear to be getting set properly
        [[textviews objectAtIndex:i] setBackgroundColor:[[ColorMap sharedInstance] colorForCode:BG_COLOR_CODE termid:i]];
        [[[textviews objectAtIndex:i] tiledView] setNeedsDisplay];
    }
    [mainView setBackgroundColor:[self.activeTextView backgroundColor]];

    [self updateFrames:YES];
}

#pragma mark Terminal view methods

- (void)addViewForTerminal:(Terminal *)terminal
{
    PTYTextView *textview = [[PTYTextView alloc]
        initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 244.0f)
               source:terminal.screen identifier:terminal.identifier];
    [textview setBackgroundColor:[[ColorMap sharedInstance]
        colorForCode:BG_COLOR_CODE termid:[application numTerminals]]];
    [textviews addObject:textview];
    [textview release];
}

- (void)resetViewForTerminal:(int)index
{
    // FIXME: this method has not been properly defined yet
    [[[textviews objectAtIndex:index] tiledView] removeFromSuperview];
    [textviews removeObjectAtIndex:index];
}

- (void)removeViewForLastTerminal
{
    [[[textviews lastObject] tiledView] removeFromSuperview];
    [textviews removeLastObject];
}

- (void)switchToTerminal:(int)terminal direction:(int)direction
{
    [self.activeTextView.tiledView willSlideOut];

    if (direction) {
        [UIView beginAnimations:@"slideOut"];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:
              @selector(activeViewDidChange:finished:context:)];
        [self.activeTextView setTransform:
            CGAffineTransformMakeTranslation(-direction * [mainView frame].size.width, 0)];
        [UIView commitAnimations];
    } else {
        [self.activeTextView setTransform:CGAffineTransformMakeTranslation(-[mainView frame].size.width,0)];
    }

    if (application.numTerminals > 1) {
        [application removeStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal%d", activeTerminal]];
        [application addStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal%d", terminal]
            removeOnAbnormalExit:YES];
    }
    activeTerminal = terminal;
    [mainView insertSubview:self.activeTextView below:keyboardView];
    [mainView setBackgroundColor:[self.activeTextView backgroundColor]];

    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, 0);
    if (direction) {
        [self.activeTextView setTransform:
            CGAffineTransformMakeTranslation(direction * [mainView frame].size.width, 0)];

        [UIView beginAnimations:@"slideIn"];
        [self.activeTextView setTransform:transform];
        [UIView commitAnimations];
    } else {
        [self.activeTextView setTransform:transform];
    }

    [self updateFrames:YES];

    [self.activeTextView.tiledView willSlideIn];
}

#pragma mark Keyboard display methods

- (void)toggleKeyboard
{
    [keyboardView setVisible:![keyboardView isVisible] animated:YES];
}

- (void)keyboardDidAppear:(NSString *)animationID finished:(NSNumber *)finished
    context:(void *)context
{
    [self updateFrames:NO];
}

- (void)keyboardDidDisappear:(NSString *)animationID finished:(NSNumber *)finished
    context:(void *)context
{
    [self updateFrames:NO];
}

#pragma mark Pie display methods

- (void)showPie:(CGPoint)point
{
    [pieView showAtPoint:point];
}

- (void)hidePie
{
    [pieView hide];
}

#pragma mark Menu display methods

- (void)showMenu:(CGPoint)point
{
    [menuView showAtPoint:point];
}

- (void)hideMenu
{
    [menuView hide];
}

#pragma mark Orientation-handling methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(int)orientation
{
    if ( [self interfaceOrientation] != orientation ) {
        targetOrientation_ = orientation;

        [application setStatusBarHidden:YES duration:0.1f];

        // Fade out
        [UIView beginAnimations:nil];
        [UIView setAnimationDuration:0.1f];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:
            @selector(viewDidFadeOut:finished:context:)];
        [keyboardView setAlpha:0.0f];
        [self.activeTextView.tiledView setAlpha:0.0f];
        [UIView commitAnimations];
    }

    return NO;
}

- (void)viewDidFadeOut:(NSString *)animationID finished:(NSNumber *)finished
    context:(void *)context
{
    // NOTE: The following method is normally called when YES is returned from
    //       shouldAutorotateToInterfaceOrientation. It causes the content view
    //       to rotate and resize with a fixed animation and duration, and sets
    //       the interfaceOrientation property of the window.
    //
    //       Unfortunately, it also modifies both the transform and the superview
    //       of the UIKeyboard object, thus affecting positioning, and so these
    //       properties must be reset afterwards.

    [[mainView window] _setRotatableViewOrientation:targetOrientation_ duration:0];
}

- (void)didRotateFromInterfaceOrientation:(int)orientation
{
    // Restore the correct superview for the keyboard (workaround for above bug)
    [mainView insertSubview:keyboardView below:gestureView];

    [keyboardView updateGeometry];
    [self updateFrames:YES];

    [application setStatusBarHidden:NO duration:0.1f];

    // Fade in
    [UIView beginAnimations:nil];
    [UIView setAnimationDuration:0.1f];
    [keyboardView setAlpha:1.0f];
    [self.activeTextView.tiledView setAlpha:1.0f];
    [UIView commitAnimations];
}

#pragma mark Other animation-handling methods

- (void)activeViewDidChange:(NSString *)animationID finished:(NSNumber *)finished
    context:(void *)context
{
    for (int i = 0; i < application.numTerminals; i++)
        if (i != activeTerminal)
            [[textviews objectAtIndex:i] removeFromSuperview];
}

#pragma mark Geometry methods

// FIXME: should rename to standart layoutSubviews?
- (void)updateFrames:(BOOL)needsRefresh
{
    // FIXME: Upon switching to preferences when not in portrait orientation,
    //        the mainView height is reported minus the statusbar height.
    //        This causes the text/scroller view to be misaligned.
    //        Need to find a proper way to detect this case.

    // Calculate the available width and height
    float statusBarHeight = [UIHardware statusBarHeight];
    float availableWidth = mainView.bounds.size.width;
    float availableHeight = mainView.bounds.size.height - statusBarHeight;
    if ([keyboardView isVisible]) {
        CGSize keybSize =
            [UIKeyboard defaultSizeForOrientation:[keyboardView orientation]];
        availableHeight -= keybSize.height;
    }

    CGRect textScrollerFrame = CGRectMake(0, statusBarHeight, availableWidth, availableHeight);
    [self.activeTextView updateFrame:textScrollerFrame];

    CGFloat tiledViewWidth = [self.activeTextView.tiledView bounds].size.width;
    CGRect gestureFrame = CGRectMake(0, statusBarHeight, availableWidth - 40.0f,
            availableHeight - (tiledViewWidth > availableWidth ? 40.0f : 0));
    [gestureView setFrame:gestureFrame];
    [gestureView setNeedsDisplay];

    if (needsRefresh) {
        [self.activeTextView.tiledView refresh];
        [self.activeTextView.tiledView updateIfNecessary];
    }
}

#pragma mark Properties

- (PTYTextView *)activeTextView
{
    return [textviews objectAtIndex:activeTerminal];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
