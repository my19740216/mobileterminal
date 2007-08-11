//
//  NSTextStorageTerminal.m
//  Crescat
//
//  Created by Fritz Anderson on Thu Sep 18 2003.
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

#import "NSTextStorageTerminal.h"
#import "TextStorageTerminal.h"
#import "NSAttributedString.h"
#import "Debug.h"

typedef unichar (*charIMP)(id, SEL, unsigned);

@implementation NSAttributedString (attributedCharacter)

+ (id) stringWithCharacter: (unichar) ch attributes: (NSDictionary *) attrs
{
	return [[[NSAttributedString alloc] initWithString: [NSString stringWithCharacters: &ch length: 1] attributes: attrs] autorelease];
}

/*+ (NSAttributedString *) newlineInFont: (NSFont *) aFont
{
	static NSMutableDictionary *	nlDictionary = nil;
	
	if (! nlDictionary)
		nlDictionary = [[NSMutableDictionary alloc] init];
	
	NSAttributedString *	retval = [nlDictionary objectForKey: aFont];
	if (!retval) {
		retval = [NSAttributedString stringWithCharacter: '\n'
							attributes: [NSDictionary dictionaryWithObjectsAndKeys: 
															aFont, NSFontAttributeName, nil]];
		[nlDictionary setObject: retval forKey: aFont];
	}
	return retval;
}*/

/*+ (NSAttributedString *) spaceInFont: (NSFont *) aFont
{
	static NSMutableDictionary *	spDictionary = nil;
	
	if (! spDictionary)
		spDictionary = [[NSMutableDictionary alloc] init];
	
	NSAttributedString *	retval = [spDictionary objectForKey: aFont];
	if (!retval) {
		retval = [NSAttributedString stringWithCharacter: ' '
											  attributes: [NSDictionary dictionaryWithObjectsAndKeys: 
														aFont, NSFontAttributeName, nil]];
		[spDictionary setObject: retval forKey: aFont];
	}
	return retval;
}*/

+ (NSAttributedString *) newlineWithAttrs: (NSDictionary *) attrs
{
	return [[[NSAttributedString alloc] initWithString: @"\n" attributes: attrs] autorelease];
}

+ (NSAttributedString *) spaceWithAttrs: (NSDictionary *) attrs
{
	return [[[NSAttributedString alloc] initWithString: @" " attributes: attrs] autorelease];
}


typedef struct {
	unichar		code;
	unichar		unicode;
}   AlternateCoding;

static AlternateCoding		sAlternateCodes[] = {
	//  This has to be in order.
	//  It has to be coordinated with the alternates as substituted in ANSICharLineFilter.m and drawn in TermLayoutManager.m
	{ '#', 0x2588 },
	{ '%', 0x259A },
	{ '-', 0x2500 },
	{ '0', 0x2502 },
	{ '1', 0x2514 },
	{ '2', 0x2534 },
	{ '3', 0x2518 },
	{ '4', 0x251C },	
	{ '5', 0x253C },
	{ '6', 0x2524 },	
	{ '7', 0x250C },
	{ '8', 0x252C },	
	{ '9', 0x2510 },
	{ '=', 0x2581 },
	{ 'L', 0x2190 },
	{ 'R', 0x2192 },
	{ 'S', 0x2593 },
	{ '_', 0x2587 },
	{ 0, 0 }
};

- (NSString *) unicodeString
{
	NSMutableString *   retval = [NSMutableString string];
	NSRange				fullRange = NSMakeRange(0, [self length]);
	if (fullRange.length == 0)
		return retval;
	
	NSString *			string = [self string];
	NSRange				attrRange = NSMakeRange(0, 0);
	
	do {
		NSNumber *		value = [self attribute: TSTAlternateAttribute
										atIndex: NSMaxRange(attrRange)
								 effectiveRange: &attrRange];
		if (value && [value intValue]) {
			//  Alternate set. Search for Unicode equivalents.
			int				i;
			for (i = attrRange.location; i < NSMaxRange(attrRange); i++) {
				unichar			ch = [string characterAtIndex: i];
				int				j;
				for (j = 0; sAlternateCodes[j].code && sAlternateCodes[j].code <= ch; j++)
					if (sAlternateCodes[j].code == ch) {
						ch = sAlternateCodes[j].unicode;
						break;
					}
						[retval appendString: [NSString stringWithCharacters: &ch length: 1]];
			}
		}
		else {
			//  Regular Unicode. Pass through.
			[retval appendString: [string substringWithRange: attrRange]];
		}
		attrRange.location = NSMaxRange(attrRange);
		attrRange.length = 0;
	} while (NSMaxRange(attrRange) < NSMaxRange(fullRange));
	
	return retval;
}

