//
//  TerminalSection.h
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
/**
    \file
    TallTextView section that emulates a terminal.
    A pure TallTextView is a visual stack of SectionRecords, all but the last static, and the last appending attributed text. The IntegratedTSView adds to the bottom of the stack an additional kind of SectionRecord, which has as a model not a simple NSTextStorage, but a TextStorageTerminal, which can emulate a terminal display. This header declares that section type, TerminalSection.
*/

#import <UIKit/UIView.h>
#import <UIKit/UIView-Rendering.h>
#import "SectionRecord.h"

@class  TextStorageTerminal;

/**	\ingroup	Presentation
        TallTextView SectionRecord that emulates a terminal.
    A pure TallTextView is a visual stack of SectionRecords, all but the last static, and the last appending attributed text. The IntegratedTSView adds to the bottom of the stack an additional kind of SectionRecord, which has as a model not a simple NSTextStorage, but a TextStorageTerminal, which can emulate a terminal display.
 
	TextStorageTerminal is responsible for drawing the terminal's cursor. The first stage is, during the background-drawing phase, simply to draw a block of the appropriate size and color in the proper place. A second phase may be necessary: If the cursor color has been determined to be close in luminance to the foreground text color, TerminalSection will come in after the text has been drawn to redraw the character at the cursor in the background color.
*/
@interface TerminalSection : SectionRecord {
	int						rows;
	int						columns;
	TextStorageTerminal *   terminal;
	UIView *				parentView;
	NSString *				cursorColor;
	float					cursorHeight;
	BOOL					needsCursorContrast;
}

/**
    Return an em-by-line-height size for a given font.
    This method renders a chain of lower-case "m"s and a few linefeeds into the SectionRecord shared layout manager, and measures the bounding rectangle of the first line. The returned value (which is cached in a dictionary) is the size of one m width by the height of the line. This is useful for converting between rows-and-columns and pixels.
    @param      aFont NSFont, the font in which to measure the character size.
    @retval     NSSize the size of a representative character in the given font.
*/
//+ (NSSize) characterSizeForFont: (NSFont *) aFont;

/**
    Create a TerminalSection of a given size.
    The initialization method allocates a TextStorageTerminal, the model object, of the given count of rows and columns. The TerminalSection subscribes to content- and cursor-change notifications, and scroll-off notifications, from the TextStorageTerminal. It readies itself to highlight URLs and emails whenever the user defaults permit and the screen content changes.
    @param      rows Integer, the height of the terminal in lines.
    @param      columns Integer, the width of the terminal in characters.
    @retval     self or nil if the superclass initialization fails.
*/
- (id) initWithRows: (int) rows columns: (int) columns;

/**
    The NSView containing this section.
    A TerminalSection changes its contents all the time, without changing its geometry, unlike SectionRecords. It therefore needs to know what view contains it, so it can notify the view to redraw when changes happen. This is the get accessor for the parent view.
    @retval     NSView the view (some kind of TallTextView) that contains this section.
*/
- (UIView *) parentView;
/**
    Set the NSView containing this section.
    A TerminalSection changes its contents all the time, without changing its geometry, unlike SectionRecords. It therefore needs to know what view contains it, so it can notify the view to redraw when changes happen. This is the set accessor for the parent view.
    @param      newView NSView, the view (some kind of TallTextView) that contains this section.
*/
- (void) setParentView: (UIView *) newView;

/**
    Setter for top y-coordinate.
    SectionRecords don't grow once there's a section below them, so there is no need for a setter for their origin property. A TerminalSection, however, sits under a steadily-growing stack of scrollback sections, and its origin changes all the time. This is the setter method.
    @param      newOrigin float, the new depth, in the owning view's coordinates, of the top of the section.
*/
- (void) setOrigin: (float) newOrigin;

/**
    Get the height and width, in characters, of the section.
    This method simply copies out the instance variables for the number of rows and columns in the terminal view.
    @param      outRows Pointer to integer, the height of the terminal in lines.
    @param      outColumns Pointer to integer, the width of the terminal in lines.
*/
- (void) getRows: (int *) outRows columns: (int *) outColumns;
/**
    Set the height and width, in characters, of the section.
    This method sets the instance variables for the number of rows and columns, and resizes the TextStorageTerminal accordingly. It adjusts the section height, and informs the enclosing view that it needs redisplay.
 
	This method has no effect if newRows and newColumns are the same as the current values. No sanity check is done on the new values.
    @param      newRows Integer, the number of rows the terminal is to have.
    @param      newColumns Integer, the number of columns the terminal is to have.
*/
- (void) resizeToRows: (int) newRows columns: (int) newColumns;

/**
    The TextStorageTerminal model object.
    This is a direct get accessor to the underlying TextStorageTerminal object that is the model for the terminal section.
    @retval     TextStorageTerminal the model object.
*/
- (TextStorageTerminal *) terminal;

/**
    Get the color of the terminal cursor.
    Accessor for the cursor-color instance variable. SectionRecord and TermLayoutManager do most of the drawing for the terminal content, but TerminalSection adds the cursor-drawing behavior.
    @retval     (description)
*/
- (NSString *) cursorColor;
/**
    Set the color of the terminal cursor.
    Setter for the cursor-color instance variable. SectionRecord and TermLayoutManager do most of the drawing for the terminal content, but TerminalSection adds the cursor-drawing behavior. If the desired cursor color is close in luminance to the default foreground color, a flag will be set so that characters under the cursor will be drawn in the background color.
    @param      newColor (description)
*/
- (void) setCursorColor: (NSString *) newString;

/**
	Get terminal cursor height.
	The practical values for this setting are 1.0, 0.5, and -1.0 (underline).
	@retval     float the proportion of a character space the cursor fills.
*/
- (float) cursorHeight;
/**
	Set terminal cursor height.
	The practical values for this setting are 1.0, 0.5, and -1.0 (underline).
	@param      value float, the proportion of a character space the cursor is to fill.
*/
- (void) setCursorHeight: (float) value;

/**
	Get the font used in the terminal.
	Returns the font used in rendering plain terminal output, by default some size of Monaco.
	@retval     NSFont the default terminal-output font.
*/
//- (NSFont *) defaultFont;

/**
	Demonstrate URL and email highlighting.
	The layout manager for the terminal section consults the settings for the application to determine whether to highlight URLs and email addresses in the display. There is a small terminal display in the preferences panel which has to demonstrate such highlighting according to the transient settings of the preference checkboxes, and not the committed preferences. Sending this message causes URLs or emails (or both) to be highlighted regardless of the global preferences.
	@param      scanURL BOOL, whether to highlight URLs in this view.
	@param      scanEmail BOOL, whether to highlight emails in this view.
*/
//- (void) ignorePreferencesAndScanURL: (BOOL) scanURL email: (BOOL) scanEmail;

@end
