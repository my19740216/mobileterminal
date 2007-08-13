//
//  NSTextStorageTerminal.h
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

#import <Foundation/Foundation.h>
#import "NSAttributedString.h"
#import "NSMutableAttributedString.h"
#import "NSTextStorage.h"

/**	Extensions to NSAttributedString to provide convenient literals and to translate alt-encoded characters into Unicode for export.
	\ingroup	TermModel
*/
@interface NSAttributedString (attributedCharacter)

/**	A single-character attributed string with the given attributes.
	\param	unichar	the single-character content for the string.
	\param	attrs	the attributes the string is to have.
	\retval	NSAttributedString	the single character, with the given attributes.
*/
+ (id) stringWithCharacter: (unichar) ch attributes: (NSDictionary *) attrs;
/**	The space character, with only the given font attribute.
	The result has an attribute dictionary with only the font attribute set.
	\param	aFont				the desired font.
	\retval	NSAttributedString	a space character, in aFont.
*/
//+ (NSAttributedString *) spaceInFont: (NSFont *) aFont;
/**	The newline character, with only the given font attribute.
	The result has an attribute dictionary with only the font attribute set.
	\param	aFont				the desired font.
	\retval	NSAttributedString	a newline character, in aFont.
*/
//+ (NSAttributedString *) newlineInFont: (NSFont *) aFont;
/**	A newline with the given attributes.
	\retval NSAttributedString	a \\n with the given attribute dictionary. Allocated and autoreleased for each call.
*/
+ (NSAttributedString *) newlineWithAttrs: (NSDictionary *) attrs;
/**	A space with the given attributes.
	\retval NSAttributedString	a space character with the given attribute dictionary. Allocated and autoreleased for each call.
*/
+ (NSAttributedString *) spaceWithAttrs: (NSDictionary *) attrs;

/**	Translate internal alt-character coding into Unicode.
	Crescat uses an internal code for ANSI alternate characters that must be drawn specially. These have at least close equivalents in Unicode, but the Unicode characters do not render with uniform spacing in Monaco. This method converts runs with the alt-charset character attributes to Unicode, and returns the plain string.
	\retval	NSString	the content of the receiver, with alt-chars translated into Unicode.
*/
- (NSString *) unicodeString;
/**	Translate internal alt-character coding into Unicode attributed string.
	Crescat uses an internal code for ANSI alternate characters that must be drawn specially. These have at least close equivalents in Unicode, but the Unicode characters do not render with uniform spacing in Monaco. This method converts runs with the alt-charset character attributes to Unicode, and returns the attributed string without the alt-charset attribute.
	\retval	NSAttributedString	a copy of the receiver, with alt-chars translated into Unicode. Formatting not related to alt-char markup is preserved.
*/
- (NSAttributedString *) unicodeAttributedString;

@end

/**	Extensions to NSMutableAttributedString for mass-substituting fonts or colors.
	\ingroup	TermModel
*/
@interface NSMutableAttributedString (attrSubstitution)

/**	Replace all uses of a foreground color with another.
	\param	target		the color to replace.
	\param	newColor	the color to replace with.
*/
- (void) replaceForegroundColor: (NSString *) target withColor: (NSString *) newColor;
/**	Replace all uses of a background color with another.
	\param	target		the color to replace.
	\param	newColor	the color to replace with.
*/
- (void) replaceBackgroundColor: (NSString *) target withColor: (NSString *) newColor;
/**	Replace all instances of a font with another.
	\param	target	the font to look for.
	\param	newFont	the font to replace it with.
*/
//- (void) replaceFont: (NSFont *) target withFont: (NSFont *) newFont;

@end

/**	Utilities for counting and extracting lines in a string.
	\ingroup	TermModel
*/
@interface NSString (lineRange)

/**	The number of lines in the receiver. A line is defined as what ends the string, or what is ended by a newline (\\n) character.
	\retval		int		the number of lines in the receiver.
*/
- (int) lineCount;
/**	The character range of the given line in a string.
	Lines are delimited by the end of the string or newline (\\n) characters. The range does not include the closing newline.
	\param	line	The zero-based index of the line desired.
	\retval	NSRange	The range of all content characters in the line, or {NSNotFound, 0} if line is out-of-range.
*/
- (NSRange) rangeOfLine: (int) line;
/**	The character range of the given lines in a string.
	Lines are delimited by the end of the string or newline (\\n) characters. This is defined as the union of the first line in the range, and the last, including the ending newline. If the end of the range is out-of-range, the returned character range extends to the end of the string. If the beginning of the range is out-of-range, the returned character range is {NSNotFound, 0}.
	\param	lines	NSRange, the lines to extract from the receiver.
	\retval	NSRange	the range of characters in the given lines, including ending newlines.
*/
- (NSRange) rangeOfLines: (NSRange) lines;
/**	Return the row and column of the character at a given index.
	Translates the linear index of the receiving NSString into zero-based line and character number. If the index identifies the newline ending a line, it is reported as column zero of the following row.
	\param[in]	index	the character to identify.
	\param[out]	row		pointer to int, the row the character is on.
	\param[out]	column	pointer to int, the column the character is on.
*/
- (void) index: (int) index atRow: (int *) row column: (int *) column;