- (NSAttributedString *) unicodeAttributedString
{
	NSMutableAttributedString * retval = [self mutableCopy];
	NSRange						fullRange = NSMakeRange(0, [self length]);
	if (fullRange.length == 0)
		return [retval autorelease];
	
	[retval removeAttribute: TSTAlternateAttribute range: fullRange];
	
	NSString *					string = [self string];
	NSRange						attrRange = NSMakeRange(0, 0);
	
	do {
		NSNumber *		value = [self attribute: TSTAlternateAttribute
										atIndex: NSMaxRange(attrRange)
								 effectiveRange: &attrRange];
		if (value && [value intValue]) {
			//  Alternate set. Search for Unicode equivalents.
			int				i;
			for (i = attrRange.location; i < NSMaxRange(attrRange); i++) {
				unichar			ch = [string characterAtIndex: i];
				int				j;
				for (j = 0; sAlternateCodes[j].code && sAlternateCodes[j].code <= ch; j++) {
					if (sAlternateCodes[j].code == ch) {
						ch = sAlternateCodes[j].unicode;
						[retval replaceCharactersInRange: NSMakeRange(i, 1) 
											  withString: [NSString stringWithCharacters: &ch length: 1]];
						break;
					}
				}
			}
		}
		attrRange.location = NSMaxRange(attrRange);
		attrRange.length = 0;
	} while (NSMaxRange(attrRange) < NSMaxRange(fullRange));
	
	return [retval autorelease];
}

@end

@implementation NSMutableAttributedString (attrSubstitution)

/**	Helper method for NSMutableAttributedString(attrSubstitution) that mass-substitutes an arbitrary attribute.
	\param	attr		The name of the attribute to look for.
	\param	target		The value of the attribute to be replaced.
	\param	newValue	The value the attribute is to assume.
*/
- (void) replaceAttribute: (NSString *) attr target: (id) target withValue: (id) newValue
{
	NSRange				fullRange = NSMakeRange(0, [self length]);
	if (fullRange.length == 0)
		return;
	
	NSRange				attrRange = NSMakeRange(0, 0);
	
	do {
		id		value = [self attribute: attr atIndex: NSMaxRange(attrRange) effectiveRange: &attrRange];
		if (value && [value isEqualTo: target]) {
			[self removeAttribute: attr range: attrRange];
			[self addAttribute: attr value: newValue range: attrRange];
		}
	} while (NSMaxRange(attrRange) < NSMaxRange(fullRange));
}

- (void) replaceForegroundColor: (NSString *) target withColor: (NSString *) newColor
{
	[self replaceAttribute: NSForegroundColorAttributeName target: target withValue: newColor];
}

- (void) replaceBackgroundColor: (NSString *) target withColor: (NSString *) newColor
{
	[self replaceAttribute: NSBackgroundColorAttributeName target: target withValue: newColor];
}

//- (void) replaceFont: (NSFont *) target withFont: (NSFont *) newFont
//{
//	[self replaceAttribute: NSFontAttributeName target: target withValue: newFont];
//}

@end


@implementation NSString (lineRange)

- (int) lineCount
{
	int			retval = 1;
	int			i, iLimit = [self length];
	for (i = 0; i < iLimit; i++)
		if ([self characterAtIndex: i] == '\n')
			retval++;
	return retval;
}

- (NSRange) rangeOfLine: (int) line
{
	NSRange			retval = { 0, 0 };
	int				index, length = [self length];
	charIMP			charAtIndex = (charIMP) [self methodForSelector: @selector(characterAtIndex:)];
	
	//  First, seek the line
	for (index = 0; index < length && line > 0; index++) {
		if (charAtIndex(self, @selector(characterAtIndex:), index) == '\n')
			line--;
	}
	
	if (line > 0)
		return NSMakeRange(NSNotFound, 0);
	
	retval.location = index;
	
	for (; index < length; index++) {
		if (charAtIndex(self, @selector(characterAtIndex:), index) == '\n')
			break;
	}
	retval.length = index - retval.location;
	
	return retval;
}

