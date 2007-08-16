//
//  TextStorageTerminal.m
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

#import "TextStorageTerminal.h"
#import "NSTextStorageTerminal.h"
#import "NSAttributedString-HTML.h"

@implementation TextStorageTerminal

NSString * const TSScreenContentChangedNotification = @"TSScreenContentChangedNotification";
NSString * const TSScreenAttrsChangedNotification = @"TSScreenAttrsChangedNotification";
NSString * const TSScreenCursorNotification = @"TSScreenCursorNotification";
NSString * const TSScreenScrolledNotification = @"TSScreenScrolledNotification";

NSString * const TSTBlinkingAttribute = @"TSTBlinkingAttribute";
NSString * const TSTInvisibleAttribute = @"TSTInvisibleAttribute";
NSString * const TSTBoldAttribute = @"TSTBoldAttribute";
NSString * const TSTEmailAttribute = @"TSTEmailAttribute";
NSString * const TSTAlternateAttribute = @"TSTAlternateAttribute";
NSString * const TSTProperNameAttribute = @"TSTProperNameAttribute";

static NSMutableDictionary *	sPlainAttributes = nil;

+ (void) initialize
{
	if (self == [TextStorageTerminal class]) {
		sPlainAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
//			[self defaultFont], NSFontAttributeName,
			[self htmlColorForCode: tcGreen], NSForegroundColorAttributeName,
			[NSNumber numberWithInt: 0], NSUnderlineStyleAttributeName,
			[NSNumber numberWithInt: 0], TSTInvisibleAttribute,
			[NSNumber numberWithInt: 0], TSTBlinkingAttribute,
			[NSNumber numberWithInt: 0], TSTBoldAttribute,
			[NSNumber numberWithInt: 0], TSTAlternateAttribute,
			[self htmlColorForCode: tcBlack], NSBackgroundColorAttributeName,
//          [NSColor whiteColor], NSBackgroundColorAttributeName,
			nil];
	}
}

//+ (NSFont *) defaultFont { return [NSFont userFixedPitchFontOfSize: 11]; }

static NSString *   sColors[8] = {
	@"000000",
    @"FF0000",
    @"00FF00",
    @"FFFF00",
    @"0000FF",
    @"FF00FF",
    @"00FFFF",
    @"FFFFFF"
};

+ (NSString *) htmlColorForCode: (TerminalColor) code
{
	return sColors[code];
}

- (NSString *)html
{
    int cursorIndex = [content ensureRow: cursorRow hasColumn: cursorColumn];
    NSString *stringBefore = nil, *stringAfter = nil, *background = nil, *foreground = nil, *cursorChar = nil;

    stringBefore = [[content attributedSubstringFromRange: NSMakeRange(0, cursorIndex)] html];
    stringAfter = [[content attributedSubstringFromRange: NSMakeRange(cursorIndex+1, [content length]-cursorIndex-1)] html];
    //cursorChar = [[content attributedSubstringFromRange: NSMakeRange(cursorIndex, 1)] string]; 
    cursorChar = @"&nbsp;";
    background = @"00FF00";
    foreground = @"000000";

    return [NSString stringWithFormat: @"%@<span style=\"background-color:#%@;color:#%@;\">%@</span>%@", stringBefore, background, foreground, cursorChar, stringAfter];
}

- (id) init
{
	return [self initWithRows: 24 columns: 80];
}

- (id) initWithRows: (int) inRows columns: (int) inColumns
{
	rows = inRows;
	columns = inColumns;
	
	//  Initialize the plain attributes
	
	plainAttributes = [sPlainAttributes mutableCopy];	
	
	[self resetCurrentAttributes];
//	[self setDefaultFont: [plainAttributes objectForKey: NSFontAttributeName]];
	[self setDefaultForeColor: [plainAttributes objectForKey: NSForegroundColorAttributeName]];
//	[self setDefaultBackColor: [plainAttributes objectForKey: NSBackgroundColorAttributeName]];
	[self setDefaultBackColor: [TextStorageTerminal htmlColorForCode: tcBlack]];//[NSColor whiteColor]];
	
	content = [[NSTextStorage alloc] initWithString: @"" attributes: attrDictionary];
	tabStops = (BOOL *) malloc(columns * sizeof(BOOL));

	if (!content || !tabStops) {
		[self release];
		return nil;
	}
		
	[self eraseScreen];
	[self resetTabs];
	
	insertMode = NO;
	wrapMode = YES;
	cursorVisible = YES;
	invertMode = NO;
	
	scrollTop = 0;
	scrollBottom = rows;
	savedCursorRow = savedCursorColumn = 0;
	
	lastCharacter = 0;
	
	//spellingTag = [NSSpellChecker uniqueSpellDocumentTag];
	
	return self;
}

