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

  // Black background
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  float backcomponents[4] = {0, 0, 0, 0};
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
/*
- (id) delegate
{
    return _delegate;
}

- (void) setDelegate: (id) aDelegate
{
    _delegate = aDelegate;
}    
*/

- (float) lineHeight
{
    return (lineHeight);
}

- (void) setLineHeight: (float) aLineHeight
{
    lineHeight = aLineHeight;
}

- (float) lineWidth
{
    return (lineWidth);
}

- (void) setLineWidth: (float) aLineWidth
{
    lineWidth = aLineWidth;
}

- (float) charWidth
{
	return (charWidth);
}

- (void) setCharWidth: (float) width
{
	charWidth = width;
}

- (void) setForceUpdate: (BOOL) flag
{
	forceUpdate = flag;
}


// We override this method since both refresh and window resize can conflict resulting in this happening twice
// So we do not allow the size to be set larger than what the data source can fill
- (void) setFrameSize: (NSSize) aSize
{
return;
	//NSLog(@"%s (0x%x): setFrameSize to (%f,%f)", __PRETTY_FUNCTION__, self, aSize.width, aSize.height);
/*
	NSSize anotherSize = aSize;
	
	anotherSize.height = [dataSource numberOfLines] * lineHeight;

	[super setFrameSize: anotherSize];
	
    if (![(PTYScroller *)([[self enclosingScrollView] verticalScroller]) userScroll]) 
    {
        [self scrollEnd];
    }
    
	// reset tracking rect
	if(trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = [self addTrackingRect:[self visibleRect] owner: self userData: nil assumeInside: NO];
*/
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

- (void)drawRect:(CGRect)rect
{
#if DEBUG_METHOD_TRACE
  NSLog(@"%s(0x%x):-[PTYTextView drawRect:(%f,%f,%f,%f) frameRect: (%f,%f,%f,%f)]",
      __PRETTY_FUNCTION__, self,
      rect.origin.x, rect.origin.y, rect.size.width, rect.size.height,
      [self frame].origin.x, [self frame].origin.y, [self frame].size.width, [self frame].size.height);
#endif

  int numLines, i, j, lineOffset, WIDTH;
  int startScreenLineIndex,line;
  screen_char_t *theLine;
  //	struct CGRect bgRect;
  //	NSColor *aColor;
  //	char  *dirty = NULL;
  //	BOOL need_draw;
  float curX, curY;
  //	unsigned int bgcode = 0, fgcode = 0;
  //	int y1, x1;
  //	BOOL double_width;
  //	BOOL reversed = [[dataSource terminal] screenMode]; 
  struct timeval now;
  int bgstart;
  //	BOOL hasBGImage = NO;  //[(PTYScrollView *)[self enclosingScrollView] backgroundImage] != nil;
  //	BOOL fillBG = NO;

  //float trans = useTransparency ? 1.0 - transparency : 1.0;
  NSLog(@"line height=%d", lineHeight); 
  NSLog(@"line width=%d", lineWidth); 

  if(lineHeight <= 0 || lineWidth <= 0) {
    NSLog(@"No line height or width set!");
    return;
  }

  // get lock on source 
  if (![dataSource tryLock]) return;

  gettimeofday(&now, NULL);
  if (now.tv_sec*10+now.tv_usec/100000 >= lastBlink.tv_sec*10+lastBlink.tv_usec/100000+7) {
    blinkShow = !blinkShow;
    lastBlink = now;
  }

  NSString* out_hack = @"";


  if (forceUpdate) {
    /*
       if ([[[dataSource session] parent] fullScreen]) {
       [[[self window] contentView] lockFocus];
       [[NSColor blackColor] set];
       NSRectFill([[self window] frame]);
       [[[self window] contentView] unlockFocus];
       }

       if(hasBGImage)
       {
       [(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: rect];
       }
       else {
       aColor = [self colorForCode:(reversed ? [[dataSource terminal] foregroundColorCode] : [[dataSource terminal] backgroundColorCode])];
       aColor = [aColor colorWithAlphaComponent: trans];
       [aColor set];
       NSRectFill(rect);
       }
     */
  }

  WIDTH=[dataSource width];

  // Starting from which line?
  lineOffset = rect.origin.y/lineHeight;

  // How many lines do we need to draw?
  numLines = ceil(rect.size.height/lineHeight);

  // Which line is our screen start?
  startScreenLineIndex=[dataSource numberOfLines] - [dataSource height];
  //NSLog(@"%f+%f->%d+%d", rect.origin.y,rect.size.height,lineOffset,numLines);

  // [self adjustScroll] should've made sure we are at an integer multiple of a line
  curY=(lineOffset+1)*lineHeight;

  // redraw margins if we have a background image, otherwise we can still "see" the margin
  /*
     if([(PTYScrollView *)[self enclosingScrollView] backgroundImage] != nil)
     {
     bgRect = NSMakeRect(0, rect.origin.y, MARGIN, rect.size.height);
     [(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: bgRect];
     bgRect = NSMakeRect(rect.size.width - MARGIN, rect.origin.y, MARGIN, rect.size.height);
     [(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: bgRect];
     }
   */


  for(i = 0; i < numLines; i++)
  {
    curX = MARGIN;
    line = i + lineOffset;

    if(line >= [dataSource numberOfLines])
    {
      NSLog(@"%s (0x%x): illegal line index %d >= %d", __PRETTY_FUNCTION__, self, line, [dataSource numberOfLines]);
      break;
    }

    // get the line
    theLine = [dataSource getLineAtIndex:line];
    //NSLog(@"the line = '%@'", [dataSource getLineString:theLine]);
    /*	
    // Check if we are drawing a line in scrollback buffer
    if (line < startScreenLineIndex) 
    {
    //NSLog(@"Buffer: %d",line);
    dirty = nil;
    }
    else 
    { 
    // get the dirty flags
    dirty=[dataSource dirty]+(line-startScreenLineIndex)*WIDTH;
    //NSLog(@"Screen: %d",(line-startScreenLineIndex));
    }	
     */

    //draw background here
    bgstart = -1;

    for(j = 0; j < WIDTH; j++) 
    {
      if (theLine[j].ch == 0xffff) 
        continue;
      /*			
      // Check if we need to redraw the background
      // do something to define need_draw
      need_draw = ((line < startScreenLineIndex || dirty[j] || forceUpdate) 
      && (theLine[j].ch == 0 || // it's a space, so we have to redraw the bg
      (theLine[j].bg_color & SELECTION_MASK) || // selected, redraw the bg
      hasBGImage)) // there's a background image
      || (!blinkShow &&(theLine[j].fg_color & BLINK_MASK)); // force to draw if it's the off-phase of blinking

      // if we don't have to update next char, finish pending jobs
      if (!need_draw)
      {
      if (bgstart >= 0) 
      {

      bgRect = NSMakeRect(floor(curX+bgstart*charWidth),curY-lineHeight,ceil((j-bgstart)*charWidth),lineHeight);
       */
      /*
      // if we have a background image and we are using the background image, redraw image
      if (fillBG) {
      aColor = (bgcode & SELECTION_MASK) ? selectionColor : [self colorForCode: (reversed && bgcode == DEFAULT_BG_COLOR_CODE) ? DEFAULT_FG_COLOR_CODE: bgcode]; 
      aColor = [aColor colorWithAlphaComponent: trans];
      [aColor set];
      NSRectFillUsingOperation(bgRect, hasBGImage?NSCompositeSourceOver:NSCompositeCopy);
      }

      }						
      bgstart = -1;
      }
      else 
      {
      if (bgstart < 0) { // any left over job?
      bgstart = j; 
      bgcode = theLine[j].bg_color & 0x3ff;
      fillBG = (bgcode & SELECTION_MASK) || 
      (theLine[j].ch == 0 && (reversed || bgcode!=DEFAULT_BG_COLOR_CODE || !hasBGImage)) || 
      (theLine[j].fg_color & BLINK_MASK && !blinkShow && // off-phase of a blink character?
      (!hasBGImage || bgcode!=DEFAULT_BG_COLOR_CODE)); // No draw if it has a bg image or the background color is the default
      }
      else if (theLine[j].bg_color != bgcode || ((bgcode & SELECTION_MASK) || (theLine[j].ch == 0 && (reversed || bgcode!=DEFAULT_BG_COLOR_CODE || !hasBGImage)) || (theLine[j].fg_color & BLINK_MASK && !blinkShow && (!hasBGImage ||bgcode!=DEFAULT_BG_COLOR_CODE))) != fillBG) 
      { 
      //background change
      bgRect = NSMakeRect(floor(curX+bgstart*charWidth),curY-lineHeight,ceil((j-bgstart)*charWidth),lineHeight);
      // if we have a background image and we are using the background image, redraw image
      if( hasBGImage)
      {
      [(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: bgRect];
      }
      if (fillBG) {
      aColor = (bgcode & SELECTION_MASK) ? selectionColor : [self colorForCode: (reversed && bgcode == DEFAULT_BG_COLOR_CODE) ? DEFAULT_FG_COLOR_CODE: bgcode]; 
      aColor = [aColor colorWithAlphaComponent: trans];
      [aColor set];
      NSRectFillUsingOperation(bgRect, hasBGImage?NSCompositeSourceOver:NSCompositeCopy);
      }
      bgstart = j; 
      bgcode = theLine[j].bg_color & 0x3ff; 
      fillBG = (bgcode & SELECTION_MASK) || (theLine[j].ch == 0 && (reversed || bgcode!=DEFAULT_BG_COLOR_CODE || !hasBGImage)) || (theLine[j].fg_color & BLINK_MASK && !blinkShow && (!hasBGImage ||bgcode!=DEFAULT_BG_COLOR_CODE));
      }

      }
       */
    }

    // finish pending jobs
    if (bgstart >= 0) 
    {
      /*
         bgRect = NSMakeRect(floor(curX+bgstart*charWidth),curY-lineHeight,ceil((j-bgstart)*charWidth),lineHeight);
      // if we have a background image and we are using the background image, redraw image
      if (fillBG) {
      aColor = (bgcode & SELECTION_MASK) ? selectionColor : [self colorForCode: (reversed && bgcode == DEFAULT_BG_COLOR_CODE) ? DEFAULT_FG_COLOR_CODE: bgcode]; 
      aColor = [aColor colorWithAlphaComponent: trans];
      [aColor set];
      NSRectFillUsingOperation(bgRect, hasBGImage?NSCompositeSourceOver:NSCompositeCopy);
      }
       */
    }

    //draw all char
    for(j = 0; j < WIDTH; j++) 
    {
      // Multiple spaces in UIKit string drawing are
      // truncated, so we replace a space character with a
      // special non-breaking space.
      unichar c = theLine[j].ch;
      if (c == ' ') {
        c = NO_BREAK_SPACE;
      }
      out_hack = [out_hack stringByAppendingString:[NSString stringWithCharacters:&c length:1]];

      /*
         need_draw = (theLine[j].ch != 0xffff) && 
         (line < startScreenLineIndex || forceUpdate || dirty[j] || (theLine[j].fg_color & BLINK_MASK));
         if (need_draw) 
         { 
         double_width = j<WIDTH-1 && (theLine[j+1].ch == 0xffff);

         if (reversed) {
         bgcode = theLine[j].bg_color == DEFAULT_BG_COLOR_CODE ? DEFAULT_FG_COLOR_CODE : theLine[j].bg_color;
         }
         else
         bgcode = theLine[j].bg_color;

      // switch colors if text is selected
      if((theLine[j].bg_color & SELECTION_MASK) && ((theLine[j].fg_color & 0x3ff) == DEFAULT_FG_COLOR_CODE))
      fgcode = SELECTED_TEXT | ((theLine[j].fg_color & BOLD_MASK) & 0x3ff); // check for bold
      else
      fgcode = (reversed && theLine[j].fg_color & DEFAULT_FG_COLOR_CODE) ? 
      (DEFAULT_BG_COLOR_CODE | (theLine[j].fg_color & BOLD_MASK)) : (theLine[j].fg_color & 0x3ff);

      if (blinkShow || !(theLine[j].fg_color & BLINK_MASK)) 
      {
      [self _drawCharacter:theLine[j].ch fgColor:fgcode bgColor:bgcode AtX:curX Y:curY doubleWidth: double_width];
      //draw underline
      if (theLine[j].fg_color & UNDER_MASK && theLine[j].ch) {
      // TODO:
      //						[[self colorForCode:(fgcode & 0x1ff)] set];
      //						NSRectFill(NSMakeRect(curX,curY-2,charWidth,1));
      }
      }
      }
      if(line >= startScreenLineIndex) dirty[j]=0;
       */

      curX+=charWidth;
    }

    const unichar c = '\n';
    out_hack = [out_hack stringByAppendingString:[NSString stringWithCharacters:&c length:1]];

    curY+=lineHeight;
  }

  // TODO: Font should be configurable
  [out_hack drawInRect:rect 
    withStyle:@"font-family:CourierNewBold; font-size: 12px; color:white;"];


  // Double check if dataSource is still available
  /*
     if (!dataSource) return;

     x1=[dataSource cursorX]-1;
     y1=[dataSource cursorY]-1;

  //draw cursor	
  float cursorWidth, cursorHeight;				

  if(charWidth < charWidthWithoutSpacing)
  cursorWidth = charWidth;
  else
  cursorWidth = charWidthWithoutSpacing;

  if(lineHeight < charHeightWithoutSpacing)
  cursorHeight = lineHeight;
  else
  cursorHeight = charHeightWithoutSpacing;
  if (CURSOR) {
  //		if([self blinkingCursor] && [[self window] isKeyWindow] && x1==oldCursorX && y1==oldCursorY)
  if([self blinkingCursor] && x1==oldCursorX && y1==oldCursorY)
  showCursor = blinkShow;
  else
  showCursor = YES;

  if (showCursor && x1<[dataSource width] && x1>=0 && y1>=0 && y1<[dataSource height]) {
  i = y1*[dataSource width]+x1;
  // get the cursor line
  theLine = [dataSource getLineAtScreenIndex: y1];

  //[[[self defaultCursorColor] colorWithAlphaComponent: trans] set];

  // TODO(allen): Draw a cursor

  ITermCursorType = CURSOR_VERTICAL;	
  switch ([[PreferencePanel sharedInstance] cursorType]) {
  case CURSOR_BOX:
  if([[self window] isKeyWindow])
  {
  NSRectFill(NSMakeRect(floor(x1 * charWidth + MARGIN),
  (y1+[dataSource numberOfLines]-[dataSource height])*lineHeight + (lineHeight - cursorHeight),
  ceil(cursorWidth), cursorHeight));
  }
  else
  {
  NSFrameRect(NSMakeRect(floor(x1 * charWidth + MARGIN),
  (y1+[dataSource numberOfLines]-[dataSource height])*lineHeight + (lineHeight - cursorHeight),
  ceil(cursorWidth), cursorHeight));

  }
  // draw any character on cursor if we need to
  unichar aChar = theLine[x1].ch;
  if (aChar)
  {
  if (aChar == 0xffff && x1>0) 
  {
  i--;
  x1--;
  aChar = theLine[x1].ch;
  }
  double_width = (x1 < WIDTH-1) && (theLine[x1+1].ch == 0xffff);
  [self _drawCharacter: aChar 
fgColor: [[self window] isKeyWindow]?CURSOR_TEXT:(theLine[x1].fg_color & 0x1ff)
bgColor: -1 // not to draw any background
AtX: x1 * charWidth + MARGIN 
Y: (y1+[dataSource numberOfLines]-[dataSource height]+1)*lineHeight
doubleWidth: double_width];
}

break;
case CURSOR_VERTICAL:
NSRectFill(NSMakeRect(floor(x1 * charWidth + MARGIN),
    (y1+[dataSource numberOfLines]-[dataSource height])*lineHeight + (lineHeight - cursorHeight),
    1, cursorHeight));
break;
case CURSOR_UNDERLINE:
NSRectFill(NSMakeRect(floor(x1 * charWidth + MARGIN),
      (y1+[dataSource numberOfLines]-[dataSource height]+1)*lineHeight + (lineHeight - cursorHeight) - 2,
      ceil(cursorWidth), 2));
break;
}

([dataSource dirty]+y1*WIDTH)[x1] = 1; //cursor loc is dirty

}
}

oldCursorX = x1;
oldCursorY = y1;

// draw any text for NSTextInput
if([self hasMarkedText]) {
  int len;

  len=[markedText length];
  if (len>[dataSource width]-x1) len=[dataSource width]-x1;
  [markedText drawInRect:NSMakeRect(floor(x1 * charWidth + MARGIN),
      (y1+[dataSource numberOfLines]-[dataSource height])*lineHeight + (lineHeight - cursorHeight),
      ceil((WIDTH-x1)*cursorWidth),cursorHeight)];
  memset([dataSource dirty]+y1*[dataSource width]+x1, 1,[dataSource width]-x1>len*2?len*2:[dataSource width]-x1); //len*2 is an over-estimation, but safe
}
*/

forceUpdate=NO;
[dataSource releaseLock];
  return [super drawRect:rect];
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
