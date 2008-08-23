//
// Settings.h
// Terminal

#import <Foundation/Foundation.h>

#import "Color.h"
#import "Constants.h"

@interface TerminalConfig : NSObject
{
    int width;
    int fontSize;
    float fontWidth;
    BOOL autosize;

    NSString *font;
    NSString *args;

    UIColor *_colors[NUM_TERMINAL_COLORS];
}

- (NSString *)fontDescription;
- (UIColor **)colors;

@property (getter = colors) UIColor **colors;
@property BOOL autosize;
@property int width;
@property int fontSize;
@property float fontWidth;
@property (readwrite, copy) NSString *font;
@property (readwrite, copy) NSString *args;

@end

@interface Settings : NSObject
{
    NSString *arguments;
    NSArray *terminalConfigs;
    NSArray *menu;
    UIColor *gestureFrameColor;
    BOOL multipleTerminals;
    NSMutableDictionary *swipeGestures;
}

@property(nonatomic, retain) UIColor *gestureFrameColor;
@property BOOL multipleTerminals;

+ (Settings *)sharedInstance;

- (id)init;

- (void)registerDefaults;
- (void)readUserDefaults;
- (void)writeUserDefaults;

- (NSArray *)terminalConfigs;
- (void)setArguments:(NSString *)arguments;
- (NSString *)arguments;
- (NSArray *)menu;
- (NSDictionary *)swipeGestures;
- (void)setCommand:(NSString *)command forGesture:(NSString *)zone;
- (UIColor **)gestureFrameColorRef;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