- (NSTextStorage *) textStorage { return content; }

- (void) setAttributedString: (NSAttributedString *) string
{
	[content setAttributedString: string];
}

- (NSDictionary *) currentAttributes { return attrDictionary; }

//- (NSFont *) defaultFont { return defaultFont; }

//- (void) setDefaultFont: (NSFont *) aFont {
//	if (aFont != defaultFont) {
//		[defaultFont release];
//		defaultFont = [aFont retain];
//
//		[content removeAttribute: NSFontAttributeName range: NSMakeRange(0, [content length])];
//		[content addAttribute: NSFontAttributeName value: defaultFont range: NSMakeRange(0, [content length])];
//		
//		[attrDictionary setObject: aFont forKey: NSFontAttributeName];
//		[plainAttributes setObject: aFont forKey: NSFontAttributeName];
//	}
//}

- (NSString *) defaultForeColor { return defaultForeColor; }

- (void) setDefaultForeColor: (NSString *) aColor
{
	if (aColor != defaultForeColor) {
		[defaultForeColor release];
		defaultForeColor = [aColor retain];

		[content removeAttribute: NSForegroundColorAttributeName range: NSMakeRange(0, [content length])];
		[content addAttribute: NSForegroundColorAttributeName value: defaultForeColor range: NSMakeRange(0, [content length])];
		
		[attrDictionary setObject: aColor forKey: NSForegroundColorAttributeName];
		[plainAttributes setObject: aColor forKey: NSForegroundColorAttributeName];
	}
}

- (NSString *) defaultBackColor { return defaultBackColor; }

- (void) setDefaultBackColor: (NSString *) aColor
{
	if (aColor != defaultBackColor) {
		[defaultBackColor release];
		defaultBackColor = [aColor retain];
		
		//  [content removeAttribute: NSBackgroundColorAttributeName range: NSMakeRange(0, [content length])];
		//  [content addAttribute: NSBackgroundColorAttributeName value: defaultBackColor range: NSMakeRange(0, [content length])];
		
		//  [attrDictionary setObject: aColor forKey: NSBackgroundColorAttributeName];
		[attrDictionary removeObjectForKey: NSBackgroundColorAttributeName];
		//  [plainAttributes setObject: aColor forKey: NSBackgroundColorAttributeName];
	}
}

- (NSDictionary *) plainAttributes { return plainAttributes; }

- (void) notifyChangedContent
{
//	NSNotification *	changeNotice = [NSNotification notificationWithName: TSScreenContentChangedNotification object: self];
//	[[NSNotificationCenter defaultCenter] postNotification: changeNotice];
}

- (void) notifyChangedCursor
{
//	NSNotification *	changeNotice = [NSNotification notificationWithName: TSScreenCursorNotification object: self];
//	[[NSNotificationCenter defaultCenter] postNotification: changeNotice];
	deferredCursorWrap = NO;
}

- (void) resizeToRows: (int) newRows columns: (int) newColumns
{
	if (newRows == rows && newColumns == columns)
		return;

	if (cursorColumn >= newColumns) {
		cursorColumn = newColumns-1;
	}
	cursorRow = cursorRow - rows + newRows;
	if (cursorRow < 0)
		cursorRow = 0;
	[self notifyChangedCursor];

	scrollBottom = scrollBottom - rows + newRows;
	
	int		deltaRows = newRows - rows;
	
	columns = newColumns;
	rows = newRows;
	
	//	FIX ME
	//	Come up with a test that narrows the window, leaving characters off the right edge of the text storage. Do such lines ever get truncated? If not, do the orphaned line-ends ever drift into view, say by a delete in the visible part of the line?
	if (deltaRows > 0)
		[content insertLines: deltaRows atLine: 0];
	else
		[content deleteLines: -deltaRows atLine: 0];
	
	tabStops = (BOOL *) realloc(tabStops, columns * sizeof(BOOL));
	[self resetTabs];
		
	[self notifyChangedContent];
}

