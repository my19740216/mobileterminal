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

#define DEBUG_ALLOC           1 
#define DEBUG_METHOD_TRACE    1
#define GREED_KEYDOWN         1

#import "PTYTextView.h"
#import "VT100Screen.h"
#import <UIKit/NSString-UIStringDrawing.h>

#include <sys/time.h>

//static NSCursor* textViewCursor =  nil;
//static float strokeWidth, boldStrokeWidth;
static int cacheSize;


@implementation NSString (UIWebViewAdditions)
- (id)_uikit_stringByTrimmingWhitespaceAndNewlines;     // IMP=0x324367f4
{
  NSLog(@"asked for the string!!!");
  exit(1);
}
@end


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

  // Black background
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  float backcomponents[4] = {0.7, 0.7, 0, 0};
  [self setBackgroundColor: CGColorCreate(colorSpace, backcomponents)];
  
  dataSource = nil;
  markedTextAttributes = nil;

  CURSOR=YES;
  lastFindX = startX = -1;
  gettimeofday(&lastBlink, NULL);
	    	
  memset(charImages, 0, cacheSize*sizeof(CharCache));	
  charWidth = 12;
  oldCursorX = oldCursorY = -1;
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
   /* 
	int i;
	if(mouseDownEvent != nil)
    {
		[mouseDownEvent release];
		mouseDownEvent = nil;
    }
	 
    //NSLog(@"remove tracking");
    if(trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
    for(i=0;i<16;i++) {
        [colorTable[i] release];
    }
    [defaultFGColor release];
    [defaultBGColor release];
    [defaultBoldColor release];
    [selectionColor release];
	[defaultCursorColor release];
*/
	
//    [font release];
//	[nafont release];
    [markedTextAttributes release];
//	[markedText release];
	
    [super dealloc];
    
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x, done", __PRETTY_FUNCTION__, self);
#endif
}
/*
- (BOOL)shouldDrawInsertionPoint
{
#if 0 // DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView shouldDrawInsertionPoint]",
          __FILE__, __LINE__);
#endif
    return NO;
}
*/

- (BOOL)isFlipped
{
    return YES;
}
/*
- (BOOL)isOpaque
{
    return YES;
}
*/

- (BOOL) blinkingCursor
{
  return (blinkingCursor);
}

- (void) setBlinkingCursor: (BOOL) bFlag
{
  blinkingCursor = bFlag;
}


