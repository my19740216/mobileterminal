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
@class MainViewController;
@class PreferencesController;
@class MobileTerminal;
@class Settings;
@class Menu;

@interface MobileTerminal : UIApplication
{
    UIWindow *window;

    MainViewController *mainController;
    PreferencesController *preferencesController;

    NSMutableArray *processes;
    NSMutableArray *screens;
    NSMutableArray *terminals;

    Settings *settings;
    Menu *menu;

    int numTerminals;
    int activeTerminalIndex;

    BOOL controlKeyMode;
    BOOL landscape;
}

@property BOOL landscape;

@property(readonly) NSArray *scrollers;
@property BOOL controlKeyMode;
@property(readonly) Menu *menu;
@property(readonly) int numTerminals;
@property(nonatomic, readonly, getter=indexOfActiveTerminal) int activeTerminalIndex;

@property(nonatomic, readonly) SubProcess *activeProcess;
@property(nonatomic, readonly) VT100Screen *activeScreen;
@property(nonatomic, readonly) VT100Terminal *activeTerminal;
@property(nonatomic, readonly) UIView *activeView;

+ (MobileTerminal *)application;
+ (Menu *)menu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationSuspend:(GSEvent *)event;
- (void)applicationResume:(GSEvent *)event;

- (void)handleStreamOutput:(const char *)c length:(unsigned int)len identifier:(int)tid;
- (void)handleKeyPress:(unichar)c;

- (void)togglePreferences;

- (void)setStatusBarHidden:(BOOL)hidden duration:(double)duration;

// Invoked by MenuView
- (void)handleInputFromMenu:(NSString *)input;

// Invoked by SwitcherMenu
- (void)setActiveTerminal:(int)terminal;
- (void)setActiveTerminal:(int)terminal direction:(int)direction;
- (void)prevTerminal;
- (void)nextTerminal;
- (void)createTerminals;
- (void)destroyTerminals;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