- (id) delegate { return delegate; }

- (void) setDelegate: (id) newDelegate
{
	if (newDelegate != delegate) {
		if (! [newDelegate respondsToSelector: @selector(terminalScreen:scrollsOffText:)])
			[NSException raise: NSInvalidArgumentException
						format: @"TextStorageTerminal delegate must implement terminalScreen:scrollsOffText:"];
				
		delegate = newDelegate;
	}
}

- (void) dealloc
{
	if (tabStops)
		free(tabStops);
	
	[content release];
	
	[super dealloc];
}

- (int) rows { return rows; }
- (int) columns { return columns; }

- (void) resetCurrentAttributes
{
	invertMode = NO;
	[attrDictionary release];
	attrDictionary = [plainAttributes mutableCopy];
}

- (void) startBold
{
	//  NSFont *		boldFont = [[NSFontManager sharedFontManager] convertWeight: YES ofFont: defaultFont];
	//  [attrDictionary setObject: boldFont forKey: NSFontAttributeName];
	[attrDictionary setObject: [NSNumber numberWithInt: 1] forKey: TSTBoldAttribute];
}

- (void) startUnderline { [attrDictionary setObject: [NSNumber numberWithInt: 1] forKey: NSUnderlineStyleAttributeName]; }

- (void) startBlink
{
	[attrDictionary setObject: [NSNumber numberWithInt: 1]
						forKey: TSTBlinkingAttribute];
}

- (void) startInverse
{
	NSString *		backColor = [attrDictionary objectForKey: NSBackgroundColorAttributeName];
	if (!backColor)
		backColor = defaultBackColor;
	
//	[attrDictionary setObject: [plainAttributes objectForKey: NSBackgroundColorAttributeName] forKey: NSForegroundColorAttributeName];
	[attrDictionary setObject: backColor forKey: NSForegroundColorAttributeName];
	[attrDictionary setObject: [plainAttributes objectForKey: NSForegroundColorAttributeName] forKey: NSBackgroundColorAttributeName];		
	invertMode = YES;
}

- (void) startInvisible
{
	[attrDictionary setObject: [NSNumber numberWithInt: 1]
						forKey: TSTInvisibleAttribute];
}

- (void) startAlternate
{
	[attrDictionary setObject: [NSNumber numberWithInt: 1]
					   forKey: TSTAlternateAttribute];
}

- (void) endBold
{
	//  [attrDictionary setObject: defaultFont forKey: NSFontAttributeName];
	[attrDictionary removeObjectForKey: TSTBoldAttribute];
}

- (void) endUnderline { [attrDictionary setObject: [NSNumber numberWithInt: 0] forKey: NSUnderlineStyleAttributeName]; }

- (void) endBlink
{
	[attrDictionary setObject: [NSNumber numberWithInt: 0]
									  forKey: TSTBlinkingAttribute];
}

- (void) endInverse
{
	[attrDictionary setObject: [plainAttributes objectForKey: NSForegroundColorAttributeName] forKey: NSForegroundColorAttributeName];
//	[attrDictionary setObject: [plainAttributes objectForKey: NSBackgroundColorAttributeName] forKey: NSBackgroundColorAttributeName];
	[attrDictionary removeObjectForKey: NSBackgroundColorAttributeName];
	invertMode = NO;
}

- (void) endInvisible
{
	[attrDictionary setObject: [NSNumber numberWithInt: 0]
									  forKey: TSTInvisibleAttribute];
}

- (void) endAlternate
{
	[attrDictionary setObject: [NSNumber numberWithInt: 0]
					   forKey: TSTAlternateAttribute];
}

- (void) setForeground: (TerminalColor) color
{
	if (invertMode)
		[attrDictionary setObject: [TextStorageTerminal htmlColorForCode: color]
							forKey: NSBackgroundColorAttributeName];
	else
		[attrDictionary setObject: [TextStorageTerminal htmlColorForCode: color]
							forKey: NSForegroundColorAttributeName];
}

- (void) setBackground: (TerminalColor) color
{
	if (invertMode)
		[attrDictionary setObject: [TextStorageTerminal htmlColorForCode: color]
							forKey: NSForegroundColorAttributeName];
	else if (color == tcWhite)
		[attrDictionary removeObjectForKey: NSBackgroundColorAttributeName];
	else
		[attrDictionary setObject: [TextStorageTerminal htmlColorForCode: color]
							forKey: NSBackgroundColorAttributeName];
}

