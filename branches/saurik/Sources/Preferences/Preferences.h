//
//  Preferences.h
//  Terminal

#import <UIKit/UINavigationController.h>

@class MobileTerminal;

@class AboutPage;
@class ColorPage;
@class FontPage;
@class GesturePrefsPage;
@class MenuPrefsPage;
@class SettingsPage;

@interface PreferencesController : UINavigationController 
{
    MobileTerminal * application;

    int terminalIndex;
}
@property(nonatomic) int terminalIndex;

+ (PreferencesController *)sharedInstance;

- (id)init;

- (void)setFontSize:(int)size;
- (void)setFontWidth:(float)width;
- (void)setFont:(NSString *)font;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
