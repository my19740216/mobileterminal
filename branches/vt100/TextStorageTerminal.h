//
//  TextStorageTerminal.h
//  Crescat
//
//  Created by Fritz Anderson on Mon Aug 25 2003.
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

//#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "GSAttributedString.h"
#import "GSTextStorage.h"
#import "Debug.h"

/**
    \file
    Model for GSTextStorage-based terminal screen.
    TextStorageTerminal maintains an GSTextStorage and supports a repertoire of methods that make the storage behave like a fixed array of characters with simple attributes. 

	It has a delegate that takes care of controller-layer tasks like transmitting report codes, printing, and storing scrolled-off text. 
*/

/**	\defgroup	TermModel		Terminal model
	Organizing NSString and GSTextStorage into a row-and-column model for placing, inserting, and deleting text. The nexus to terminal presentation (using the Cocoa text architecture to display and select terminal text) is TextStorageTerminal.
*/
/**	\defgroup	Presentation	Terminal presentation
	The visual presentation of a terminal screen and its scrollback. Text display is based on the Cocoa text architecture. The nexus to the terminal model (addressing attributed text by row and column) is TextStorageTerminal.
*/

/**
    Terminal color codes
    These are the ANSI codes for foreground and background colors. Terminal coloring assumes white characters scanned onto a black screen, whereas document-model applications display black text on a white canvas. The code for "black" is therefore interpreted as the session's background color, which by default is white. Likewise "white" is taken to mean the session's foreground color, which by default is black.
 */
typedef enum {
	tcRegularFore = -2,
	tcRegularBack,
	
	tcBlack,	///<	black (i.e., "background," usually white)
	tcRed,		///<	red
	tcGreen,	///<	green
	tcYellow,	///<	yellow
	tcBlue,		///<	blue
	tcMagenta,	///<	magenta
	tcCyan,		///<	cyan
	tcWhite		///<	white (i.e., "foreground," usually black)
}   TerminalColor;

/**
    Text attribute: Blinking
    The host sent this text with the blink attribute set.
*/
extern NSString * const TSTBlinkingAttribute;
/**
    Text attribute: Invisible
    The host sent this text with the invisible attribute set.
*/
extern NSString * const TSTInvisibleAttribute;
/**
    Text attribute: Bold
    The host sent this text with the bold attribute set.
*/
extern NSString * const TSTBoldAttribute;
/**
    Text attribute: Alternate character set
    The host sent this text from the alternative character set.
*/
extern NSString * const TSTAlternateAttribute;

/**
    Notification: Terminal content changed.
    Notification sent by TextStorageTerminal when the string content of the terminal screen has changed.
*/
extern NSString * const TSScreenContentChangedNotification;
/**
    Notification: Terminal atttributes changed.
    Notification sent by TextStorageTerminal when attributes (color, face, etc.) of terminal content has changed.
*/
extern NSString * const TSScreenAttrsChangedNotification;
/**
    Notification: Terminal cursor moved.
    Notification sent by TextStorageTerminal when the terminal cursor has moved, been hidden, or been revealed.
*/
extern NSString * const TSScreenCursorNotification;
/**
    Notification: Text scrolled off of the terminal.
    Notification sent by TextStorageTerminal when text has scrolled off the screen. UserInfo has one key, "contentShift," an NSNumber indicating how many characters shifted off.
*/
extern NSString * const TSScreenScrolledNotification;


/**
	Model class for an GSTextStorage-based terminal screen.
	TextStorageTerminal maintains an GSTextStorage and supports a repertoire of methods that make the storage behave like a fixed array of characters with simple attributes. The intent of this class is to provide methods that correspond closely to the primitive terminal operations in the termcap database.
 
	The other classes in the terminal-model group handle row-and-column addressing of an GSTextStorage, but they do not have the semantics of a terminal: There is no concept of scrolling, of a cursor, or of a limit to the height or width of the character array. TextStorageTerminal is responsible for those semantics.
 
	\ingroup TermModel
	\ingroup Presentation
*/
@interface TextStorageTerminal : NSObject
{
	GSTextStorage *			content;
	
	int						rows;
	int						columns;
	int						cursorRow;
	int						cursorColumn;
	BOOL					cursorVisible;
	
	BOOL					invertMode;
	
	BOOL					insertMode;
	BOOL					wrapMode;
	BOOL					deferredCursorWrap;
	
	BOOL					eatsNewlines;
	BOOL					justWrapped;
	
	int						scrollTop;
	int						scrollBottom;
	
	int						savedCursorRow;
	int						savedCursorColumn;
	
	unichar					lastCharacter;
	NSMutableDictionary *   attrDictionary;
	BOOL *					tabStops;
	BOOL					defaultTabStops;
	
