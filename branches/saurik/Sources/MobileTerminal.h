//
// MobileTerminal.h
// Terminal

#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/UIKit.h>

#import "Constants.h"
#import "Log.h"

@class PTYTextView;
@class ShellKeyboard;
@class SubProcess;
@class VT100Screen;
@class VT100Terminal;
@class GestureView;
@class PieView;
@class PreferencesController;
@class MobileTerminal;
@class Settings;
@class Menu;

@interface MobileTerminal : UIApplication
{
    UIWindow *window;

    ShellKeyboard *keyboardView;
    UITransitionView *contentView;
    UIView *mainView;

    UIView *activeView;

    GestureView *gestureView;

    PreferencesController *preferencesController;

    NSMutableArray *processes;
    NSMutableArray *screens;
    NSMutableArray *terminals;
    NSMutableArray *textviews;
    NSMutableArray *scrollers;

    Settings *settings;
    Menu *menu;

    int numTerminals;
    int activeTerminal;

    BOOL controlKeyMode;
    BOOL keyboardShown;
    BOOL landscape;
    int degrees;
}

@property BOOL landscape;
@property int degrees;
@property BOOL controlKeyMode;
@property(readonly) Menu *menu;
@property(readonly) PTYTextView *textView;

+ (MobileTerminal *)application;
+ (Menu *)menu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationSuspend:(GSEvent *)event;
- (void)applicationResume:(GSEvent *)event;

- (void)handleStreamOutput:(const char *)c length:(unsigned int)len identifier:(int)tid;
- (void)handleKeyPress:(unichar)c;

- (void)updateStatusBar;
- (void)updateColors;
- (void)updateFrames:(BOOL)needsRefresh;
- (void)setOrientation:(int)degrees;
- (CGPoint)viewPointForWindowPoint:(CGPoint)point;

- (SubProcess *)activeProcess;
- (VT100Screen *)activeScreen;
- (VT100Terminal *)activeTerminal;
- (NSArray *)textviews;

- (UIScroller *)textScroller;
- (CGRect)keyboardFrame;

- (void)togglePreferences;

// Invoked by MenuView
- (void)hideMenu;
- (void)showMenu:(CGPoint)point;
- (void)handleInputFromMenu:(NSString *)input;
- (void)toggleKeyboard;

// Invoked by SwitcherMenu
- (void)prevTerminal;
- (void)nextTerminal;
- (void)createTerminals;
- (void)destroyTerminals;
- (void)setActiveTerminal:(int)active;
- (void)setActiveTerminal:(int)active direction:(int)direction;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