/*
- (void) setFGColor:(NSColor*)color
{
    [defaultFGColor release];
    [color retain];
    defaultFGColor=color;
	[self resetCharCache];
	forceUpdate = YES;
	[self setNeedsDisplay];
	// reset our default character attributes    
}

- (void) setBGColor:(NSColor*)color
{
    [defaultBGColor release];
    [color retain];
    defaultBGColor=color;
	//    bg = [bg colorWithAlphaComponent: [[SESSION backgroundColor] alphaComponent]];
	//    fg = [fg colorWithAlphaComponent: [[SESSION foregroundColor] alphaComponent]];
	forceUpdate = YES;
	[self resetCharCache];
	[self setNeedsDisplay];
}

- (void) setBoldColor: (NSColor*)color
{
    [defaultBoldColor release];
    [color retain];
    defaultBoldColor=color;
	[self resetCharCache];
	forceUpdate = YES;
	[self setNeedsDisplay];
}

- (void) setCursorColor: (NSColor*)color
{
    [defaultCursorColor release];
    [color retain];
    defaultCursorColor=color;
	forceUpdate = YES;
	[self setNeedsDisplay];
}

- (void) setCursorTextColor:(NSColor*) aColor
{
	[cursorTextColor release];
	[aColor retain];
	cursorTextColor = aColor;
	[self _clearCacheForColor: CURSOR_TEXT];
	
	forceUpdate = YES;
	[self setNeedsDisplay];

}

- (NSColor *) cursorTextColor
{
	return (cursorTextColor);
}

- (NSColor *) defaultFGColor
{
    return defaultFGColor;
}

- (NSColor *) defaultBGColor
{
	return defaultBGColor;
}

- (NSColor *) defaultBoldColor
{
    return defaultBoldColor;
}

- (NSColor *) defaultCursorColor
{
    return defaultCursorColor;
}


- (void) setColorTable:(int) index highLight:(BOOL)hili color:(NSColor *) c
{
	int idx=(hili?1:0)*8+index;
	
    [colorTable[idx] release];
    [c retain];
    colorTable[idx]=c;
	[self _clearCacheForColor: idx];
	[self _clearCacheForColor: (BOLD_MASK | idx)];
	[self _clearCacheForBGColor: idx];
	
	[self setNeedsDisplay];
}

- (NSColor *) colorForCode:(unsigned int) index 
{
    NSColor *color;
	
	if (index&DEFAULT_FG_COLOR_CODE) // special colors?
    {
		switch (index) {
			case SELECTED_TEXT:
				color = selectedTextColor;
				break;
			case CURSOR_TEXT:
				color = cursorTextColor;
				break;
			case DEFAULT_BG_COLOR_CODE:
				color = defaultBGColor;
				break;
			default:
				if(index&BOLD_MASK)
				{
					color = index-BOLD_MASK == DEFAULT_BG_COLOR_CODE ? defaultBGColor : [self defaultBoldColor];
				}
				else
				{
					color = defaultFGColor;
				}
		}
    }
    else 
    {
		index &= 0xff;
		
        if (index<16) {
			color=colorTable[index];
		}
		else if (index<232) {
			index -= 16;
			color=[NSColor colorWithCalibratedRed:(index/36) ? ((index/36)*40+55)/256.0:0 
											green:(index%36)/6 ? (((index%36)/6)*40+55)/256.0:0 
											 blue:(index%6) ?((index%6)*40+55)/256.0:0
											alpha:1];
		}
		else {
			index -= 232;
			color=[NSColor colorWithCalibratedWhite:(index*10+8)/256.0 alpha:1];
		}
    }
	
    return color;
    
}

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

- (void) resetCharCache
{
/*
	int loop;
	for (loop=0;loop<cacheSize;loop++)
    {
		[charImages[loop].image release];
		charImages[loop].image=nil;
    }
*/
}

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
	//NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
	struct CGRect aFrame;
	int height;
    
    if(dataSource != nil)
    {
		[dataSource acquireLock];
        numberOfLines = [dataSource numberOfLines];
		[dataSource releaseLock];

        height = numberOfLines * lineHeight;
		aFrame = [self frame];
		
        if(height != aFrame.size.height)
        {
            
			//NSLog(@"%s: 0x%x; new number of lines = %d; resizing height from %f to %d", 
			//	  __PRETTY_FUNCTION__, self, numberOfLines, [self frame].size.height, height);
            aFrame.size.height = height;
            [self setFrame: aFrame];
// TODO(allen): Scroll
/*
			if (![(PTYScroller *)([[self enclosingScrollView] verticalScroller]) userScroll]) 
			{
				[self scrollEnd];
			}
*/
        }
				
		
		[self setNeedsDisplay];
    }
	
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

- (struct CGSize)contentSize
{
  NSLog(@"contentSize!");

  return CGSizeMake(12 * [dataSource numberOfLines], 320);
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
  struct timeval now;

  // get lock on source 
  if (![dataSource tryLock]) return;

  gettimeofday(&now, NULL);
  if (now.tv_sec*10+now.tv_usec/100000 >= lastBlink.tv_sec*10+lastBlink.tv_usec/100000+7) {
    blinkShow = !blinkShow;
    lastBlink = now;
  }

  WIDTH=[dataSource width];
  HEIGHT=[dataSource height];
  numLines = [dataSource numberOfLines];

  // Which line is our screen start?
  // TODO: Draw a scrollback buffer
  startLineIndex = numLines - HEIGHT;
  if (startLineIndex < 0) {
    startLineIndex = 0;
  }

  NSString* terminal_output = @"";
  for (i = startLineIndex; i < numLines; ++i) {
    screen_char_t *theLine = [dataSource getLineAtIndex:i];
    for (j = 0; j < WIDTH; j++) {
      // Multiple spaces in UIKit string drawing are
      // truncated, so we replace a space character with a
      // special non-breaking space.
      unichar c = theLine[j].ch;
      if (c == ' ') {
        c = NO_BREAK_SPACE;
      }
      terminal_output = [terminal_output stringByAppendingString:[NSString stringWithCharacters:&c length:1]];
    }
    const unichar c = '\n';
    terminal_output = [terminal_output stringByAppendingString:[NSString stringWithCharacters:&c length:1]];
  }

  // TODO: Font should be configurable
  [terminal_output drawInRect:rect 
    withStyle:@"font-family:CourierNewBold; font-size: 12px; color:white;"];

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

- (BOOL) keyIsARepeat
{
	return (keyIsARepeat);
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
	[self resetCharCache];
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
  [self resetCharCache];
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
