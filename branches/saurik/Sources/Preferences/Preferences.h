//
//  Preferences.h
//  Terminal

#import <UIKit/UINavigationController.h>

@class MobileTerminal;

@interface PreferencesController : UINavigationController 
{
    MobileTerminal *application;
    UIViewController *prefsPage;
    int terminalIndex;
}

@property(nonatomic) int terminalIndex;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