	//NSFont *				defaultFont;
	NSString *				defaultForeColor;
	NSString *				defaultBackColor;
	NSMutableDictionary *   plainAttributes;
	
	id						delegate;
}

+ (NSString *) htmlColorForCode: (TerminalColor) code;
//+ (NSFont *) defaultFont;

/**
    Convenience initializer. Model a 24 x 80 terminal.
    This method does nothing more than call initWithRows:columns: with 24 rows and 80 columns.
    @retval     self
*/
- (id) init;
/**
    Designated initializer. Model a terminal with the given number of lines and columns.
    This initializer sets its character attributes to the terminal defaults and allocates its GSTextStorage, initializing it with the default attributes. Cursor visible at 0, 0, tabs reset, screen erased.
    @param      nRows Integer, the number of lines the terminal is to have.
    @param      nColumns Integer, the number of characters each line in the terminal is to have.
    @retval     self
*/
- (id) initWithRows: (int) nRows columns: (int) nColumns;

/**
    The GSTextStorage backing the terminal model.
    This is a direct accessor to the GSTextStorage object that underlies the terminal model.
    @retval     GSTextStorage the text storage object.
*/
- (GSTextStorage *) textStorage;
/**
    Set the contents of the terminal screen.
    This is equivalent to sending setAttributedString: to the underlying textStorage for the TextStorageTerminal. The attributed string you supply will completely replace the contents of the terminal.
    @param      string GSAttributedString, the new content for the terminal.
*/
- (void) setAttributedString: (GSAttributedString *) string;
/**
    The attributes for characters arriving at the screen.
    This is an NSDictionary, suitable for use in an GSAttributedString, describing the attributes that will be given the next character that is written to the terminal.
 
	-resetCurrentAttributes will replace this object, so always use this method to examine the current-attribute dictionary.
    @retval     NSDictionary an attribute dictionary.
*/
- (NSDictionary *) currentAttributes;
/**
    The attributes that constitute plain text.
    This is an NSDictionary, suitable for use in an GSAttributedString, describing the attributes used when the terminal is reset to plain text. Absolute dictionaries -- dictionaries that are "just bold," for instance -- are built from this dictionary.
    @retval     NSDictionary an attribute dictionary.
*/
- (NSDictionary *) plainAttributes;

/**
    The font in which the terminal is rendered.
    This is a direct accessor to the font that is used to render the terminal content. In principle, the content is an attributed string and can have different fonts for different characters, but in practice, Crescat assumes only one font is used throughout.
    @retval     NSFont the font used to render the terminal content.
*/
//- (NSFont *) defaultFont;
/**
    Set the font used to render terminal content.
    Setting the font not only sets the instance variable, it changes the font attribute in currentAttributes and plainAttributes, and replaces any fonts currently used in the terminal display. At present, nothing is done toward invalidating the display or resizing the view; presumably this is the responsibility of the sender.
    @param      aFont The font to use in the display.
*/
//- (void) setDefaultFont: (NSFont *) aFont;
/**
    The color of plain text.
    This is a direct accessor to the color used when rendering terminal content. 
    @retval     NSColor the default foreground color.
*/
- (NSString *) defaultForeColor;
/**
    Set the color of all text.
    This method sets not only the defaultForeColor instance variable, but the foreground-color attribute of the current and plain attribute dictionaries; it also replaces the color of all text in the terminal. In other words, it makes everything the selected color.
    @param      aColor NSColor, the color you want everything to be.
*/
- (void) setDefaultForeColor: (NSString *) aColor;
/**
    The color painted behind text when another isn't specified.
    This is a direct accessor to the default background color.
    @retval     NSColor the default background color.
*/
- (NSString *) defaultBackColor;
/**
    Set the color painted behind text unless otherwise specified.
    This method sets the defaultBackColor instance variable; it also sets the background-color attribute of the plain and current attribute dictionaries, and sets the background of all text on the screen. It's really quite comprehensive.
    @param      aColor NSColor, the desired default background color.
*/
- (void) setDefaultBackColor: (NSString *) aColor;

/**
    Change size of terminal.
    This method, called by the TerminalSection initialization and resizing methods, handles the bookkeeping for changes in terminal geometry: Adding or removing lines in the GSTextStorage, resetting tab stops, and making sure the cursor stays on the screen. 
	
	Curiously, nothing is done to truncate lines when the terminal becomes narrower. One would not want to do so while tracking a resize (the resize might be reversed), but I'm surprised the storage is allowed to linger. 
    @param      nRows Integer, the new height of the terminal, in lines.
    @param      nColumns Integer, the new width of the terminal, in characters.
*/
- (void) resizeToRows: (int) nRows columns: (int) nColumns;