- (NSRange) rangeOfLines: (NSRange) lines
{
	NSRange		firstRange = [self rangeOfLine: lines.location];
	if (firstRange.location == NSNotFound)
		return NSMakeRange(NSNotFound, 0);
	
	if (NSMaxRange(firstRange) < [self length] && [self characterAtIndex: NSMaxRange(firstRange)] == '\n')
		firstRange.length++;
	
	NSRange		lastRange = [self rangeOfLine: NSMaxRange(lines)-1];
	if (lastRange.location == NSNotFound)
		firstRange.length = [self length] - firstRange.location;
	else {
		if (NSMaxRange(lastRange) < [self length] && [self characterAtIndex: NSMaxRange(lastRange)] == '\n')
			lastRange.length++;
		firstRange.length = NSMaxRange(lastRange) - firstRange.location;
	}
	
	return firstRange;
}

/*
 123\n567\n\nAB
*/

- (void) index: (int) index atRow: (int *) row column: (int *) column
{
	int			lclRow = 0;
	int			lclColumn = 0;
	int			i, limit = MIN(index, [self length]);
	unichar		ch = 0;
	
	for (i = 0; i < limit; i++) {
		ch = [self characterAtIndex: i];
		if (ch == '\n') {
			lclRow++;
			lclColumn = 0;
		}
		else
			lclColumn++;
	}
	
	*row = lclRow;
	*column = lclColumn;
}

@end

@implementation NSTextStorage (terminalExtensions)

- (int) lineCount { return [[self mutableString] lineCount]; }

- (NSRange) rangeOfLine: (int) line
{
	return [[self string] rangeOfLine: line];
}

- (NSRange) rangeOfLines: (NSRange) lines
{
	return [[self string] rangeOfLines: lines];
}

- (void) index: (int) index atRow: (int *) row column: (int *) column
{
	[[self mutableString] index: index atRow: row column: column];
}

//- (NSFont *) defaultFont
//{
//	return [NSFont userFixedPitchFontOfSize: 12.0f];
//}
- (int) ensureRow: (int) row hasColumn: (int) column
{
    [self beginEditing];

	//  First ensure that there are enough rows
	NSString *			mString = [self string];
	int					i, iLimit = [mString length];
	
	//  after this loop, i should be the index of the first character of
	//  the row sought
	
	NSAssert(row >= 0, @"Row must be >= 0");
	NSAssert(column >= 0, @"Column must be >= 0");
	
	for (i = 0; i < iLimit && row > 0; i++) {
		if ([mString characterAtIndex: i] == '\n')
			row--;
	}		
	
	if (row) {
		NSAttributedString *	newLine = [[[NSAttributedString alloc] initWithString: @"\n"] autorelease];
		while (row--) {
			[self appendAttributedString: newLine];
			i++;
		}
		
	}
	
	//  i is the index of the first character of the row sought
	//  Now look for the \n at the end of the row
	mString = [self string];
	for (; i < iLimit && column > 0; i++, column--) {
		if ([mString characterAtIndex: i] == '\n')
			break;
	}
	
	int		finalOffset = i + column;
	if (column) {
		NSAttributedString *	space = [[[NSAttributedString alloc] initWithString: @" "] autorelease];
		while (column--) {
			[self insertAttributedString: space atIndex: i];
		}		
	}

	mString = [self string];
	if (finalOffset == [mString length] || [mString characterAtIndex: finalOffset] == '\n')
		[[self mutableString] insertString: @" " atIndex: finalOffset];
	
	[self endEditing];

	//  By here, the range finalOffset, width 1, is at row, column.
	return finalOffset;
}