@end

/**	Extensions to NSTextStorage that support the row-and-column model of a terminal.
	\ingroup	TermModel
*/
@interface NSTextStorage (terminalExtensions)

/**	The number of lines in the receiver.
	\see NSString(lineRange)#lineCount
	\retval	int		the number of lines (\\n-delimited runs) in the receiver.
*/
- (int) lineCount;
/**	The range of characters in the n'th line of the receiver.
	\see NSString(lineRange)#rangeOfLine:
	\param[in]	line	zero-based index of the line.
	\retval		NSRange	the range of characters, not including \\n, comprising the line.
*/
- (NSRange) rangeOfLine: (int) line;
/**	The range of characters in a range of lines in the receiver.
	\see NSString(lineRange)#rangeOfLines:
	\param[in]	lines	NSRange, zero-based, of the lines of interest.
	\retval		NSRange	the range of characters, including \\n, comprising the lines.
*/
- (NSRange) rangeOfLines: (NSRange) lines;
/**	The row and column corresponding to the n'th character in the receiver.
	\see NSString(lineRange)#index:atRow:column:
	\param[in]	index	the zero-based index of the character in question.
	\param[out]	row		pointer to integer, the row the character occupies.
	\param[out]	column	pointer to integer, the column the parameter occupies.
*/
- (void) index: (int) index atRow: (int *) row column: (int *) column;

/**	Extract N lines beginning at line M of the receiver.
	The result will end in a newline unless the last line was ended with end-of-string. Asking for more lines than are available will yield only as many lines as are there. Asking for where >= the number of lines in the receiver will return nil.
	\param	howMany	int, >= 1, the number of lines to copy
	\param	where	int, >= 0, the first line to copy.
	\retval	NSAttributedString	the substring comprising howMany lines beginning at line where.
*/
- (NSAttributedString *) copyLines: (int) howMany atLine: (int) where;

/**	Make sure a character in the receiver represents {row, column}.
	This is the heart of modeling the terminal in a flat string. A caller can ensure, before setting a character at a row and column, that a space representing that position, front-filled with spaces if necessary, is present in the text storage. This method will append as many newlines as are necessary to ensure that \c row is present in the storage, and then will fill that line with as many spaces as are necessary to ensure that at least \c column + 1 spaces are in that line.

	As the usual intention for calling this method is to secure a place to write characters into the text storage, the method returns the index of the character at {row, column}.

	All whitespace added by this method has the \c NSFontAttributeName set to #defaultFont. If you have more detailed requirements, use #ensureRow:hasColumn:withAttributes:.
	\param	row			integer, the zero-based row
	\param	column		integer, the zero-based column.
	\retval	integer		the index in the text storage of the character for {row, column}.
	\throw	NSAssert	if row or column < 0.
*/
- (int) ensureRow: (int) row hasColumn: (int) column;
	/**	Make sure a character in the receiver represents {row, column}, with specified attributes.
	This and #ensureRow:hasColumn: are the heart of modeling the terminal in a flat string. A caller can ensure, before setting a character at a row and column, that a space representing that position, front-filled with spaces if necessary, is present in the text storage. This method will append as many newlines as are necessary to ensure that \c row is present in the storage, and then will fill that line with as many spaces as are necessary to ensure that at least \c column + 1 spaces are in that line.

	As the usual intention for calling this method is to secure a place to write characters into the text storage, the method returns the index of the character at {row, column}.

	All whitespace added by this method has attributes set to \c attrs.
	\param	row			integer, the zero-based row
	\param	column		integer, the zero-based column.
	\param	attrs		NSDictionary, the attributes to use for inserted characters.
	\retval	integer		the index in the text storage of the character for {row, column}.
	\throw	NSAssert	if row or column < 0.
	\see	#ensureRow:hasColumn:
	*/