/**
    Get the terminal delegate.
 A TextStorageTerminal has a delegate that takes care of controller-layer tasks like transmitting report codes, printing, and storing scrolled-off text. This is the direct getter for that attribute.
    @retval     (description)
*/
- (id) delegate;
/**
    Set the terminal delegate.
    A TextStorageTerminal has a delegate that takes care of controller-layer tasks like transmitting report codes, printing, and storing scrolled-off text. This is the direct setter for that attribute. This method raises an exception if the supplied delegate does not implement terminalScreen:scrollsOffText:.
    @param      theDelegate id, the proposed delegate object.
	@throw		NSInvalidArgumentException if theDelegate doesn't implement terminalScreen:scrollsOffText:.
*/
- (void) setDelegate: (id) theDelegate;

/**
    Reset new-character attributes to plain text.
    Resets the current-attribute dictionary to a mutable copy of the plain-attribute dictionary.
*/
- (void) resetCurrentAttributes;
/**
    Reset soft tab stops to match hard (every-8).
    Resets the soft tab stops to the first column and every eighth column thereafter. Setting a soft tab stop while the default soft tabs are set clears all the default tabs.
*/
- (void) resetTabs;
/**
    Clear the tab stop at the cursor.
    Clears the tab stop, if any, set at the column the cursor is in. Setting an additional soft tab stop will not clear any soft tab stops after this operation.
*/
- (void) clearOneTabStop;
/**
    Clear all soft tab stops.
    Clears every soft tab stop.
*/
- (void) clearTabStops;
/**
    Set a tab stop at the cursor.
    Sets a soft tab stop at the cursor's column. If the default soft tabs were in effect when this message was sent, they are all cleared.
*/
- (void) setTabStop;
/**
    Advance cursor to next soft tab stop.
    Advances the terminal cursor to the next position on the same line set by the host as a tab stop. If there are no more tab stops in the line, advance to the end of the line.
*/
- (void) horizontalTab;
/**
    Retreat cursor to previous soft tab stop.
    Retreats the terminal cursor to the previous position on the same line set as a soft tab stop. If there is no such position, retreat to the beginning of the line.
*/
- (void) backTab;
/**
    Advance cursor to next hard (column-of-8) tab stop.
    Advances the terminal cursor to the next character position, numbering from zero, on the same line, that is divisible by 8. If the end of the line is encountered, stop.
*/
- (void) hardwareTab;

/**
    The height of the terminal in lines of text.
    This is a direct accessor to the rows property of the TextStorageTerminal.
    @retval     Integer the height of the terminal in lines.
*/
- (int) rows;
/**
    The width of the terminal in characters.
    This is a direct accessor to the columns property of the TextStorageTerminal.
    @retval     Integer the width of the terminal in characters.
*/
- (int) columns;

/**
    Place one character on the terminal screen.
    Depending on the insert mode, inserts or overwrites the presented character at the cursor position, then advances the cursor. Scrolling is done if necessary -- at the first character of the new line. Uses the current attributes. Notifies of changes in content and cursor position.
    @param      aChar unichar, the character to insert or overwrite.
*/
- (void) acceptCharacter: (unichar) aChar;
/**
    Place several Latin-1 characters on the terminal screen.
    Depending on the insert mode, insert or overlay the given characters beginning at the cursor position. Scrolling is done if necessary -- at the first character of the new line. Uses the current attributes. Notifies of changes in content and cursor position. This should be much faster than sending acceptCharacter: for each byte.
    @param      chars Pointer to constant void data, the characters to insert/overlay.
    @param      length Integer, the number of characters.
*/
- (void) acceptASCII: (const void *) chars length: (int) length;

/**
    Accept the last-accepted character N times.
    Repeatedly sends acceptCharacter to self with the last character accepted by acceptCharacter: or acceptASCII:length:.
    @param      howMany	Integer, the number of times to insert the character.
*/
- (void) repeatLastCharacter: (int) howMany;

/**
    Scroll the scrollable region by a number of lines.
    Scrolls the content of the scrollable region (in practice the whole terminal screen) up by the given number of lines. If the number of lines is less than zero, scrolls the region down. 
 
	If the scroll is positive (up), the delegate is sent terminalScreen:scrollsOffText:. In all cases, posts the number of characters scrolled off in a TSScreenScrolledNotification.
    @param      positiveForUp Integer, the number of lines to scroll, negative to scroll down.
	@see		scrollAreaTop:bottom:
	@see		setScrollAreaTop:bottom:
	@see		unsetScrollArea
	@see		scrollUp
	@see		scrollDown
*/
- (void) scrollLines: (int) positiveForUp;
/**
    Scroll the scrollable region up one line.
    This is equivalent to [self scrollLines: 1].
*/
- (void) scrollUp;
/**
    Scroll the scrollable region down one line.
    This is equivalent to [self scrollLines: -1].
*/
- (void) scrollDown;

