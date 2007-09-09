// PTYTextView.m
#define DEBUG_ALLOC           0 
#define DEBUG_METHOD_TRACE    0 

#import "PTYTextView.h"
#import <UIKit/NSString-UIStringDrawing.h>
#import "VT100Screen.h"
#import "ColorMap.h"
#import "PTYTile.h"
#import "Settings.h"

#include <sys/time.h>

static PTYTextView* instance = nil;

@implementation PTYTextView

+ (PTYTextView*)sharedInstance
{
  if (instance == nil) {
    [NSException raise:@"Uninitialized"
                format:@"sharedInstance was not initalized yet"];
  }
  return instance;
}

+ (Class)tileClass
{
  return [PTYTile class];
}

- (id)initWithFrame:(CGRect)frame
             source:(VT100Screen*)screen
           scroller:(UIScroller*)scroller
{
#if DEBUG_ALLOC
  NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
  if (instance != nil) {
    [NSException raise:@"Unsupported" format:@"Only one PTYTextView"];
  }
  self = [super initWithFrame:frame];
  instance = self;
  CURSOR = YES;
  dataSource = screen;

  textScroller = scroller;
  [textScroller addSubview:self];
  [textScroller setAllowsRubberBanding:YES];
  [textScroller displayScrollerIndicators];
  [textScroller setBottomBufferHeight:5.0];
  [textScroller setBounces:YES];
  [textScroller setContentSize:frame.size];
  [textScroller setScrollerIndicatorStyle:kUIScrollerIndicatorWhite];

  [self refresh];

  // Create one tile per row
  _tileSize = CGSizeMake(frame.size.width, lineHeight);
  _firstTileSize = _tileSize;

  [self setOpaque:YES];
  [self setTilingEnabled:YES];
  [self setTileDrawingEnabled:YES];
  return self;
}

- (void)dealloc
{
#if DEBUG_ALLOC
  NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
  [super dealloc];

#if DEBUG_ALLOC
  NSLog(@"%s: 0x%x, done", __PRETTY_FUNCTION__, self);
#endif
}

- (void)logRect:(struct CGRect)rect;
{
  NSLog(@"(%f,%f) -> (%f,%f)", rect.origin.x, rect.origin.y,
        rect.size.width, rect.size.height);
}

- (void)refresh
{
  id temp = dataSource;
  [temp acquireLock];
  int WIDTH = [dataSource width];
  int HEIGHT = [dataSource height];
  [temp releaseLock];

  CGRect frame = [self frame];
  charWidth = floor(frame.size.width / WIDTH);
  float availableHeight = frame.size.height - [textScroller bottomBufferHeight];
  lineHeight = floor(availableHeight / HEIGHT);

  // TODO: Use margins on either side
  margin = floor((frame.size.width - (charWidth * WIDTH)) / 2);
  vmargin = floor((frame.size.height - (lineHeight * HEIGHT)) / 2);
}

- (void)updateIfNecessary
{
  [dataSource acquireLock];
  int width = [dataSource width];
  int height = [dataSource height];
  int lines = [dataSource numberOfLines];

  // Expand the height, and cause scroll
  int newHeight = lines * lineHeight;
  CGRect frame = [self frame];
  if (frame.size.height != newHeight) {
    frame.size.height = newHeight;
    [self setFrame:frame];
    [textScroller setContentSize:frame.size];
  }
  int startIndex = 0;
  if (lines > height) {
    startIndex = lines - height;
  }

  // Check for dirty on-screen rows; scroll back is not updated
  int row;
  int column;
  for (row = 0; row < height; row++) {
    BOOL redraw_row = NO;
    const char* dirty = [dataSource dirty] + row * width;
    for (column = 0; column < width; column++) {
      char c = dirty[column];
      if (c) {
        redraw_row = YES;
        break;
      }
    }
    if (redraw_row) {
      CGRect rect = CGRectMake(0, (startIndex + row) * lineHeight,
                               [self frame].size.width, lineHeight);
      [self setNeedsDisplayInRect:rect];
    }
  }

  [dataSource resetDirty];
  [dataSource releaseLock];
}