- (void) setPlainForeground
{
	[attrDictionary setObject: [plainAttributes objectForKey: NSForegroundColorAttributeName]
									  forKey: NSForegroundColorAttributeName];
}

- (void) setPlainBackground
{
//	[attrDictionary setObject: [plainAttributes objectForKey: NSBackgroundColorAttributeName]
//						forKey: NSBackgroundColorAttributeName];
	[attrDictionary removeObjectForKey: NSBackgroundColorAttributeName];
}

- (void) enableAlternateCharacters { }

- (void) resetTabs
{
	int		i;
	for (i = 0; i < columns; i++)
		tabStops[i] = (i % 8 == 0);
	defaultTabStops = YES;
}

- (void) clearOneTabStop
{
	tabStops[cursorColumn] = NO;
	defaultTabStops = NO;
}

- (void) clearTabStops
{
	int		i;
	for (i = 0; i < columns; i++)
		tabStops[i] = NO;
	defaultTabStops = NO;
}

- (void) horizontalTab
{
	do {
		cursorColumn++;
	} while (!tabStops[cursorColumn] && cursorColumn < columns);
	
	if (cursorColumn >= columns)
		cursorColumn = columns - 1;
	
	[self notifyChangedCursor];		
}

- (void) backTab
{
	do {
		cursorColumn--;
	} while (!tabStops[cursorColumn] && cursorColumn > 0);
	
	if (cursorColumn < 0)
		cursorColumn = 0;
	
	[self notifyChangedCursor];
}

- (void) hardwareTab
{
	int			delta = 8 - (cursorColumn % 8);
	cursorColumn += delta;
	if (cursorColumn >= columns)
		cursorColumn = columns - 1;
	[self notifyChangedCursor];
}

- (void) setTabStop
{
	if (defaultTabStops) {
		[self clearTabStops];   //  Sets defaultTabStops to NO
	}
	tabStops[cursorColumn] = YES;
}

- (unichar) characterAtRow: (int) row column: (int) column
{
	if (row < 0 || row >= rows || column < 0 || column >= columns) {
		[NSException raise: NSInvalidArgumentException
					format: @"r=%d c=%d is out of bounds", row, column];
	}
	
	return [content characterAtRow: row column: column];
}

- (void) advanceCursor
{
	BOOL		doDeferWrap = NO;
	
	if (++cursorColumn >= columns) {
		if (wrapMode) {
			cursorColumn = 0;
			if (++cursorRow >= scrollBottom) {
				//  [self scrollLines: 1];
				//  cursorRow--;	<== Done in scrollLines
				
				cursorColumn = 0;
				cursorRow = rows-1;
				doDeferWrap = YES;
			}
		}
		else {
			cursorColumn--;
		}
		justWrapped = YES;
	}
	else
		justWrapped = NO;
	
	[self notifyChangedCursor];
	
	if (doDeferWrap)
		deferredCursorWrap = YES;
}

- (void) acceptCharacter: (unichar) aChar
{
	//  NOTE -- changes to this method should be parallelled in -acceptASCII:length:
	if (aChar < ' ')
		return;
	
	if (deferredCursorWrap) {
		[self scrollLines: 1];
		deferredCursorWrap = NO;
	}
	
	lastCharacter = aChar;
		
	if (insertMode)
		[content insertCharacter: aChar atRow: cursorRow column: cursorColumn withAttributes: attrDictionary];
	else {
		[content ensureRow: cursorRow hasColumn: cursorColumn withAttributes: plainAttributes];
		[content replaceCharacter: aChar atRow: cursorRow column: cursorColumn withAttributes: attrDictionary];
	}

	[self notifyChangedContent];
	[self advanceCursor];
}