/**
    Whether the terminal is in insert mode.
    This is a direct getter for the insertMode attribute. If insert mode is on, arriving characters shove existing content out of the way; if off, arriving charaacters overwrite the existing content.
    @retval     BOOL whether the terminal is in insert mode.
*/
- (BOOL) insertMode;
/**
    Set the terminal's insert mode.
    This is a direct setter for the insertMode attribute. If insert mode is on, arriving characters shove existing content out of the way; if off, arriving charaacters overwrite the existing content.
    @param      newMode BOOL, whether the terminal is to be in insert mode.
*/
- (void) setInsertMode: (BOOL) newMode;
/**
    Whether the terminal is in wrap mode.
    This is a direct getter for the wrapMode attribute. In wrap mode, characters that overflow the right column of the terminal overflow into the next line, potentially scrolling the contents up; otherwise the overflow characters are lost.
    @retval     BOOL whether the terminal is in wrap mode.
*/
- (BOOL) wrapMode;
/**
    Set the terminal's wrap mode.
    This is a direct setter for the wrapMode attribute. In wrap mode, characters that overflow the right column of the terminal overflow into the next line, potentially scrolling the contents up; otherwise the overflow characters are lost.
    @param      newMode BOOL, whether the terminal is to be in wrap mode.
*/
- (void) setWrapMode: (BOOL) newMode;
/**
    Whether the terminal ignores newline commands after line wraps.
    This is a direct getter for the eatsNewlines attribute. If eatsNewlines is YES, and a newline arrives immediately after the cursor has wrapped to a new line, the newline is ignored. In practice, Crescat always sets this to NO.
    @retval     BOOL whether the terminal ignores newlines after line wraps.
*/
- (BOOL) eatsNewlines;
/**
    Set whether the terminal ignores newline commands after line wraps.
    This is a direct setter for the eatsNewlines attribute. If eatsNewlines is YES, and a newline arrives immediately after the cursor has wrapped to a new line, the newline is ignored. In practice, Crescat always sets this to NO.
    @param      value BOOL, whether the terminal is to ignore newlines after line wraps.
*/
- (void) setEatsNewlines: (BOOL) value;

/**
    The range of lines that scroll.
    ANSI terminals can define a subset of terminal lines to respond to scroll commands. This method returns the zero-based line numbers, with the bottom line being the first line that does not scroll. Therefore if all of an N-line terminal is scrollable, the returned values are:
 
	- top = 0
	- bottom = N
    @param[out] top Pointer to integer, zero-based, the first line subject to scrolling.
    @param[out] bottom Pointer to integer, zero-based, the first line not subject to scrolling.
	@see		setScrollAreaTop:bottom:
	@see		scrollLines:
*/
- (void) scrollAreaTop: (int *) top bottom: (int *) bottom;
/**
    Set the range of lines that scroll.
    Set the subset of terminal lines that respond to scroll commands. The range is specified as zero-based indices, from the first line that does scroll to the first line that does not. By default all of the screen is scrollable, so in an N-line terminal, top is 0 and bottom is N.
    @param[in] top Integer, zero-based, the first line subject to scrolling.
    @param[in] bottom Integer, zero-based, the first line after top not subject to scrolling.
	@throw		NSInvalidArgumentException if top >= bottom.
	@see		scrollAreaTop:bottom:
	@see		scrollLines:
*/
- (void) setScrollAreaTop: (int) top bottom: (int) bottom;
/**
    Reset the scrolling area to full-screen.
    This is equivalent to [self setScrollAreaTop: 0 bottom: rows].
	@see		setScrollAreaTop:bottom:
*/
- (void) unsetScrollArea;