- (void)updateAndScrollToEnd
{
  [self updateIfNecessary];

  [dataSource acquireLock];
  int height = [dataSource height];
  int lines = [dataSource numberOfLines];
  int scrollIndex = height;
  if (lines > height) {
    scrollIndex = lines - height;
  }
  float visiblePoint =
    [self frame].size.height + [textScroller bottomBufferHeight];
  CGRect visibleRect = CGRectMake(0, visiblePoint, 0, 0);
  [textScroller scrollRectToVisible:visibleRect animated:YES];
  [dataSource releaseLock];
}

- (void)drawTileFrame:(CGRect)frame tileRect:(CGRect)rect
{
  // Each Tile is responsible for one row so determine the row that this
  // tile is responsible for based on its bounding rectangle.
  int row = (int)((frame.origin.y - [self frame].origin.y) / lineHeight);
  [self drawRow:row tileRect:(CGRect)rect];
}

- (void)setupTextForContext:(CGContextRef)context
{
  const char* font = [[[Settings sharedInstance] font] cString];
  CGContextSelectFont(context, font, lineHeight, kCGEncodingMacRoman);
  CGContextSetRGBFillColor(context, 1, 1, 1, 1);
  CGContextSetTextDrawingMode(context, kCGTextFill);
  // Flip text, for some reason its written upside down by default
  CGAffineTransform translate =
    CGAffineTransformMake(1, 0, 0, -1, 0, 1.0);
  CGContextSetTextMatrix(context, translate);
}

- (void)drawBox:(CGContextRef)context
          color:(CGColorRef)color
        boxRect:(CGRect)rect
{
  const float* components = CGColorGetComponents(color);
  CGContextSetRGBFillColor(context, components[0], components[1],
                                    components[2], components[3]);
  CGContextFillRect(context, rect);
}

- (void)drawChar:(CGContextRef)context
       character:(char)c
           color:(CGColorRef)color
           point:(CGPoint)point
{
  const float* components = CGColorGetComponents(color);
  CGContextSetRGBFillColor(context, components[0], components[1],
                                    components[2], components[3]);
  // TODO: Consider adjusting the text point based on the rotation above
  CGContextShowTextAtPoint(context, point.x, point.y, &c, 1);
}

- (void)drawRow:(unsigned int)row tileRect:(CGRect)rect
{
  CGContextRef context = UICurrentContext();
  rect.origin.x += margin;

  [dataSource acquireLock];

  CGRect charRect = CGRectMake(rect.origin.x, rect.origin.y,
                               charWidth, lineHeight);

  // Draw background for each column in the row
  int width = [dataSource width];
  screen_char_t *theLine = [dataSource getLineAtIndex:row];
  int column;
  for (column = 0; column < width; column++) {
    unsigned int bgcode = theLine[column].bg_color;
    CGColorRef bg = [[ColorMap sharedInstance] colorForCode:bgcode];
    [self drawBox:context color:bg boxRect:charRect];
    charRect.origin.x += charWidth;
  }

  // Set font and mirror text; start one line lower to account for text flip
  [self setupTextForContext:context];
  // TODO: Text adjustment (3 px) should be font line height dependent.  Needs
  // some testing.
  charRect.origin.y += lineHeight - 3;

  // Draw forground character for each column in the row
  charRect.origin.x = rect.origin.x;
  for (column = 0; column < width; column++) {
    char c = 0xff & theLine[column].ch;
    if (c == 0) {
      c = ' ';
    }
    unsigned int fgcode = theLine[column].fg_color;
    CGColorRef fg = [[ColorMap sharedInstance] colorForCode:fgcode];
    [self drawChar:context character:c color:fg point:charRect.origin];
    charRect.origin.x += charWidth;
  }

  // Fill a rectangle with the cursor. drawRow consideres scrollback buffer;
  // cursorY is relative to the non-scrollback screen.
  int cursorY = [dataSource cursorY] - 1;
  int height = [dataSource height];
  int lines = [dataSource numberOfLines];
  if (lines > height) {
    cursorY += (lines - height);
  }
  if (CURSOR && row == cursorY) {
    int cursorX = [dataSource cursorX] - 1;
    CGRect cursorRect = CGRectMake(rect.origin.x, rect.origin.y,
                                   charWidth, lineHeight);
    cursorRect.origin.x += cursorX * charWidth;
    CGColorRef cursorColor = [[ColorMap sharedInstance] defaultCursorColor];
    [self drawBox:context color:cursorColor boxRect:cursorRect];
  }

  [dataSource releaseLock];
}

@end
