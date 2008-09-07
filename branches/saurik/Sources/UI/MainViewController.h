//
// MainViewController.h
// Terminal

#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIViewController.h>

@class GestureView;
@class MenuView;
@class MobileTerminal;
@class NSMutableArray;
@class PieView;
@class PTYTextView;
@class ShellKeyboard;
@class UIScroller;
@class UIView;
@class VT100Screen;

@interface MainViewController : UIViewController
{
    MobileTerminal *application;

    UIView *mainView;
    ShellKeyboard *keyboardView;
    GestureView *gestureView;
    PieView *pieView;
    MenuView *menuView;

    NSMutableArray *textviews;
    NSMutableArray *scrollers;

    int activeTerminal;

    @private
        int orientation_;
}

@property(nonatomic, readonly) PTYTextView *activeTextView;
@property(nonatomic, readonly) UIScroller *activeScroller;

- (void)toggleKeyboard;

- (void)showPie:(CGPoint)point;
- (void)hidePie;

- (void)showMenu:(CGPoint)point;
- (void)hideMenu;

- (void)addViewForTerminalScreen:(VT100Screen *)screen;
- (void)removeViewForLastTerminal;
- (void)switchToTerminal:(int)terminal direction:(int)direction;

- (void)updateColors;
- (void)updateFrames:(BOOL)needsRefresh;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