/**
	@name	Cursor operations	
*/
//@{
/**
    Get the location of the terminal cursor.
    This is a direct getter of the cursor column and row attributes. The values are zero-based.
    @param[out]      cursorX Pointer to integer, zero-based, the column the cursor is in.
    @param[out]      cursorY Pointer to integer, zero-based, the row (from the top) the cursor is in.
*/
- (void) cursorLocationX: (int *) cursorX Y: (int *) cursorY;
/**
    Set the location of the terminal cursor.
    This is a direct setter of the cursor column and row attributes. The values are zero-based. The parameters are not bounds-checked. Posts a TSScreenCursorNotification.
 
	This is a synonym (with the parameters reversed) for moveToRow:column:.
    @param      cursorX Integer, zero-based, the column to move the cursor to.
    @param      cursorY Integer, zero-based, the row (from the top) to move the cursor to.
*/
- (void) setCursorLocationX: (int) cursorX Y: (int) cursorY;
/**
    Set the location of the terminal cursor.
	This is a direct setter of the cursor row and column attributes. The values are zero-based. The parameters are not bounds-checked. Posts a TSScreenCursorNotification.
 
	This is a synonym (with the parameters reversed) for setCursorLocationX:Y:.
    @param      cursorToRow Integer, zero-based, the row (from the top) to move the cursor to.
    @param      cursorToColumn Integer, zero-based, the column to move the cursor to.
*/
- (void) moveToRow: (int) cursorToRow column: (int) cursorToColumn;
/**
    Move the cursor to a line, preserving the column.
    This is a direct setter for the cursor row attribute. The value is zero-based, and is not bounds-checked. Posts a TSScreenCursorNotification.
    @param      line Integer, zero-based, the row (from the top) to move the cursor to.
*/
- (void) cursorToLine: (int) line;
/**
    Move the cursor to a column, preserving the line.
    This is a direct setter for the cursor column attribute. The value is zero-based, and is not bounds-checked. Posts a TSScreenCursorNotification.
    @param      column Integer, zero-based, the column to move the cursor to.
*/
- (void) cursorToColumn: (int) column;
/**
    The number of characters in the text storage before the cursor position.
    This method uses a GSTextStorage category method, ensureRow:hasColumn:withAttributes:, to determine how many characters there currently are in the text storage before the character under the terminal cursor. This is not necessarily row * columns + column, because the text storage keeps short lines for lines that don't fill all the columns.
    @retval     Integer the number of characters before the cursor.
*/
- (int) characterOffsetOfCursor;
/**
    Set whether the terminal cursor can be seen.
    ANSI terminals can hide their cursors. This is a direct setter for the cursorVisible attribute. Posts a TSScreenCursorNotification.
    @param      visibility BOOL, whether the terminal cursor is to be seen.
*/
- (void) setCursorVisible: (BOOL) visibility;
/**
    Whether the terminal cursor can be seen.
    ANSI terminals can hide their cursors. This is a direct getter for the cursorVisible attribute.
    @retval     BOOL whether the terminal cursor is visible.
*/
- (BOOL) isCursorVisible;

/**
    Move the cursor up N lines.
    Moves the terminal cursor up by the given number of lines, until the top of the screen is encountered. Posts a TSScreenCursorNotification.
    @param      howMany The number of lines to move the cursor.
*/
- (void) cursorUp: (int) howMany;
/**
    Move the cursor up one line.
    Move the terminal cursor up one line, unless it is already at the top line. Posts a TSScreenCursorNotification.
*/
- (void) cursorUp;
/**
    Move the cursor down N lines.
    Moves the terminal cursor down by the given number of lines, until the bottom of the screen is encountered. Posts a TSScreenCursorNotification.
    @param      howMany The number of lines to move the cursor.
*/
- (void) cursorDown: (int) howMany;
/**
    Move the cursor down one line.
    Move the terminal cursor down one line, unless it is already at the bottom line. Posts a TSScreenCursorNotification.
*/
- (void) cursorDown;
/**
    Move the cursor left N characters.
    Moves the terminal cursor left by the given number of characters, until the left edge of the screen is encountered. Posts a TSScreenCursorNotification.
    @param      howMany The number of character positions to move the cursor.
*/
- (void) cursorLeft: (int) howMany;
/**
    Move the cursor left one character.
    Move the terminal cursor left, unless it is already at the left edge of the screen. Posts a TSScreenCursorNotification.
*/
- (void) cursorLeft;
/**
    Move the cursor right N characters.
    Moves the terminal cursor right by the given number of characters, until the right edge of the screen is encountered. Posts a TSScreenCursorNotification.
    @param      howMany The number of character positions to move the cursor.
*/
- (void) cursorRight: (int) howMany;
/**
    Move the cursor right one character.
    Move the terminal cursor right, unless it is already at the right edge of the screen. Posts a TSScreenCursorNotification.
*/
- (void) cursorRight;

/**
    Move the cursor up N lines, scrolling as necessary.
    Moves the cursor up by the smaller of howMany and the number of lines to the top of the scroll region. If there are lines left over from the parameter, scrolls the scroll region down that many lines. Posts a TSScreenCursorNotification and, if necessary, a TSScreenScrolledNotification.
    @param      howMany How many lines to move the cursor up.
*/
- (void) reverseIndex: (int) howMany;

/**
    Move the cursor to beginning of line.
    Moves the cursor to column zero. Posts a TSScreenCursorNotification.
*/
- (void) carriageReturn;
/**
    Move the cursor to the next line, scrolling if needed.
    If the cursor is at the bottom of the scroll region, scrolls the scroll region up one line, so that the cursor is in the line scrolled in; posts a TSScreenScrolledNotification. Otherwise, places the cursor in the next line and posts a TSScreenCursorNotification.
*/
- (void) lineFeed;

