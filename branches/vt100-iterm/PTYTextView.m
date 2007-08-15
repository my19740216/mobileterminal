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
#import "VT100Screen.h"
#import <UIKit/NSString-UIStringDrawing.h>
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

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  // System 7.5 colors, why not?
  float darkBlack[] = { 0, 0, 0, 1 };
  colorTable[0] = CGColorCreate(colorSpace, darkBlack);
  float darkRed[] = { 0.67, 0, 0, 1 };
  colorTable[1] = CGColorCreate(colorSpace, darkRed);
  float darkGreen[] = { 0, 0.67, 0, 1 };
  colorTable[2] = CGColorCreate(colorSpace, darkGreen);
  float darkYellow[] = { 0.6, 0.4, 0, 1 };
  colorTable[3] = CGColorCreate(colorSpace, darkYellow);
  float darkBlue[] = { 0, 0, 0.67, 1 };
  colorTable[4] = CGColorCreate(colorSpace, darkBlue);
  float darkMagenta[] = { 0.6, 0, 0.6, 1 };
  colorTable[5] = CGColorCreate(colorSpace, darkMagenta);
  float darkCyan[] = { 0, 0.6, 0.6, 1 };
  colorTable[6] = CGColorCreate(colorSpace, darkCyan);
  float darkWhite[] = { 0.67, 0.67, 0.67, 1 };
  colorTable[7] = CGColorCreate(colorSpace, darkWhite);
  float lightBlack[] = { 0.33, 0.33, 0.33, 1 };
  colorTable[8] = CGColorCreate(colorSpace, lightBlack);
  float lightRed[] = { 1, 0.4, 0.4, 1 };
  colorTable[9] = CGColorCreate(colorSpace, lightRed);
  float lightGreen[] = { 0.4, 1, 0.4, 1 };
  colorTable[10] = CGColorCreate(colorSpace, lightGreen);
  float lightYellow[] = { 1, 1, 0.4, 1 };
  colorTable[11] = CGColorCreate(colorSpace, lightYellow);
  float lightBlue[] = { 0.4, 0.4, 1, 1 };
  colorTable[12] = CGColorCreate(colorSpace, lightBlue);
  float lightMagenta[] = { 1, 0.4, 1, 1 };
  colorTable[13] = CGColorCreate(colorSpace, lightMagenta);
  float lightCyan[] = { 0.4, 1, 1, 1 };
  colorTable[14] = CGColorCreate(colorSpace, lightCyan);
  float lightWhite[] = { 1, 1, 1, 1 };
  colorTable[15] = CGColorCreate(colorSpace, lightWhite);

  // Default colors
  float fgColor[4] = {1, 1, 1, 1};
  defaultFGColor = CGColorCreate(colorSpace, fgColor);
  float bgColor[4] = {0, 0, 0, 1};
  defaultBGColor = CGColorCreate(colorSpace, bgColor);
  float boldColor[4] = {1, 1, 1, 1};
  defaultBoldColor = CGColorCreate(colorSpace, boldColor);
  float cursorColor[4] = {1, 1, 1, 1};
  defaultCursorColor = CGColorCreate(colorSpace, cursorColor);
  float cursorTextColorC[4] = {1, 1, 1, 1};
  cursorTextColor = CGColorCreate(colorSpace, cursorTextColorC);

  [self setBackgroundColor:defaultBGColor];
  
  dataSource = nil;
  markedTextAttributes = nil;

  CURSOR=YES;
  return (self);
}

- (BOOL) canBecomeFirstResponder;
{
  return NO;
}

- (void) dealloc
{
#if DEBUG_ALLOC
  NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
  CGColorRelease(defaultFGColor);
  CGColorRelease(defaultBGColor);
  CGColorRelease(defaultBoldColor);
  CGColorRelease(defaultCursorColor);

  //    [font release];
  //	[nafont release];
  [markedTextAttributes release];
  //	[markedText release];

  [super dealloc];

#if DEBUG_ALLOC
  NSLog(@"%s: 0x%x, done", __PRETTY_FUNCTION__, self);
#endif
}

- (BOOL)isFlipped
{
    return YES;
}

- (void) setFGColor:(CGColorRef)color
{
  CGColorRelease(defaultFGColor);
  CGColorRetain(color);
  defaultFGColor=color;
  [self setNeedsDisplay];
  // reset our default character attributes    
}

- (void) setBGColor:(CGColorRef)color
{
  CGColorRelease(defaultBGColor);
  CGColorRetain(color);
  defaultBGColor=color;
  [self setNeedsDisplay];
}

- (void) setBoldColor: (CGColorRef)color
{
  CGColorRelease(defaultBoldColor);
  CGColorRetain(color);
  defaultBoldColor=color;
  [self setNeedsDisplay];
}