- (int) ensureRow: (int) row hasColumn: (int) column withAttributes: (NSDictionary *) attrs;
/**	Insert a character at a row and column, with default attributes.
	\param	ch		Unicode character, the character to insert.
	\param	row		integer, the zero-based row.
	\param	column	integer, the zero-based column.
	\throw	NSAssert	if row or column < 0.
	\see	#insertCharacter:atRow:column:
*/
- (void) insertCharacter: (unichar) ch atRow: (int) row column: (int) column;
/**	Replace a character at a row and column, with existing attributes.
	Bear in mind that in the model of this message, the receiver is notionally at least a (row+1) by (column+1) matrix of spaces, so even if there is no character in the underlying flat string to replace, #ensureRow:hasColumn: will make sure that there will be a space character, representing that position, to replace.
	\param	ch		Unicode character, the character to put in place of the existing one.
	\param	row		integer, the zero-based row.
	\param	column	integer, the zero-based column.
	\throw	NSAssert	if row or column < 0.
*/
- (void) replaceCharacter: (unichar) ch atRow: (int) row column: (int) column;
/**	Insert a character at a row and column, with the given attributes.
	\param	ch		Unicode character, the character to insert.
	\param	row		integer, the zero-based row.
	\param	column	integer, the zero-based column.
	\param	attrs	NSDictionary, the attributes the inserted character is to have.
	\throw	NSAssert	if row or column < 0.
*/
- (void) insertCharacter: (unichar) ch atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs;
	/**	Replace a character at a row and column, with the given attributes.
	\param	ch		Unicode character, the character to put in place of the existing one.
	\param	row		integer, the zero-based row.
	\param	column	integer, the zero-based column.
	\param	attrs	NSDictionary, the attributes the new character is to have.
	\throw	NSAssert	if row or column < 0.
	\see	Commentary at #insertCharacter:atRow:column:
	*/
- (void) replaceCharacter: (unichar) ch atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs;
/**	Insert a given number of blank lines before a line.
	The insertion will have the default attributes (I think).
	\param	howMany	integer, the number of lines to insert.
	\param	where	integer, the zero-based number of the line before which to insert.
	\see #insertLines:atLine:withAttributes:
*/
- (void) insertLines: (int) howMany atLine: (int) where;
/**	Insert a given number of blank lines before a line, with the given attributes.
	\param	howMany	integer, the number of lines to insert.
	\param	where	integer, the zero-based number of the line before which to insert.
	\param	attrs	NSDictionary, the attributes the inserted lines are to have.
	\see #insertLines:atLine:
*/
- (void) insertLines: (int) howMany atLine: (int) where withAttributes: (NSDictionary *) attrs;
/**	Delete a given number of lines beginning at a line.
	\param	howMany	the number of lines to delete.
	\param	where	the zero-based index of the first line to delete.
*/
- (void) deleteLines: (int) howMany atLine: (int) where;
/**	Replace a range of lines with blanks.
	Notionally, this fills the specified lines with space characters, but in practice, it removes all the content between the newline characters that delimit each line.
	\param	firstLine	the zero-based index of the first line to blank out.
	\param	notIncluded	the zero-based index of the first line following that is not to be blanked out.
*/
- (void) eraseLinesFrom: (int) firstLine to: (int) notIncluded;

/**	Delete up to the given number of characters from a line, starting at a column.
	This method removes the lesser of \c howMany characters or the remaining characters on the line, beginning at column \c column of line \c row. The effect will be to close up the contents of the line into the deletion, but not to move characters from line to line.
	\param	howMany	integer, the number of characters to delete.
	\param	row		integer, the zero-based line number.
	\param	column	integer, the zero-based column number of the first character to delete.
*/
- (void) deleteCharacters: (int) howMany atRow: (int) row column: (int) column;
/**	Fills a given line, beginning at a given column, with a number of spaces.
	This is not a deletion; it replaces the contents of the \c howMany characters beginning at column \c column of line \c row, with a run of spaces. The spaces are set to the given attributes. In other words, this blanks-out a field on the screen.
	\param	howMany		integer, the number of spaces to blank.
	\param	row			integer, the zero-based line to blank on.
	\param	column		integer, the zero-based first column to blank.
	\param	attrs		NSDictionary, the attributes for the blanking field.
	\throw	NSAssert	if row or column < 0, or howMany <= 0.
*/
- (void) eraseCharacters: (int) howMany atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs;

/**	Insert a number of spaces at a location in the screen.
	Note well that this category does not enforce any invariants as to maximum line length. The client has to do that.
	\param	howMany		integer, the number of spaces to insert.
	\param	row			integer, the zero-based line to insert on.
	\param	column		integer, the zero-based column to insert on.
	\throw	NSAssert	if row or column < 0, or howMany <= 0.
*/
- (void) insertCharacters: (int) howMany atRow: (int) row column: (int) column;