- (int) ensureRow: (int) row hasColumn: (int) column withAttributes: (NSDictionary *) attrs
{
    [self beginEditing];
	
    //  First ensure that there are enough rows
	NSString *			mString = [self string];
	int					i, iLimit = [mString length];
	
	//  after this loop, i should be the index of the first character of
	//  the row sought
	
	NSAssert(row >= 0, @"Row must be >= 0");
	NSAssert(column >= 0, @"Column must be >= 0");

	charIMP				charAtIndex = (charIMP) [mString methodForSelector: @selector(characterAtIndex:)];
	
	for (i = 0; i < iLimit && row > 0; i++) {
		//  if ([mString characterAtIndex: i] == '\n')
		if (charAtIndex(mString, @selector(characterAtIndex:), i) == '\n')
			row--;
	}
    
	if (row) {
		NSAttributedString *	newLine = [NSAttributedString newlineWithAttrs: attrs];
		while (row--) {
			[self appendAttributedString: newLine];
			i++;
		}
		
	}

	//  i is the index of the first character of the row sought
	//  Now look for the \n at the end of the row
	mString = [self string];
	for (; i < iLimit && column > 0; i++, column--) {
		//  if ([mString characterAtIndex: i] == '\n')
		if (charAtIndex(mString, @selector(characterAtIndex:), i) == '\n')
			break;
	}
	int finalOffset = i + column;
	if (column) {
		NSAttributedString *	space = [NSAttributedString spaceWithAttrs: attrs];
     
        while (column--) {
			[self insertAttributedString: space atIndex: i];
		}
	}
	
    mString = [self string];
	if (finalOffset == [mString length] || [mString characterAtIndex: finalOffset] == '\n')
		[[self mutableString] insertString: @" " atIndex: finalOffset];

    [self endEditing];

    //  By here, the range finalOffset, width 1, is at row, column.
	return finalOffset;
}

- (void) insertCharacter: (unichar) ch atRow: (int) row column: (int) column
{
	[self beginEditing];
	int			offset = [self ensureRow: row hasColumn: column];
	[[self mutableString] insertString: [NSString stringWithCharacters: &ch length: 1] atIndex: offset];
	[self endEditing];
}

- (void) replaceCharacter: (unichar) ch atRow: (int) row column: (int) column
{
	[self beginEditing];
	int					offset = [self ensureRow: row hasColumn: column];
	NSMutableString *   mString = [self mutableString];
	
	if ([mString characterAtIndex: offset] == '\n')
		[self insertCharacter: ch atRow: row column: column];
	else
		[mString replaceCharactersInRange: NSMakeRange(offset, 1)
								withString: [NSString stringWithCharacters: &ch length: 1]];
	[self endEditing];
}

- (void) insertCharacter: (unichar) ch atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs
{
	[self beginEditing];
	int			offset = [self ensureRow: row hasColumn: column];
	[self insertAttributedString: [NSAttributedString stringWithCharacter: ch attributes: attrs] atIndex: offset];
	[self endEditing];
}

- (void) insertString: (NSString *) aString atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs
{
	[self beginEditing];
	//  int			offset = [self ensureRow: row hasColumn: column];
	int			offset = [self ensureRow: row hasColumn: column withAttributes: attrs];
	NSAttributedString *	attrString = [[NSAttributedString alloc] initWithString: aString attributes: attrs];
	[self insertAttributedString: attrString atIndex: offset];
	[self endEditing];
}

- (void) replaceCharacter: (unichar) ch atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs
{
	[self beginEditing];
	//  int					offset = [self ensureRow: row hasColumn: column];
	int					offset = [self ensureRow: row hasColumn: column withAttributes: attrs];
	NSMutableString *   mString = [self mutableString];
	
	NSAssert(mString != nil, @"Has to have a mutable string behind it");
	
	if (offset == [mString length] || [mString characterAtIndex: offset] == '\n')
		[self insertCharacter: ch atRow: row column: column withAttributes: attrs];
	else {
		[self replaceCharactersInRange: NSMakeRange(offset, 1)
					withAttributedString: [NSAttributedString stringWithCharacter: ch attributes: attrs]];
	}
	[self endEditing];
}

- (void) placeString: (NSString *) aString atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs
{
	//  Caller is responsible for calling [self ensureRow: row hasColumn: column+[aString length] withAttributes: plain]
	[self beginEditing];
	int						length = [aString length];
	//  int						offset = [self ensureRow: row hasColumn: column + length];
	int						offset = [self ensureRow: row hasColumn: column + length withAttributes: attrs];
	NSAttributedString *	attrString = [[NSAttributedString alloc] initWithString: aString attributes: attrs];

	[self replaceCharactersInRange: NSMakeRange(offset - length, length) withAttributedString: attrString];
	[attrString release];

	[self endEditing];
}