/**
    Put the cursor position in the save register.
    An ANSI terminal has a one-position-capacity register for saving the cursor position. This method saves the current cursor position in that register.
	@see		restoreCursorPosition
*/
- (void) saveCursorPosition;
/**
	Put the cursor position in the save register.
	An ANSI terminal has a one-position-capacity register for saving the cursor position. This method restores the cursor position from that register. Posts a TSScreenCursorNotification.
	@see		saveCursorPosition
*/
- (void) restoreCursorPosition;

/**
    Move cursor to top-left of screen.
    Moves the terminal cursor to the 0, 0 position. Posts a TSScreenCursorNotification.
*/
- (void) homeCursor;
//@}
/**
	@name	Erasures
 */
//@{
/**
    Remove all content from the screen.
    This method removes all characters from the screen storage, and moves the cursor to 0, 0. Posts a TSScreenContentChangedNotification and a TSScreenCursorNotification.
*/
- (void) eraseScreen;
/**
    Erase all content from the cursor onward.
    Does an eraseToEndOfLine on the cursor's line, and then deletes the lines that follow. Posts a TSScreenContentChangedNotification.
*/
- (void) eraseToEndOfScreen;
/**
    Erase all content through the cursor.
    Erases (changes to bare newlines) all lines before the one the cursor is on, and issues an eraseToStartOfLine for the cursor's position, erasing everything up to and including the cursor's position. Posts a TSScreenContentChangedNotification.
*/
- (void) eraseToStartOfScreen;
/**
    Erase all content in the scroll area.
    Replaces all lines in the scroll area with bare newlines, and moves the cursor to the top left of the scroll area. Posts a TSScreenContentChangedNotification and a TSScreenCursorNotification.
*/
- (void) eraseScrollArea;
/**
    White-out line content from the cursor to the end.
    Replaces everything in the cursor's line from the cursor's column to before the newline that ends the line with spaces. Posts a TSScreenContentChangedNotification. Note that the cursor's position does not change.
*/
- (void) eraseToEndOfLine;
/**
    White-out line content from the beginning through the cursor's position.
    Replaces everything in the cursor's line from the beginning through the cursor's position with spaces. Posts a TSScreenContentChangedNotification. Note that the cursor position does not change.
*/
- (void) eraseToStartOfLine;
/**
    Replace the cursor's line with blanks.
    Replaces everything in the cursor's line from beginning to newline with spaces. Posts a TSScreenContentChangedNotification. The cursor position does not change.
*/
- (void) eraseLine;
/**
    Replace N characters from the cursor with spaces.
    Replaces the given number of characters in the line beginning at the terminal cursor's position with blanks. The operation does not wrap. If the underlying storage does not have room on the line for the blanks, room is made. The cursor position does not change. Posts a TSScreenContentChangedNotification.
    @param      howMany (description)
*/
- (void) eraseCharacters: (int) howMany;
/**
    Replace the character under the cursor with a space.
    Replaces the character under the terminal cursor with a space. The cursor position does not change. Posts a TSScreenContentChangedNotification. Equivalent to [self eraseCharacters: 1].
*/
- (void) eraseCharacter;
//@}
/**
    Insert blank lines before the cursor's line.
    Inserts newlines in the underlying text storage before the terminal cursor's line. Content may be scrolled off the bottom of the scroll region by this operation; remember that content scrolled off the bottom is not reported to the delegate. Posts TSScreenContentChangedNotification. Moves the cursor to column zero if it was not there already, and posts TSScreenCursorNotification.
    @param      howMany Integer, the number of lines to insert.
*/
- (void) insertLines: (int) howMany;
/**
    Insert one blank line before the cursor's line.
    Inserts a newline in the underlying text storage before the terminal cursor's line. Content may be scrolled off the bottom of the scroll region by this operation; remember that content scrolled off the bottom is not reported to the delegate. Posts TSScreenContentChangedNotification. Moves the cursor to column zero if it was not there already, and posts TSScreenCursorNotification. Equivalent to [self insertLines: 1].
*/
- (void) insertLine;
/**
    Remove N lines starting at the cursor.
    Removes the given number of lines, starting at the cursor's line, from the text storage and the display. The content below the deletion is scrolled up. Posts TSScreenContentChangedNotification. If the cursor is not at the leftmost column, it is moved there, and TSScreenCursorNotification is posted.
    @param      howMany Integer, how many lines to delete.
*/
- (void) deleteLines: (int) howMany;
/**
    Delete the line the cursor is on.
    Removes the line the cursor is on from the text storage and the display. The content below the deletion is scrolled up. Posts TSScreenContentChangedNotification. If the cursor is not at the leftmost column, it is moved there, and TSScreenCursorNotification is posted. Equivalent to [self deleteLines: 1].
*/
- (void) deleteLine;