- (void) setCursorColor: (CGColorRef)color
{
  CGColorRelease(defaultCursorColor);
  CGColorRetain(color);
  defaultCursorColor=color;
  [self setNeedsDisplay];
}

- (void) setCursorTextColor:(CGColorRef) color
{
  CGColorRelease(cursorTextColor);
  CGColorRetain(color);
  cursorTextColor = color;
  [self setNeedsDisplay];

}

- (CGColorRef) cursorTextColor
{
  return (cursorTextColor);
}

- (CGColorRef) defaultFGColor
{
  return defaultFGColor;
}

- (CGColorRef) defaultBGColor
{
  return defaultBGColor;
}

- (CGColorRef) defaultBoldColor
{
  return defaultBoldColor;
}

- (CGColorRef) defaultCursorColor
{
  return defaultCursorColor;
}

- (CGColorRef) colorForCode:(unsigned int) index 
{
  CGColorRef color;

  if (index & DEFAULT_FG_COLOR_CODE) {  // special colors?
    switch (index) {
      case SELECTED_TEXT:
        exit(1);
        break;
      case CURSOR_TEXT:
        color = cursorTextColor;
        break;
      case DEFAULT_BG_COLOR_CODE:
        color = defaultBGColor;
        break;
      default:
        if (index & BOLD_MASK) {
          color = (index-BOLD_MASK == DEFAULT_BG_COLOR_CODE) ?
              defaultBGColor : [self defaultBoldColor];
        } else {
          color = defaultFGColor;
        }
    }
  } else {
    index &= 0xff;

    if (index < 16) {
      color = colorTable[index];
    } else if (index < 232) {
      index -= 16;
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      float components[] = {
        (index/36) ? ((index / 36) * 40 + 55) / 256.0 : 0 ,
        (index%36)/6 ? (((index % 36) / 6) * 40 + 55 ) / 256.0:0 ,
        (index%6) ? ((index % 6) * 40 + 55) / 256.0:0,
        1.0
      };
      color = CGColorCreate(colorSpace, components);
    } else {
      index -= 232;
      exit(1); 
      //color=[CGColorRef colorWithCalibratedWhite:(index*10+8)/256.0 alpha:1];
    }
  }
  return color;
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

- (void) refresh
{
  /*
  //NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
  struct CGRect aFrame;
  int height;

  if(dataSource != nil) {
  [dataSource acquireLock];
  numberOfLines = [dataSource numberOfLines];
  [dataSource releaseLock];

  height = numberOfLines * lineHeight;
  aFrame = [self frame];

  if(height != aFrame.size.height) {
  //NSLog(@"%s: 0x%x; new number of lines = %d; resizing height from %f to %d", 
  //	  __PRETTY_FUNCTION__, self, numberOfLines, [self frame].size.height, height);
  aFrame.size.height = height;
  [self setFrame: aFrame];
  // TODO(allen): Scroll
  if (![(PTYScroller *)([[self enclosingScrollView] verticalScroller]) userScroll]) 
  {
  [self scrollEnd];
  }
  }
  [self setNeedsDisplay];
  }
   */
}


/*

- (CGRect)adjustScroll:(CGRect)proposedVisibleRect
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView adjustScroll]", __FILE__, __LINE__ );
#endif
	proposedVisibleRect.origin.y=(int)(proposedVisibleRect.origin.y/lineHeight+0.5)*lineHeight;

//	if([(PTYScrollView *)[self enclosingScrollView] backgroundImage] != nil)
//        forceUpdate = YES; // we have to update everything if there's a background image
    
	[self setNeedsDisplay];
	return proposedVisibleRect;
}

-(void) scrollLineUp: (id) sender
{
    CGRect scrollRect;
    
    scrollRect= [self visibleRect];
//    scrollRect.origin.y-=[[self enclosingScrollView] verticalLineScroll];
    scrollRect.origin.y-=[self lineHeight];
    //NSLog(@"%f/%f",[[self enclosingScrollView] verticalLineScroll],[[self enclosingScrollView] verticalPageScroll]);
    [self scrollRectToVisible: scrollRect];
}

-(void) scrollLineDown: (id) sender
{
    CGRect scrollRect;
    
    scrollRect= [self visibleRect];
//    scrollRect.origin.y+=[[self enclosingScrollView] verticalLineScroll];
    scrollRect.origin.y+=[self lineHeight];
    [self scrollRectToVisible: scrollRect];
}

-(void) scrollPageUp: (id) sender
{
    CGRect scrollRect;
	
    scrollRect= [self visibleRect];
//    scrollRect.origin.y-= scrollRect.size.height - [[self enclosingScrollView] verticalPageScroll];
    scrollRect.origin.y-= scrollRect.size.height - [self lineHeight];
    [self scrollRectToVisible: scrollRect];
}

-(void) scrollPageDown: (id) sender
{
    CGRect scrollRect;
    
    scrollRect= [self visibleRect];
    scrollRect.origin.y+= scrollRect.size.height - [self lineHeight];
//    scrollRect.origin.y+= scrollRect.size.height - [[self enclosingScrollView] verticalPageScroll];
    [self scrollRectToVisible: scrollRect];
}

-(void) scrollHome
{
    CGRect scrollRect;
    
    scrollRect= [self visibleRect];
    scrollRect.origin.y = 0;
    [self scrollRectToVisible: scrollRect];
}

- (void)scrollEnd
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView scrollEnd]", __FILE__, __LINE__ );
#endif
    
    if (numberOfLines > 0)
    {
        CGRect aFrame;
		aFrame.origin.x = 0;
		aFrame.origin.y = (numberOfLines - 1) * lineHeight;
		aFrame.size.width = [self frame].size.width;
		aFrame.size.height = lineHeight;
		[self scrollRectToVisible: aFrame];
    }
}

- (void)scrollToSelection
{
	CGRect aFrame;
	aFrame.origin.x = 0;
	aFrame.origin.y = startY * lineHeight;
	aFrame.size.width = [self frame].size.width;
	aFrame.size.height = (endY - startY + 1) *lineHeight;
	[self scrollRectToVisible: aFrame];
}

*/

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
      CGColorRef bg = [self colorForCode:bgcode];
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
    screen_char_t *theLine = [dataSource getLineAtIndex:i];
    for (j = 0; j < WIDTH; j++) {
      char c = 0xff & theLine[j].ch;
      if (c == 0) {
        c = ' ';
      }
      unsigned int fgcode = theLine[j].fg_color;
      CGColorRef fg = [self colorForCode:fgcode];
      const float* fg_components = CGColorGetComponents(fg);
      CGContextSetRGBFillColor(context, fg_components[0], fg_components[1],
                                        fg_components[2], fg_components[3]);
      CGContextShowTextAtPoint(context, j * charWidth,
                               (i - startLineIndex + 1) * lineHeight, &c, 1);
    }
  }

  // Fill a rectangle with the cursor.
  if (CURSOR) {
    [self fillBoxColor:defaultCursorColor
                     X:[dataSource cursorX]
                     Y:[dataSource cursorY]];
  }

  [dataSource releaseLock];
}