- (void) insertLines: (int) howMany atLine: (int) where
{
	if (howMany <= 0)
		return;
	
	NSMutableString *   mString = [self mutableString];
	NSRange				range = [mString rangeOfLine: where];
	if (range.location == NSNotFound) {
		[self ensureRow: where+howMany-1 hasColumn: 0];
	}
	else {
		[self beginEditing];
		while (howMany--) {
			[mString insertString: @"\n" atIndex: range.location];
		}
		[self endEditing];
	}
}

- (void) insertLines: (int) howMany atLine: (int) where withAttributes: (NSDictionary *) attrs
{
	if (howMany <= 0)
		return;
	
	NSRange				range = [self rangeOfLine: where];
	if (range.location == NSNotFound) {
		[self ensureRow: where+howMany-1 hasColumn: 0 withAttributes: attrs];
	}
	else {
		[self beginEditing];
		NSAttributedString *	newLine = [NSAttributedString stringWithCharacter: '\n' attributes: attrs];
		while (howMany--) {
			[self insertAttributedString: newLine atIndex: range.location];
		}
		[self endEditing];
	}
}

- (void) deleteLines: (int) howMany atLine: (int) where
{
	if (howMany <= 0)
		return;
	
	NSMutableString *   mString = [self mutableString];
	NSRange				range = [mString rangeOfLine: where];
	
	if (range.location == NSNotFound)
		return;
	
	int					i, length = [mString length];
	
	for (i = NSMaxRange(range); i < length && howMany > 0; i++) {
		if ([mString characterAtIndex: i] == '\n')
			howMany--;
	}
	
	range.length = i - range.location;
	[self deleteCharactersInRange: range];
}

- (NSAttributedString *) copyLines: (int) howMany atLine: (int) where
{
	if (howMany <= 0)
		return nil;
	
	NSString *  mString = [self mutableString];
	NSRange		range = [mString rangeOfLine: where];
	
	if (range.location == NSNotFound)
		return nil;
	
	int					i, length = [mString length];
	
	for (i = NSMaxRange(range); i < length && howMany > 0; i++) {
		if ([mString characterAtIndex: i] == '\n')
			howMany--;
	}
	
	range.length = i - range.location;
	return [self attributedSubstringFromRange: range];
}

- (void) deleteCharacters: (int) howMany atRow: (int) row column: (int) column
{
	NSRange				lineRange = [self rangeOfLine: row];
	
	if (lineRange.location == NSNotFound)
		return;
	
	NSRange				deleteRange = NSMakeRange(lineRange.location + column, howMany);
	deleteRange = NSIntersectionRange(lineRange, deleteRange);
	//  [self deleteCharactersInRange: deleteRange];
	[self replaceCharactersInRange: deleteRange withString: @""];
}

/**	Remove every character between the beginning of a line and a column, inclusive.
	This has the effect of moving the content after \c column to the beginning of the line. Attempting to delete more characters than are on a line (nonexistent line, column beyond what is written) is safe. Lines will not be merged by this operation.
	\param	row		integer, the zero-based index of the line on which to do the deletion.
	\param	column	integer, the zero-based index of the last character on the line to delete.
*/
- (void) deleteStartOfLineAtRow: (int) row column: (int) column
{
	[self deleteCharacters: column+1 atRow: row column: column];
}

- (void) deleteEndOfLineAtRow: (int) row column: (int) column
{
	NSRange			lineRange = [self rangeOfLine: row];
	if (lineRange.location == NSNotFound)
		return;
	
	NSRange			deleteRange = NSMakeRange(lineRange.location + column, lineRange.length - column);
	deleteRange = NSIntersectionRange(deleteRange, lineRange);
	if (deleteRange.length > 0)
		[self deleteCharactersInRange: deleteRange];
}

- (void) insertCharacters: (int) howMany atRow: (int) row column: (int) column
{
	NSAssert1(howMany > 0, @"Attempt to insert %d characters", howMany);
	
	[self beginEditing];
	int						offset = [self ensureRow: row hasColumn: column + howMany];
	offset = offset - howMany;
	NSMutableString *		blanks = [NSMutableString stringWithCapacity: howMany];
	
	while (howMany--)
		[blanks appendString: @" "];
	[[self mutableString] insertString: blanks atIndex: offset];
	[self endEditing];
}

