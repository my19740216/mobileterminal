// -*- mode:objc -*-
/*
 **  PTYTextView.m
 **
 **  Copyright (c) 2002, 2003, 2007
 **
 **  Author: Fabian, Ujwal S. Setlur
 **	     Initial code by Kiichi Kusama
 **          Ported to MobileTerminal (from iTerm) by Allen Porter
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#define DEBUG_ALLOC           0
#define DEBUG_METHOD_TRACE    0

#import "PTYTextView.h"
#import <UIKit/NSString-UIStringDrawing.h>
#import "VT100Screen.h"
#import "ColorMap.h"
#import "Common.h"

#include <sys/time.h>

@implementation PTYTextView

+ (void) initialize
{
}

- (id)initWithFrame: (struct CGRect) aRect
{
#if DEBUG_ALLOC
  NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
  self = [super initWithFrame: aRect];
  [self setEditable:NO];
  [self displayScrollerIndicators];
  [self setAllowsRubberBanding:YES];

  dataSource = nil;
  CURSOR=YES;
  return (self);
}

- (void) dealloc
{
#if DEBUG_ALLOC
  NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
  //    [font release];
  //	[nafont release];

  [super dealloc];

#if DEBUG_ALLOC
  NSLog(@"%s: 0x%x, done", __PRETTY_FUNCTION__, self);
#endif
}

/*
- (NSFont *)font
{
    return font;
}

- (NSFont *)nafont
{
    return nafont;
}

- (void) setFont:(NSFont*)aFont nafont:(NSFont *)naFont;
{    
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSSize sz;
	
    [dic setObject:aFont forKey:NSFontAttributeName];
    sz = [@"W" sizeWithAttributes:dic];
	
	charWidthWithoutSpacing = sz.width;
	charHeightWithoutSpacing = [aFont defaultLineHeightForFont];
	
    [font release];
    [aFont retain];
    font=aFont;
    [nafont release];
    [naFont retain];
    nafont=naFont;
}

- (void)changeFont:(id)fontManager
{
	if ([ITConfigPanelController onScreen])
		[[ITConfigPanelController singleInstance] changeFont:fontManager];
	else
		[super changeFont:fontManager];
}
*/

- (VT100Screen*) dataSource
{
    return (dataSource);
}

- (void) setDataSource: (VT100Screen*) aDataSource
{
    id temp = dataSource;
    
    [temp acquireLock];
    dataSource = aDataSource;
    [temp releaseLock];
}

-(void) hideCursor
{
    CURSOR=NO;
}

-(void) showCursor
{
    CURSOR=YES;
}

- (void)fillBoxColor:(CGColorRef)color X:(int)x Y:(int)y
{
  CGContextRef context = UICurrentContext();
  const float* components = CGColorGetComponents(color);
  CGRect box = CGRectMake(floor((x - 1) * charWidth + 2), // + MARGIN/2,
                          floor((y - 1) * lineHeight + 3), // + VMARGIN/2,
                          ceil(charWidth), // - MARGIN/2,
                          ceil(lineHeight)); // - VMARGIN/2);
  CGContextSetRGBFillColor(context, components[0], components[1],
                                    components[2], components[3]);
  CGContextFillRect(context, box);
}

- (void)drawRect:(CGRect)rect
{
#if DEBUG_METHOD_TRACE
  NSLog(@"%s(0x%x):-[PTYTextView drawRect:(%f,%f,%f,%f) frameRect: (%f,%f,%f,%f)]",
      __PRETTY_FUNCTION__, self,
      rect.origin.x, rect.origin.y, rect.size.width, rect.size.height,
      [self frame].origin.x, [self frame].origin.y, [self frame].size.width, [self frame].size.height);
#endif

  int numLines, i, j, WIDTH;
  int startLineIndex, HEIGHT;

  // get lock on source 
  if (![dataSource tryLock]) return;

  WIDTH = [dataSource width];
  HEIGHT = [dataSource height];
  numLines = [dataSource numberOfLines];

  // Which line is our screen start?
  // TODO: Draw a scrollback buffer
  startLineIndex = numLines - HEIGHT;
  if (startLineIndex < 0) {
    startLineIndex = 0;
  }

  // TODO(allen): We should only draw stuff that has changed since the last
  // to save work for CoreGraphics.

  CGContextRef context = UICurrentContext();
  float w = rect.size.width - MARGIN;
  float h = rect.size.height - VMARGIN;
  lineHeight = h / HEIGHT;
  charWidth = w / WIDTH;

  // Draw background
  for (i = startLineIndex; i < numLines; ++i) {
    screen_char_t *theLine = [dataSource getLineAtIndex:i];
    for (j = 0; j < WIDTH; j++) {
      unsigned int bgcode = theLine[j].bg_color;
      CGColorRef bg = [[ColorMap sharedInstance] colorForCode:bgcode];
      [self fillBoxColor:bg X:(j + 1) Y:(i - startLineIndex + 1)];
    }
  }

  // Draw text
  CGContextSelectFont(context, "CourierNewBold", lineHeight,
                      kCGEncodingMacRoman);
  CGContextSetRGBFillColor(context, 1, 1, 1, 1);
  CGContextSetTextDrawingMode(context, kCGTextFill);
  CGAffineTransform myTextTransform;
  // Flip text, for some reason its written upside down by default
  myTextTransform = CGAffineTransformMake(1, 0, 0, -1, 0, h/30);
  CGContextSetTextMatrix(context, myTextTransform);
  for (i = startLineIndex; i < numLines; ++i) {
    const char* dirty = [dataSource dirty] + (i - startLineIndex) * WIDTH;
    screen_char_t *theLine = [dataSource getLineAtIndex:i];
    for (j = 0; j < WIDTH; j++) {
      if (!dirty) {
        continue;
      }
      char c = 0xff & theLine[j].ch;
      if (c == 0) {
        c = ' ';
      }
      unsigned int fgcode = theLine[j].fg_color;
      CGColorRef fg = [[ColorMap sharedInstance] colorForCode:fgcode];
      const float* fg_components = CGColorGetComponents(fg);
      CGContextSetRGBFillColor(context, fg_components[0], fg_components[1],
                                        fg_components[2], fg_components[3]);
      CGContextShowTextAtPoint(context, j * charWidth,
                               (i - startLineIndex + 1) * lineHeight, &c, 1);
    }
  }

  // Fill a rectangle with the cursor.
  if (CURSOR) {
    [self fillBoxColor:[[ColorMap sharedInstance] defaultCursorColor]
                     X:[dataSource cursorX]
                     Y:[dataSource cursorY]];
  }
  [dataSource resetDirty];
  [dataSource releaseLock];
}

/*
// transparency
- (float) transparency
{
	return (transparency);
}

- (void) setTransparency: (float) fVal
{
	transparency = fVal;
	forceUpdate = YES;
	useTransparency = fVal >=0.01;
	[self setNeedsDisplay];
}

- (BOOL) useTransparency
{
  return useTransparency;
}

- (void) setUseTransparency: (BOOL) flag
{
  useTransparency = flag;
  forceUpdate = YES;
  [self setNeedsDisplay];
}
*/

@end
