// Common.h
#import <Foundation/Foundation.h>

#define DEBUG
#ifdef DEBUG
  #define debug(...) NSLog(__VA_ARGS__)
#else
  #define debug(...)
#endif

// The terminal height and width are determined by trial and error based on
// the font size
#define TERMINAL_WIDTH 43
#define TERMINAL_HEIGHT 17
#define COREGRAPHICS_DRAW

#ifdef COREGRAPHICS_DRAW
#define TERMINAL_FONT "CourierNewBold"
#endif
#ifdef NSSTRING_DRAW
#define TERMINAL_FONT \
  @"font-family:CourierNewBold; font-size: 12px; color:white;"
#endif