- (void) eraseLinesFrom: (int) firstLine to: (int) notIncluded
{
	[self beginEditing];
	int			i;
	for (i = firstLine; i < notIncluded; i++) {
		[self ensureRow: i hasColumn: 0];
		NSRange			lineRange = [self rangeOfLine: i];
		if (lineRange.length > 0) {
			[self deleteCharactersInRange: lineRange];
		}
	}
	[self endEditing];
}

- (unichar) characterAtRow: (int) row column: (int) column
{
	//  First ensure that there are enough rows
	NSMutableString *   mString = [self mutableString];
	unichar				ch;
	int					i, iLimit = [mString length];
	
	//  after this loop, i should be the index of the first character of
	//  the row sought
	
	for (i = 0; i < iLimit && row > 0; i++) {
		ch = [mString characterAtIndex: i];
		if (ch == '\n')
			row--;
	}		
	
	if (row > 0) {
		return 0xffff;
	}
	
	//  i is the index of the first character of the row sought
	//  Now look for the \n at the end of the row
	
	for (; i < iLimit && column > 0; i++, column--) {
		ch = [mString characterAtIndex: i];
		if (ch == '\n')
			break;
	}
	
	if (column > 0 || [mString characterAtIndex: i] == '\n') {
		return 0xffff;
	}
	
	return [mString characterAtIndex: i];
}
/*
- (UITextView *) textView
{
	NSArray *			layouts = [self layoutManagers];
	if ([layouts count] < 1)
		return nil;
	
	NSArray *			containers = [[layouts objectAtIndex: 0] textContainers];
	if ([containers count] < 1)
		return nil;
	
	return [[containers objectAtIndex: 0] textView];
}*/

- (void) eraseCharacters: (int) howMany atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs
{
	NSAssert1(howMany > 0, @"Attempt to erase %d characters", howMany);
	
	[self beginEditing];
	int						offset = [self ensureRow: row hasColumn: column + howMany withAttributes: attrs];
	NSMutableString *		blanks = [NSMutableString stringWithCapacity: howMany];
	int						count = howMany;
	NSRange					eraseRange = NSMakeRange(offset-howMany, howMany);
	
	while (count--)
		[blanks appendString: @" "];
	[[self mutableString] replaceCharactersInRange: eraseRange withString: blanks];
	[self setAttributes: attrs range: eraseRange];
	
	[self endEditing];
}

- (NSRange) rangeOfFirstURLInRange: (NSRange) rangeToSearch
{
	NSString *		string = [self string];
	NSRange			httpRange = [string rangeOfString: @"http://" options: 0 range: rangeToSearch];
	NSRange			httpsRange = [string rangeOfString: @"https://" options: 0 range: rangeToSearch];
	NSRange			mailToRange = [string rangeOfString: @"mailto:" options: 0 range: rangeToSearch];
	NSRange			ftpRange = [string rangeOfString: @"ftp://" options: 0 range: rangeToSearch];
	NSRange			retval;
	
	if (httpRange.location != NSNotFound && httpRange.location < mailToRange.location && httpRange.location < ftpRange.location && httpRange.location < httpsRange.location) {
		retval = httpRange;
	}
	else if (httpsRange.location != NSNotFound && httpsRange.location < mailToRange.location && httpsRange.location < ftpRange.location && httpsRange.location < httpRange.location) {
		retval = httpsRange;
	}
	else if (mailToRange.location != NSNotFound && mailToRange.location < httpRange.location && mailToRange.location < ftpRange.location && mailToRange.location < httpsRange.location) {
		retval = mailToRange;
	}
	else if (ftpRange.location != NSNotFound && ftpRange.location < httpRange.location && ftpRange.location < mailToRange.location && ftpRange.location < httpsRange.location) {
		retval = ftpRange;
	}
	else
		return NSMakeRange(NSNotFound, 0);
	
	static NSCharacterSet *		urlCharset = nil;
	if (! urlCharset)
		urlCharset = [[NSCharacterSet characterSetWithCharactersInString: @"0123456789=@%./?,:;_-~&abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"] retain];
	while (NSMaxRange(retval) < [string length] && [urlCharset characterIsMember: [string characterAtIndex: NSMaxRange(retval)]])
		retval.length++;
	
	unichar						lastChar = [string characterAtIndex: NSMaxRange(retval)-1];
	if (lastChar == '.' || lastChar == ';' || lastChar == ',')
		retval.length--;
	
	return retval;
}