- (void) acceptASCII: (const void *) chars length: (int) length
{
#if 0
	const char *		buffer = chars;
	while (length--)
		[self acceptCharacter: *buffer++];
#else
	if (length > columns - cursorColumn) {
		int			subLine = columns - cursorColumn;
		[self acceptASCII: chars length: subLine];
		[self acceptASCII: chars + subLine length: length - subLine];
		
		return;
	}
	
	//  NOTE -- changes to this method should be parallelled in -acceptCharacter:
	if (deferredCursorWrap) {
		[self scrollLines: 1];
		deferredCursorWrap = NO;
	}

	NSData *		theData = [NSData dataWithBytesNoCopy: (void *) chars length: length freeWhenDone: NO];
	NSString *		theString = [[NSString alloc] initWithData: theData encoding: NSISOLatin1StringEncoding];
		
	lastCharacter = [theString characterAtIndex: length-1];
	
	
	if (insertMode)
		[content insertString: theString atRow: cursorRow column: cursorColumn withAttributes: attrDictionary];
	else {
        //DEBUG("content 0x%0X ensureRow: %d hasColumn: %d withAttributes: 0x%08X\n", content, cursorRow, cursorColumn+length, plainAttributes);
        [content ensureRow: cursorRow hasColumn: cursorColumn+length withAttributes: plainAttributes];
		[content placeString: theString atRow: cursorRow column: cursorColumn withAttributes: attrDictionary];
	}
	[theString release];
	
	[self notifyChangedContent];
	while (length--)
		[self advanceCursor];	
#endif
}

- (void) repeatLastCharacter: (int) howMany
{
	while (howMany--)
		[self acceptCharacter: lastCharacter];
}

- (void) scrollUp { [self scrollLines: 1]; }
- (void) scrollDown { [self scrollLines: -1]; }

- (void) scrollLines: (int) positiveForUp
{
	if (positiveForUp == 0)
		return;
	
	[content beginEditing];
	NSRange					affectedRange;
	int						shift;
	
	if (positiveForUp > 0) {
		if (scrollTop == 0 && delegate) {
			//  Moved test for whether the delegate responds to this message to setDelegate, in the interest of speed.
			[delegate terminalScreen: self
					  scrollsOffText: [content copyLines: positiveForUp atLine: 0]];
		}

		affectedRange = [content rangeOfLines: NSMakeRange(scrollTop, positiveForUp)];
		[content deleteLines: positiveForUp atLine: scrollTop];
		[content insertLines: positiveForUp atLine: scrollBottom-positiveForUp withAttributes: plainAttributes];
		cursorRow = scrollBottom-1;
		shift = - (int) affectedRange.length;
	}
	else {  //  positiveForUp < 0
		[content deleteLines: -positiveForUp atLine: scrollBottom];
		[content insertLines: -positiveForUp atLine: scrollTop withAttributes: plainAttributes];
		affectedRange = [content rangeOfLines: NSMakeRange(scrollTop, -positiveForUp)];
		cursorRow = scrollTop;
		shift = affectedRange.length;
	}
	
	[content endEditing];
	
	[[NSNotificationCenter defaultCenter]
				postNotificationName: TSScreenScrolledNotification
							  object: self
							userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
											[NSNumber numberWithInt: shift], @"contentShift",
											nil]];
	
	[self notifyChangedContent];
	[self notifyChangedCursor];
}

- (BOOL) insertMode { return insertMode; }
- (void) setInsertMode: (BOOL) newMode { insertMode = newMode; }
- (BOOL) wrapMode { return wrapMode; }
- (void) setWrapMode: (BOOL) newMode { wrapMode = newMode; }
- (BOOL) isCursorVisible { return cursorVisible; }
- (void) setCursorVisible: (BOOL) newVisible { cursorVisible = newVisible; [self notifyChangedCursor]; }
- (BOOL) eatsNewlines { return eatsNewlines; }
- (void) setEatsNewlines: (BOOL) value { eatsNewlines = value; }

- (void) eraseScreen
{
	cursorRow = cursorColumn = 0;
	
	[content deleteLines: [content lineCount] atLine: 0];
	[content ensureRow: cursorRow hasColumn: cursorColumn withAttributes: plainAttributes];

	[self notifyChangedContent];
	[self notifyChangedCursor];
}

- (void) eraseScrollArea
{
	[content eraseLinesFrom: scrollTop to: scrollBottom];	
	cursorRow = scrollTop;
	cursorColumn = 0;
	[self notifyChangedContent];
	[self notifyChangedCursor];
}

- (void) eraseToEndOfScreen
{
	[self eraseToEndOfLine];
	if (cursorRow < rows - 1) {
		[content deleteLines: [content lineCount] - cursorRow atLine: cursorRow+1];
	}
	[self notifyChangedContent];
}

- (void) eraseToStartOfScreen
{
	if (cursorRow > 0)
		[content eraseLinesFrom: 0 to: cursorRow - 1];
	[self eraseToStartOfLine];
}

