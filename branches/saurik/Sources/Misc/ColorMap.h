// ColorMap.h
//
// ColorMap is not at all thread safe.

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "Constants.h"

@class UIColor;

enum {
  BG_COLOR = 16,
  FG_COLOR,
  FG_COLOR_BOLD,
  FG_COLOR_CURSOR,
  BG_COLOR_CURSOR,
  NUM_COLORS = BG_COLOR + MAXTERMINALS *  NUM_TERMINAL_COLORS,
};

@interface ColorMap : NSObject
{
  UIColor *table[NUM_COLORS];
}

+ (ColorMap*)sharedInstance;
- (UIColor *)colorForCode:(unsigned int)index termid:(int)termid;
- (void)setTerminalColor:(UIColor *)color atIndex:(int)index termid:(int)termid;

@end