- (NSRange) rangeOfFirstEmailInRange: (NSRange) rangeToSearch
{
	if (rangeToSearch.length == 0)
		return NSMakeRange(NSNotFound, 0);
	
	NSString *		string = [self string];
	NSRange			seedRange = NSMakeRange(rangeToSearch.location+1, rangeToSearch.length-1);

	do {
		//  Top-of-loop invariant: seedRange is the remaining length of the string (less 1 because a terminal @ doesn't count).
		seedRange.length = rangeToSearch.length - (seedRange.location - rangeToSearch.location) - 1;
		//  Grow the found range from the @.
		seedRange = [string rangeOfString: @"@" options: 0 range: seedRange];
		
		//  No @, no address.
		if (seedRange.location == NSNotFound)
			return seedRange;
		
		static NSCharacterSet *		userCharset = nil;
		if (!userCharset)
			userCharset = [[NSCharacterSet characterSetWithCharactersInString: @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+-_."] retain];
		
		//  Grow back from the @
		while (seedRange.location-1 >= rangeToSearch.location && [userCharset characterIsMember: [string characterAtIndex: seedRange.location-1]]) {
			seedRange.location--;
			seedRange.length++;
		}
		
		//  Can't grow back? Look for another @
		if ([string characterAtIndex: seedRange.location] == '@') {
			seedRange.location++;
			seedRange.length = 0;
			continue;
		}
		
		//  Grow forward from the @.
		static NSCharacterSet *		domainCharset = nil;
		if (!domainCharset)
			domainCharset = [[NSCharacterSet characterSetWithCharactersInString: @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-."] retain];
		
		while (NSMaxRange(seedRange) < NSMaxRange(rangeToSearch) && [domainCharset characterIsMember: [string characterAtIndex: NSMaxRange(seedRange)]])
			seedRange.length++;
		
		//  Forgive ending punctuation.
		while ([string characterAtIndex: NSMaxRange(seedRange)-1] == '.' || [string characterAtIndex: NSMaxRange(seedRange)-1] == '-')
			seedRange.length--;
		
		//  Empty domain? Look for another.
		if ([string characterAtIndex: NSMaxRange(seedRange)-1] == '@') {
			seedRange.location = NSMaxRange(seedRange);
			seedRange.length = 0;
		}
		else if ([[string substringWithRange: seedRange] rangeOfString: @"."].location == NSNotFound) {
			//  seedRange contains a probable address but no period.
			seedRange.location = NSMaxRange(seedRange);
			seedRange.length = 0;
		}
		else {
			//  seedRange contains a probable address with a period.
			return seedRange;
		}
	} while (NSMaxRange(seedRange) < NSMaxRange(rangeToSearch));
	
	return NSMakeRange(NSNotFound, 0);
}

- (NSRange) rangeOfProperNameBeforeOffset: (unsigned) offset
{
	NSRange			retval = NSMakeRange(offset, 0);
	NSString *		string = [self string];
	
	static NSCharacterSet *		domainCharset = nil;
	if (!domainCharset)
		domainCharset = [[NSCharacterSet characterSetWithCharactersInString: @" abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-."] retain];
	
	//  First, move backward over any non-domain characters.
	//  Any newline is poison.
	while (retval.location-- >= 0) {
		unichar			ch = [string characterAtIndex: retval.location];
		if (ch == '\n')
			return NSMakeRange(NSNotFound, 0);
		if ([domainCharset characterIsMember: ch]) {
			retval.length = 1;
			break;
		}
	}
	
	//  retval contains one character in the domain. Grow it.
	while (retval.location-1 >= 0 && [domainCharset characterIsMember: [string characterAtIndex: retval.location-1]]) {
		retval.location--;
		retval.length++;
	}
	
	//  Trim leading white space
	while (retval.length && [string characterAtIndex: retval.location] == ' ') {
		retval.location++;
		retval.length--;
	}
	
	//  Trim trailing white space
	while (retval.length && [string characterAtIndex: NSMaxRange(retval)-1] == ' ')
		retval.length--;
	
	//  Assume a name has to contain at least one embedded space
	if ([[string substringWithRange: retval] rangeOfString: @" "].location == NSNotFound)
		return NSMakeRange(NSNotFound, 0);
	
	return retval;
}

@end