/**	Insert a string with given attributes at a screen location.
	This category does not enforce line-length invariants; that's the client's job.
	\param	aString	NSString, the text to insert.
	\param	row		integer, the zero-based line to insert on.
	\param	column	integer, the zero-based column to insert at.
	\param	attrs	NSDictionary, the attributes the inserted text is to have.
	\throw	NSAssert	if row or column < 0.
*/
- (void) insertString: (NSString *) aString atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs;
/**	Replace the contents of a string field with a string of certain attributes.
	This replaces the characters beginning at {\c row, \c column}, extending for the length of \c aString, with the contents of aString. The internal representation of the line is grown if necessary to accommodate the string (the line is notionally an infinite string of space characters). It is up to the client to enforce line-length invariants once editing is done.
	\param	aString	NSString, the text to place on the terminal screen.
	\param	row		integer, the zero-based line on which to place the text.
	\param	column	integer, the zero-based column at which the text is to begin.
	\param	attrs	NSDictionary, character attributes for the text.
	\throw	NSAssert	if row or column < 0.
*/
- (void) placeString: (NSString *) aString atRow: (int) row column: (int) column withAttributes: (NSDictionary *) attrs;

/**	Delete characters from a screen location to the end of the line.
	Notionally, this blank-fills the screen from the given position to the right margin. In practice, it removes from text storage the characters from the one representing the position up to the next newline.
	\param	row		integer, the zero-based line on which to delete.
	\param	column	integer, the zero-based column from which to delete.
*/
- (void) deleteEndOfLineAtRow: (int) row column: (int) column;

/**	The character at a given screen position.
	\param	row		integer, the zero-based line for the character.
	\param	column	integer, the zero-based column for the character.
	\retval	unichar	the character at the given position, if one is stored.
	\retval 0xffff	if no character is stored for that position (an unfilled blank, or out-of-bounds).
*/
- (unichar) characterAtRow: (int) row column: (int) column;

/**	The NSTextView associated with this NSTextStorage.
	This method returns the first text view associated with the first container 
    associated with the first layout manager associated with the receiver. Each 
    of those associations can be many-to-one, or null, so this is not a 
    generalizable method. In the context of Crescat, however, in which this 
    method will be used on the text storage of the only container in the only 
    layout manager for a terminal, it's a safe simplification.
	\retval	NSTextView	the view associated with the receiver.
	\retval	nil			if any of the layout manager, container, or view, are empty.
*/
//- (UITextView *) textView;

/**	The range of the first URL found in the given part of the receiver.
	This is a moderately simple-minded search. It looks for the schema strings for http, https, mailto, and ftp, and pursues the first one it finds through a character set it believes valid. The returned range runs from the beginning of the schema to the end of the matched character run. Trailing sentence punctuation (,.;) is trimmed.
	\param	rangeToSearch	NSRange, the limits within which to search for a URL.
	\retval	NSRange			the range of characters containing a presumed URL.
	\retval	{NSNotFound,0}	if no URL is found.
	\see	#rangeOfFirstEmailInRange:
*/
//- (NSRange) rangeOfFirstURLInRange: (NSRange) rangeToSearch;
/**	The range of the first email address found in the given part of the receiver.
	This is another fairly-simple grovel through the text. The method looks for @ signs, then traces forward and back from them to see if the prefix and suffix might be valid user and domain names. Trailing punctuation is trimmed.
	\param	rangeToSearch	NSRange, the limits within which to search for an email address.
	\retval	NSRange			the range of characters containing a presumed email address.
	\retval	{NSNotFound,0}	if no address is found.
	\see	#rangeOfFirstURLInRange:
*/
//- (NSRange) rangeOfFirstEmailInRange: (NSRange) rangeToSearch;
/**	The range of a possible proper name before an offset in the receiver.
	This is the diciest of the special-string searches. The application is that any alpha string (plus hyphen, space, and period) that comes before an email address (skipping over some delimiters) and after the beginning newline may be the proper name of the owner of the address.
	\param	offset			integer, the location before which the name is to be sought.
	\retval	NSRange			the range of characters containing a possible proper name.
	\retval {NSNotFound,0}	if the method is pretty sure there's no name to be found.
	\see	#rangeOfFirstEmailInRange:
*/
//- (NSRange) rangeOfProperNameBeforeOffset: (unsigned) offset;

@end