/**
    Insert N blank characters at the cursor.
    Inserts the given number of blanks at the cursor position. No more blanks will be inserted than there are columns remaining in the line. Any content that is pushed beyond the right edge of the line is lost. No wrapping is done. Posts TSScreenContentChangedNotification.
    @param      howMany (description)
*/
- (void) insertCharacters: (int) howMany;
/**
    Delete N characters from the line beginning at the cursor.
    Deletes the given number of characters beginning at the cursor position. No more characters than the remainder of the line will be deleted. No wrapping or line merging is done. Posts TSScreenContentChangedNotification.
    @param      howMany (description)
*/
- (void) deleteCharacters: (int) howMany;
/**
    Delete one character at the cursor.
    Deletes a single character at the position of the terminal cursor. No wrapping or line merging is done. Posts TSScreenContentChangedNotification. Equivalent to [self deleteCharacters: 1].
*/
- (void) deleteCharacter;

/**
	@name	Character attributes
*/
//@{
/**
    Set Bold text attribute.
    Sets the TSTBoldAttribute in the attribute dictionary to 1, so all characters that arrive until endBold or a reset is encountered are displayed in bold face. Additional calls to this method have no effect.
*/
- (void) startBold;
/**
    Set Underline text attribute.
    Sets the GSUnderlineStyleAttributeName in the attribute dictionary to 1, so all characters that arrive until endUnderline or a reset is encountered are underlined. Additional calls to this method have no effect.
*/
- (void) startUnderline;
/**
    Set Blink text attribute.
    Sets the TSTBlinkingAttribute in the attribute dictionary to 1, so all characters that arrive until endBlink or a reset is encountered blink. Additional calls to this method have no effect.
*/
- (void) startBlink;
/**
    Set Invert text attribute.
    Reverses the foreground and background color attributes, so all characters that arrive until endInverse or a reset is encountered are shown in reverse video. Additional calls to this method have no effect.
*/
- (void) startInverse;
/**
    Set Invisible text attribute.
    Sets the TSTInvisibleAttribute in the attribute dictionary to 1, so all characters that arrive until endInvisible or a reset is encountered are invisible. Additional calls to this method have no effect.
*/
- (void) startInvisible;
/**
    Set Alternate text attribute.
    Sets the TSTAlternateAttribute in the attribute dictionary to 1, so all characters that arrive until endAlternate or a reset is encountered are drawn from the alternate character set. Additional calls to this method have no effect.
*/
- (void) startAlternate;
/**
    Clear the Bold text attribute.
    Sets the TSTBoldAttribute in the attribute dictionary to 0, ending the effect of -startBold. Additional calls to this method have no effect.
*/
- (void) endBold;
/**
    Clear the Underline text attribute.
    Sets the GSUnderlineStyleAttributeName in the attribute dictionary to 0, ending the effect of -startUnderline. Additional calls to this method have no effect.
*/
- (void) endUnderline;
/**
    Clear the Blink text attribute.
    Sets the TSTBlinkingAttribute in the attribute dictionary to 0, ending the effect of -startBlink. Additional calls to this method have no effect.
*/
- (void) endBlink;
/**
    Clear the Invert text attribute.
    Restores the foreground and background color attributes to their normal roles, ending the effect of -startInverse. Additional calls to this method have no effect.
*/
- (void) endInverse;
/**
    Clear the Invisible text attribute.
    Sets the TSTInvisibleAttribute in the attribute dictionary to 0, ending the effect of -startInvisible. Additional calls to this method have no effect.
*/
- (void) endInvisible;
/**
    Clear the Alternate text attribute.
    Sets the TSTAlternateAttribute in the attribute dictionary to 0, ending the effect of -startAlternate. Additional calls to this method have no effect.(comprehensive description)
*/
- (void) endAlternate;
/**
    Set the text color.
    Sets the NSForegroundColorAttribute in the attribute dictionary to the color corresponding to the color parameter. If invertMode is set (-startInverse has been received and not canceled), NSBackgroundColor is changed instead; the change will be to the background color while the inversion is in effect, but in normal mode, the color is applied to text.
    @param      color TerminalColor, the code for the color to use for text.
*/
- (void) setForeground: (TerminalColor) color;
/**
    Set the background color.
	Sets the NSBackgroundColorAttribute in the attribute dictionary to the color corresponding to the color parameter. If invertMode is set (-startInverse has been received and not canceled), NSForegroundColor is changed instead; the change will be to the foreground color while the inversion is in effect, but in normal mode, the color is applied to the background.
	
	If color is tcWhite and inversion mode is not set, NSBackgroundColorAttribute is cleared.
	@param      color TerminalColor, the code for the color to use for background.
*/
- (void) setBackground: (TerminalColor) color;
/**
    Set text drawing to plain-colored text.
    Sets the NSForegroundColorAttribute in the attribute dictionary to the value of the same name in the plain-text attribute dictionary (typically black).
*/
- (void) setPlainForeground;
/**
    Set text drawing to plain-background text.
    Clears the NSBackgroundColorAttribute in the attribute dictionary, making it white by default, or whatever the user-set background color is for this session.
*/
- (void) setPlainBackground;
//@}
/**
	@name	Status reports
 */