/*
- (void)keyDown:(NSEvent *)event
{
    NSInputManager *imana = [NSInputManager currentInputManager];
    BOOL IMEnable = [imana wantsToInterpretAllKeystrokes];
    id delegate = [self delegate];
	unsigned int modflag = [event modifierFlags];
    BOOL prev = [self hasMarkedText];
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView keyDown:%@]",
          __FILE__, __LINE__, event );
#endif
    
	keyIsARepeat = [event isARepeat];
	
    // Hide the cursor
    [NSCursor setHiddenUntilMouseMoves: YES];   
		
	if ([delegate hasKeyMappingForEvent: event highPriority: YES]) 
	{
		[delegate keyDown:event];
		return;
	}
	
    IM_INPUT_INSERT = NO;
    if (IMEnable) {
        [self interpretKeyEvents:[NSArray arrayWithObject:event]];
        
        if (prev == NO &&
            IM_INPUT_INSERT == NO &&
            [self hasMarkedText] == NO)
        {
            [delegate keyDown:event];
        }
    }
    else {
		// Check whether we have a custom mapping for this event or if numeric or function keys were pressed.
		if ( prev == NO && 
			 ([delegate hasKeyMappingForEvent: event highPriority: NO] ||
			  (modflag & NSNumericPadKeyMask) || 
			  (modflag & NSFunctionKeyMask)))
		{
			[delegate keyDown:event];
		}
		else {
			if([[self delegate] optionKey] == OPT_NORMAL)
			{
				[self interpretKeyEvents:[NSArray arrayWithObject:event]];
			}
			
			if (IM_INPUT_INSERT == NO) {
				[delegate keyDown:event];
			}
		}
    }
}
*/

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

//
// private methods
//
/*
@implementation PTYTextView (Private)
- (void) _scrollToLine:(int)line
{
	CGRect aFrame;
	aFrame.origin.x = 0;
	aFrame.origin.y = line * lineHeight;
	aFrame.size.width = [self frame].size.width;
	aFrame.size.height = lineHeight;
	forceUpdate = YES;
	[self scrollRectToVisible: aFrame];
}
@end
*/