- (void) scrollAreaTop: (int *) top bottom: (int *) bottom
{
	*top = scrollTop;
	*bottom = scrollBottom;
}

- (void) setScrollAreaTop: (int) top bottom: (int) bottom
{
	if (top >= bottom)
		[NSException raise: NSInvalidArgumentException 
							 format: @"Scroll rect t=%d b=%d has no content", top, bottom];

	scrollTop = top;
	scrollBottom = bottom;
}

- (void) unsetScrollArea
{
	//	FIX ME
	//	The other usages of scrollBottom seem to require that the bottom value be rows, not rows-1.
//	[self setScrollAreaTop: 0 bottom: rows-1];
	[self setScrollAreaTop: 0 bottom: rows];
}

- (int) characterOffsetOfCursor
{
	return [content ensureRow: cursorRow hasColumn: cursorColumn withAttributes: plainAttributes];
}

- (void) cursorLocationX: (int *) cursorX Y: (int *) cursorY
{
	*cursorX = cursorColumn;
	*cursorY = cursorRow;
}

- (void) setCursorLocationX: (int) cursorX Y: (int) cursorY
{
	cursorColumn = cursorX;
	cursorRow = cursorY;
	[self notifyChangedCursor];
}

- (void) moveToRow: (int) cursorToRow column: (int) cursorToColumn
{
	cursorRow = cursorToRow;
	cursorColumn = cursorToColumn;
	[self notifyChangedCursor];
}

- (void) cursorToLine: (int) line
{
	cursorRow = line;
	[self notifyChangedCursor];
}

- (void) cursorToColumn: (int) column
{
	cursorColumn = column;
	[self notifyChangedCursor];
}

- (void) reverseIndex: (int) howMany
{
	cursorRow -= howMany;
	while (cursorRow < scrollTop) {
		cursorRow++;
		[self scrollLines: -1];
	}
	[self notifyChangedCursor];
}

- (void) cursorUp: (int) howMany
{
	cursorRow -= howMany;
	if (cursorRow < 0)
		cursorRow = 0;
	[self notifyChangedCursor];
}

- (void) cursorUp
{
	[self cursorUp: 1];
}

- (void) cursorDown: (int) howMany
{
	cursorRow += howMany;
	if (cursorRow >= rows)
		cursorRow = rows-1;
	[self notifyChangedCursor];
}

- (void) cursorDown
{
	[self cursorDown: 1];
}

- (void) cursorLeft: (int) howMany
{
	cursorColumn -= howMany;
	while (cursorColumn < 0)
    {
        cursorColumn += columns;
        cursorRow--;
    }
    if (cursorRow < 0) {cursorRow = 0; cursorColumn = 0;}
    [self notifyChangedCursor];
}

- (void) cursorLeft
{
	[self cursorLeft: 1];
}

- (void) cursorRight: (int) howMany
{
	cursorColumn += howMany;
	if (cursorColumn >= columns)
		cursorColumn = columns-1;
	[self notifyChangedCursor];
}

- (void) cursorRight
{
	[self cursorRight: 1];
}

- (void) carriageReturn
{
	cursorColumn = 0;
	[self notifyChangedCursor];
}

- (void) lineFeed
{
	if (eatsNewlines && justWrapped) {
		justWrapped = NO;
		return;
	}
	
	cursorRow += 1;
	if (cursorRow >= scrollBottom) {
		//  cursorRow = scrollBottom-1;		//  Done in scrollUp
		[self scrollUp];
		//  deferredCursorWrap = YES;
	}
	else
		[self notifyChangedCursor];
	
}

- (void) saveCursorPosition
{
	savedCursorRow = cursorRow;
	savedCursorColumn = cursorColumn;
}

- (void) restoreCursorPosition
{
	cursorRow = savedCursorRow;
	cursorColumn = savedCursorColumn;
	[self notifyChangedCursor];
}

- (void) homeCursor
{
	cursorRow = cursorColumn = 0;
	[self notifyChangedCursor];
}

- (void) insertLines: (int) howMany
{	
	[content insertLines: howMany atLine: cursorRow];
	
	if ([content lineCount] > rows) {
		[content deleteLines: ([content lineCount] - rows) atLine: scrollBottom];
	}
	
	[self notifyChangedContent];

	if (cursorColumn != 0) {
		cursorColumn = 0;
		[self notifyChangedCursor];
	}
}