//@{
/**
    Get the character at a location on the terminal screen.
    Given zero-based row and column numbers, return the character at that location in the terminal screen. Throws an exception if either coordinate is out of bounds. If the given portion of the screen has no content (it is to the right of the written content of the line), returns 0xffff.
    @param[in]  row Integer, the zero-based row the character is sought on.
    @param[in]  column Integer, the zero-based column the character is sought at.
    @retval     Unichar the character at the given location, or 0xffff if the given location has not been written.
	@throw		NSInvalidArgumentException if row or column is less than zero or greater than or equal to the respective counts of rows or columns.
*/
- (unichar) characterAtRow: (int) row column: (int) column;

/**
    Make delegate report this as an ANSI terminal.
    Uses the terminalScreen:sendsReportData: method to send the string "esc[?1;2c", which identifies this as an ANSI terminal.
*/
- (void) reportDeviceCode;
/**
    Make delegate report status to host.
    Uses the terminalScreen:sendsReportData: method to send the string "esc[0n", which indicates that the terminal is responsive and in good order.
*/
- (void) reportDeviceStatus;
/**
    Make delegate report cursor position to host.
    Uses the terminalScreen:sendsReportData: method to send the string "esc[MM;NNR", where MM is the one-based row, and NN the one-based column, of the cursor address.
*/
- (void) reportCursorPosition;
//@}
/**
    Sound the system beep.
    This method just sounds the system beep sound, which may or may not be appropriate for use in a terminal. Long sounds, for instance, may bog down applications that make enthusiastic use of the bell.
*/
- (void) soundBell;
/**
    Reverse foreground and background of current contents (UNIMPLEMENTED).
    This method is not implemented; it simply logs "Invert Screen: " followed by YES or NO, depending on the parameter. With every transition between YES and NO, this method should probably swap the foreground and background attributes of every character in the text storage, swap the new-text attributes colors, and, probably swap the default foreground and background colors so that undrawn parts of the screen get drawn properly.
 
	No need for this method has been demonstrated.
    @param      inverted BOOL, whether to reverse the foreground and background colors.
*/
- (void) invertScreen: (BOOL) inverted;

/**
    Permit use of the alternate character set.
    This is apparently part of the standard terminal repertoire, but the terminal works fine with this method as a no-op.
 
	This method is a no-op.
*/
- (void) enableAlternateCharacters;

/**
    Reset terminal attributes, and optionally clear the screen.
    This method restores the terminal to ANSI defaults (insert OFF, wrap ON, cursor VISIBLE, cursor position forgotten, full-screen scrolling, plain text attributes). If the parameter specifies a hard reset, the screen is cleared and the cursor is moved to 0, 0, in which case TSScreenContentChangedNotification and TSScreenCursorNotification are both posted.
    @param      hard BOOL, YES if the reset includes clearing the screen contents.
*/
- (void) resetAll: (BOOL) hard;

- (NSString *)html;
@end

/** TextStorageTerminal delegate informal protocol.
    TextStorageTerminal relies on a delegate object to handle controller-layer tasks like printing, transmitting report codes to the terminal's host, and storing text that scrolls off the terminal.
*/
@interface NSObject (TerminalScreenDelegate)

/**
    Send automatic replies to host.
    TextStorageTerminal uses this method to get the terminal to send replies to commands from the host to report its type, status, or cursor location. It's expected that the delegate that receives this message will pass the report data unchanged to the host associated with this terminal.
    @param      screen The TextStorageTerminal sending the report data.
    @param      report The data to send to the host.
*/
- (void) terminalScreen: (TextStorageTerminal *) screen sendsReportData: (NSData *) report;
/**
    Save text that has scrolled off the terminal.
    The TextStorageTerminal sends this message so the delegate can provide a scrollback buffer for the terminal. Any text that is scrolled up (but not down) out of view from the terminal is passed to the delegate through this method. 
 
	This is the one method that delegates must implement. The others are optional.
    @param      screen The TextStorageTerminal on which the scroll-off occurred.
    @param      someText GSAttributedString, the attributed text that scrolled up out of view.
*/
- (void) terminalScreen: (TextStorageTerminal *) screen scrollsOffText: (GSAttributedString *) someText;

@end
