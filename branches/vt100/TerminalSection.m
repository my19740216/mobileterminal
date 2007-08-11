//
//  TerminalSection.m
//  Crescat
//
//  Created by Fritz Anderson on Fri Oct 03 2003.
//  Copyright (c) 2003 Trustees of the University of Chicago. All rights reserved.
//	This program is free software; you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation; either version 2 of the License, or
//	(at your option) any later version.
//	
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//	
//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software
//	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//

#import "TerminalSection.h"
#import "TextStorageTerminal.h"
#import "NSTextStorageTerminal.h"

@implementation TerminalSection


#pragma mark ### Instance Methods ###

- (void) scrollNotice: (NSNotification *) notice
{
//	if (selectionStart == selectionEnd)
		return;
	
//	int			shift = [[[notice userInfo] objectForKey: @"contentShift"] intValue];
//	if (shift > 0)
//		[self unhighlight];
//	else {
//		shift = -shift;
//		
//		if (shift > selectionStart)
//			selectionStart = 0;
//		else
//			selectionStart -= shift;
//		
//		if (shift > selectionEnd)
//			selectionEnd = 0;
//		else
//			selectionEnd -= shift;
//	}
}

- (id) initWithRows: (int) initRows columns: (int) initColumns
{
	//  Are we having the containing view calculate the rows and columns?
	if ((self = [super initWithOrigin: 0.0])) {
		rows = initRows;
		columns = initColumns;
		
		terminal = [[TextStorageTerminal alloc] init];
		[self setContent: [terminal textStorage]];
	//	[terminal setDefaultFont: [AppDelegate defaultFont]];
		[terminal resizeToRows: initRows columns: initColumns];

		//NSSize		charSize = [TerminalSection characterSizeForFont: [terminal defaultFont]];
		cursorHeight = 1.0f;//[AppDelegate cursorProportion];
		//height = rows * charSize.height;

		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(cursorChanged:)
													 name: TSScreenCursorNotification
												   object: terminal];
		[self setCursorColor: @"FFFFFF"];//[AppDelegate cursorColor]];
		//  cursorColor = [[CrescatAppDelegate cursorColor] retain];
	}	
	
	return self;
}

- (void) dealloc
{
	[terminal release];
	[cursorColor release];
	[super dealloc];
}

- (TextStorageTerminal *) terminal { return terminal; }

- (UIView *) parentView { return parentView; }

- (void) setParentView: (UIView *) newView { parentView = newView; }

- (void) cursorChanged: (NSNotification *) notice {
	[parentView setNeedsDisplay];
}

- (void) getRows: (int *) outRows columns: (int *) outColumns {
	*outRows = rows;
	*outColumns = columns;
}

- (void) resizeToRows: (int) newRows columns: (int) newColumns {
	if (rows != newRows || columns != newColumns) {
		rows = newRows;
		columns = newColumns;
		[terminal resizeToRows: newRows columns: newColumns];
		//height = rows * [TerminalSection characterSizeForFont: [terminal defaultFont]].height;

		[parentView setNeedsDisplay];
	}
}

- (void) setOrigin: (float) newOrigin
{
	origin = newOrigin;
}
/*
- (void) drawBackground: (NSRect) sectionArea
{
	[super drawBackground: sectionArea];

	int				cursorOffset = [terminal characterOffsetOfCursor];
	NSRect			cursorRect = [self rectForCharacterOffset: cursorOffset];
	cursorRect.size = [TerminalSection characterSizeForFont: [terminal defaultFont]];

	if (! NSEqualRects(cursorRect, NSZeroRect)) {
		[cursorColor set];
		
		if (cursorHeight < 0.0) {
			cursorRect.origin.y = NSMaxY(cursorRect) - 1.5;
			cursorRect.size.height = 1.5;
		}
		else if (cursorHeight == 0.5) {
			cursorRect.size.height *= 0.5;
			cursorRect.origin.y += cursorRect.size.height;
		}
		
		NSRectFill(cursorRect);
	}
}
*/

/*- (void) draw
{
	[super draw];
	if (needsCursorContrast) {
		int				cursorOffset = [terminal characterOffsetOfCursor];
		NSRect			cursorRect = [self rectForCharacterOffset: cursorOffset];
		cursorRect.size = [TerminalSection characterSizeForFont: [terminal defaultFont]];

		//  Get the character at the cursor
		int			row, column;
		[terminal cursorLocationX: &column Y: &row];
		unichar		ch;
		if (column >= columns || row >= rows)
			ch = 0;
		else
			ch = [terminal characterAtRow: row column: column];
		
		if (ch > ' ') {
			//  Get the background color and set it
			NSDictionary *			attrs = [NSDictionary dictionaryWithObjectsAndKeys:
				[terminal defaultBackColor], NSForegroundColorAttributeName,
				cursorColor, NSBackgroundColorAttributeName,
				[terminal defaultFont], NSFontAttributeName,
				nil];
			//  Draw the character
			cursorRect.origin.y--;
			[[NSString stringWithCharacters: &ch length: 1] drawAtPoint: cursorRect.origin withAttributes: attrs];
		}
	}
}*/

- (NSString *) cursorColor { return cursorColor; }

float Luminance(NSString *aColor)
{
    NSScanner *sc = [NSScanner scannerWithString: aColor];
	unsigned color = 0;
    [sc scanHexInt: &color];
    int r = (color & 0xFF0000) >> 16;
    int g = (color & 0xFF00) >> 8;
    int b = (color & 0xFF);
    float red = (float)r / 255.0f, green = (float)g / 255.0f, blue = (float)b / 255.0f;
    return 0.11f * blue + 0.39f * red + 0.5f * green;
}

- (void) setCursorColor: (NSString *) newColor
{
	if (newColor != cursorColor) {
		[cursorColor release];
		cursorColor = [newColor retain];
		[parentView setNeedsDisplay];
		
		NSString *		textColor = [terminal defaultForeColor];
		needsCursorContrast = ABS(Luminance(textColor) - Luminance(cursorColor)) < 0.4;
	}
}

- (float) cursorHeight { return cursorHeight; }
- (void) setCursorHeight: (float) value
{
	if (value != cursorHeight) {
		cursorHeight = value;
		[parentView setNeedsDisplay];
	}
}


- (NSString *) backgroundColor
{
	return [terminal defaultBackColor];
}

@end