- (void) insertLine
{
	[self insertLines: 1];
}

- (void) deleteLines: (int) howMany
{
	[content deleteLines: howMany atLine: cursorRow];

	[content ensureRow: cursorRow hasColumn: cursorColumn withAttributes: plainAttributes];
	//  This has two effects: First, it ensures that the eventual rectArray... message
	//  that gets the cursor rect has a character rect to refer to. Second, it ensures
	//  the terminal string is not empty, and therefore that rangeLeft will not be of
	//  length zero. The drawBackground... message crashes ignominiously if passed a range
	//  of zero length.
	
	[self notifyChangedContent];
	
	if (cursorColumn != 0) {
		cursorColumn = 0;
		[self notifyChangedCursor];
	}
}

- (void) deleteLine
{
	[self deleteLines: 1];
}

- (void) insertCharacters: (int) howMany
{
	if (howMany > columns - cursorColumn)
		howMany = columns - cursorColumn;

	[content insertCharacters: howMany atRow: cursorRow column: cursorColumn];
	[content deleteEndOfLineAtRow: cursorRow column: columns];
	[self notifyChangedContent];
}

- (void) deleteCharacters: (int) howMany
{
	if (howMany > columns - cursorColumn)
		howMany = columns - cursorColumn;
	
	[content deleteCharacters: howMany atRow: cursorRow column: cursorColumn];	
	[self notifyChangedContent];
}

- (void) deleteCharacter
{
	[self deleteCharacters: 1];
}

- (void) eraseCharacters: (int) howMany
{
	if (howMany > columns - cursorColumn)
		howMany = columns - cursorColumn;
	
	[content eraseCharacters: howMany atRow: cursorRow column: cursorColumn withAttributes: plainAttributes];
	[self notifyChangedContent];
}

- (void) eraseCharacter
{
	[self eraseCharacters: 1];
}

- (void) eraseToEndOfLine
{
	[self eraseCharacters: columns - cursorColumn];
}

- (void) eraseToStartOfLine
{
	int			savedColumn = cursorColumn;
	cursorColumn = 0;
	[self eraseCharacters: savedColumn - cursorColumn + 1];
	cursorColumn = savedColumn;
}

- (void) eraseLine
{
	int			savedColumn = cursorColumn;
	cursorColumn = 0;
	[self eraseToEndOfLine];
	cursorColumn = savedColumn;
}

- (void) reportDeviceCode
{
	if (!delegate)
		return;
	
	//  <esc>[?1;2c
	NSMutableData *		deviceData = [NSMutableData dataWithCapacity: 7];
	char				escape = 27;
	char *				body = "[?1;2c";
	[deviceData appendBytes: &escape length: 1];
	[deviceData appendBytes: body length: 6];
	
	[delegate terminalScreen: self sendsReportData: deviceData];
}

- (void) reportDeviceStatus
{
	if (!delegate)
		return;
	
	//  <esc>[0n
	NSMutableData *		deviceData = [NSMutableData dataWithCapacity: 4];
	char				escape = 27;
	char *				body = "[0n";
	[deviceData appendBytes: &escape length: 1];
	[deviceData appendBytes: body length: 3];
	
	[delegate terminalScreen: self sendsReportData: deviceData];
}

- (void) reportCursorPosition
{
	if (!delegate)
		return;
	
	//  <esc>[nnn;nnnR
	NSString *			report = [NSString stringWithFormat: @"\033[%d;%dR", cursorRow+1, cursorColumn+1];
	NSData *			reportData = [report dataUsingEncoding: NSASCIIStringEncoding
										  allowLossyConversion: YES];
	[delegate terminalScreen: self sendsReportData: reportData];
}

- (void) soundBell
{
//	NSBeep();
}

- (void) invertScreen: (BOOL) inverted
{
	NSLog(@"Invert Screen: %@", inverted? @"YES": @"NO");
}

- (void) resetAll: (BOOL) hard
{
	insertMode = NO;
	wrapMode = YES;
	cursorVisible = YES;
	scrollTop = 0;
	scrollBottom = rows;
	savedCursorRow = 0;
	savedCursorColumn = 0;
	
	[self resetCurrentAttributes];
	
	if (hard) {
		[self eraseScreen];
		[self homeCursor];
	}
}

@end
