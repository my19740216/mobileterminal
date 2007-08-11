//
//  SectionRecord.m
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

#import <UIKit/UIView.h>
#import <UIKit/UIBezierPath.h>
#import "SectionRecord.h"
#import "NSTextStorageTerminal.h"

@implementation SectionRecord

//static NSLayoutManager *	sLayoutManager = nil;
//static NSTextContainer *	sTextContainer = nil;

#define VERY_LARGE 1.0e7
#if 0
+ (void) initialize
{
	if (self == [SectionRecord class]) {
//		sLayoutManager = [[NSLayoutManager alloc] init];
//		sTextContainer = [[NSTextContainer alloc] initWithContainerSize: NSMakeSize(VERY_LARGE, VERY_LARGE)];
//		[sLayoutManager addTextContainer: sTextContainer];
	}
}
#endif
//+ (NSLayoutManager *) sharedLayoutManager { return sLayoutManager; }

//+ (void) setSharedLayoutManager: (NSLayoutManager *) manager
//{
//	if (manager != sLayoutManager) {
//		[sLayoutManager release];
//		sLayoutManager = [manager retain];
//		[sLayoutManager addTextContainer: sTextContainer];
//	}
//}

//+ (NSTextContainer *) sharedTextContainer { return sTextContainer; }
#if 1
- (id) initWithOrigin: (float) yCoord content: (NSAttributedString *) initialContent
{
	if ((self = [self initWithOrigin: yCoord])) {
		[self appendAttributedString: initialContent];
	}
	return self;
}

- (id) initWithOrigin: (float) yCoord
{
	origin = yCoord;
	height = 
		heightOfLastLine = 0.0;
	selectionStart =
		selectionEnd = 0;
	content = [[NSTextStorage alloc] init];
	if (! content) {
		[self release];
		self = nil;
	}
	return self;
}

- (void) dealloc
{
	[content release];
	[super dealloc];
}

- (void) appendAttributedString: (NSAttributedString *) moreContent
{
	//  For each line in the string, scan for fonts and ask the layout manager for the line height.
	//  Add this to the height of the view. Append the string to the text storage. Redisplay.
	
	//  The usual scenario is that the last char in the buffer was a \n. This first text ought to
	//  adjust the height of the last line.
/*	
	NSString *			string = [moreContent string];
	NSRange				wholeLine = NSMakeRange(0, [string length]);
	float				lineHeight;
	
	do {
		unsigned		startIndex, endIndex;
		NSRange			currRange = NSMakeRange(0, 0);
		
		currRange.location = wholeLine.location;
		[string getLineStart: &startIndex end: &endIndex contentsEnd: NULL forRange: currRange];
		NSRange			lineRange = NSMakeRange(startIndex, endIndex-startIndex);
		
		//  Loop through the line by NSFontAttributeName, looking for lineHeight.
		lineHeight = 0.0;
		int				index = startIndex;
		do {
			NSRange		fontRange;
			NSFont *	aFont = [moreContent attribute: NSFontAttributeName atIndex: index effectiveRange: &fontRange];
			index = NSMaxRange(fontRange);
			float		fontHeight = [sLayoutManager defaultLineHeightForFont: aFont];
			if (fontHeight > lineHeight)
				lineHeight = fontHeight;
		} while (index < NSMaxRange(lineRange));
		
		float			deltaHeight;
		if (heightOfLastLine != 0.0 && heightOfLastLine != lineHeight)
			deltaHeight = lineHeight - heightOfLastLine;
		else
			deltaHeight = lineHeight;
		
		height += deltaHeight;
		heightOfLastLine = 0.0;
		
		wholeLine.length -= lineRange.length;
		wholeLine.location += lineRange.length;
	} while (wholeLine.length > 0);
		
	//  WATCH THE FOLLOWING
	//  I think what I want to do is to use heightOfLastLine to ensure
	//  that appends in the middle of lines adjust an existing line height
	//  rather than double-add the height that's already there.
	if ([string characterAtIndex: [string length]-1] != '\n')
		heightOfLastLine = lineHeight;
*/	
	[content appendAttributedString: moreContent];
}

//- (float) origin { return origin; }
//- (float) height { return height; }
//- (float) foot { return origin + height; }

//- (BOOL) containsDepth: (float) depth
//{
//	return depth >= origin && depth < origin+height;
//}

- (NSTextStorage *) content { return content; }

- (void) setContent: (NSTextStorage *) newContent
{
	if (newContent != content) {
		[content release];
		content = [newContent retain];
	}
}

- (unsigned) length { return [content length]; }

- (NSAttributedString *) attributedSubstringFromRange: (NSRange) range
{
	return [[content attributedSubstringFromRange: range] unicodeAttributedString];
}

/*- (NSAttributedString *) selectedAttributedString
{
	if (selectionStart == selectionEnd)
		return nil;
	
	NSRange			glyphRange;
	if (selectionStart > selectionEnd)
		glyphRange = NSMakeRange(selectionEnd, selectionStart-selectionEnd);
	else
		glyphRange = NSMakeRange(selectionStart, selectionEnd-selectionStart);
	
	NSRange			charRange = [sLayoutManager characterRangeForGlyphRange: glyphRange actualGlyphRange: NULL];
	return [self attributedSubstringFromRange: charRange];
}
*/
- (NSString *) backgroundColor
{
	//  Return, as the background color for the whole string, the first background color found in the string. If none is found, or the string is empty, return white.
	
	NSRange			fullRange = NSMakeRange(0, [content length]);
	if (fullRange.length == 0)
		return @"FFFFFF";
	
	NSRange			attrRange = NSMakeRange(0, 0);
	do {
		NSString *	candidate = [content attribute: NSBackgroundColorAttributeName
										   atIndex: NSMaxRange(attrRange)
									effectiveRange: &attrRange];
		if (candidate)
			return candidate;
		else {
			attrRange.location = NSMaxRange(attrRange);
			attrRange.length = 0;
		}
	} while (NSMaxRange(attrRange) < NSMaxRange(fullRange));
	
	return @"FFFFFF";
}
#endif

#if 0
//- (void) drawBackground: (NSRect) backgroundArea
//{
//	/*
//	//  Fill it with the background color
//	if ([NSGraphicsContext currentContextDrawingToScreen]) {
//		[[self backgroundColor] set];
//		NSRectFill(backgroundArea);
//	}
//	 */
//	
//	NSRange				allChars = NSMakeRange(0, [content length]);
//	//  No characters? Nothing more to do.
//	if (allChars.length == 0)
//		return;
//	
//	NSRange				allGlyphs = [sLayoutManager glyphRangeForCharacterRange: allChars actualCharacterRange: NULL];
//	[sLayoutManager drawBackgroundForGlyphRange: allGlyphs atPoint: NSMakePoint(0.0, origin)];	
//}

//- (BOOL) pointWithinSelection: (NSPoint) aPoint
//{
//	unsigned			rectCount;
//	NSRect *			selRects = [self selectionRects: &rectCount];
//	
//	if (!selRects)
//		return NO;
//	
//	int					i;
//	
//	for (i = 0; i < rectCount; i++) {
//		if (NSPointInRect(aPoint, selRects[i]))
//			return YES;
//	}
//	
//	return NO;
//}

//- (NSRect *) selectionRects: (unsigned *) howMany
//{
//	if (selectionStart == selectionEnd) {
//		*howMany = 0;
//		return nil;
//	}
//	
//	static NSRect		retval[3];
//	NSRange				dragRange;
//	
//	if (selectionStart > selectionEnd)
//		dragRange = NSMakeRange(selectionEnd, selectionStart-selectionEnd);
//	else
//		dragRange = NSMakeRange(selectionStart, selectionEnd-selectionStart);
//
//	NSRectArray		bgRects;
//	bgRects = [sLayoutManager rectArrayForGlyphRange: dragRange withinSelectedGlyphRange: dragRange inTextContainer: sTextContainer rectCount: howMany];
//	int				i;
//	for (i = 0; i < *howMany; i++) {
//		retval[i] = bgRects[i];
//		retval[i].origin.y += origin;
//	}
//	
//	return retval;
//}

//- (NSRect) selectionUnionRect
//{
//	unsigned		bgRectCount;
//	NSRect *		bgRects = [self selectionRects: &bgRectCount];
//	
//	if (!bgRects)
//		return NSZeroRect;
//	else {
//		NSRect		retval = bgRects[0];
//		int			i;
//		for (i = 1; i < bgRectCount; i++)
//			retval = NSUnionRect(retval, bgRects[i]);
//		
//		return retval;
//	}
//}

//#define CGMakeRect(_nsrect_) *(CGRect *)&_nsrect_

//- (void) drawInRect: (NSRect) aRect
//{
//	NSRect				myArea = NSMakeRect(0.0, origin, VERY_LARGE, height);
//	myArea = NSIntersectionRect(myArea, aRect);
//	
//	//  Clip to my area (otherwise drawing erases out-of-area)
//	//[NSGraphicsContext saveGraphicsState];
//	UIBezierPath *clipPath = [UIBezierPath bezierPath]; 
//  [clipPath appendBezierPathWithRect: CGMakeRect(myArea)];
//  [clipPath clip];
//  //[[NSBezierPath bezierPathWithRect: myArea] addClip];
//	
//	[sLayoutManager replaceTextStorage: content];
//
//	[self drawBackground: myArea];
//	//  Determine my portion of the view so I can erase it.
//	
//	NSRange				allChars = NSMakeRange(0, [content length]);
//	//  No characters? Nothing more to do.
//	if (allChars.length == 0)
//		return;
//	
//	//	FIX ME
//	//	I don't think this replaceTextStorage: is necessary. Verify that it isn't.
////	[sLayoutManager replaceTextStorage: content];
//	NSRange				allGlyphs = [sLayoutManager glyphRangeForCharacterRange: allChars actualCharacterRange: NULL];
//
//	if (selectionStart != selectionEnd) {
//		NSRange			dragRange;
//		
//		if (selectionStart > selectionEnd)
//			dragRange = NSMakeRange(selectionEnd, selectionStart-selectionEnd);
//		else
//			dragRange = NSMakeRange(selectionStart, selectionEnd-selectionStart);
//		
//		unsigned		bgRectCount;
//		NSRectArray		bgRects;
//		bgRects = [sLayoutManager rectArrayForGlyphRange: dragRange withinSelectedGlyphRange: dragRange inTextContainer: sTextContainer rectCount: &bgRectCount];
//		[[NSColor selectedTextBackgroundColor] set];
//		int				i;
//		for (i = 0; i < bgRectCount; i++)
//			bgRects[i].origin.y += origin;
//		NSRectFillListUsingOperation(bgRects, bgRectCount, NSCompositeCopy); // NSCompositePlusDarker);
//	}
//	
//	[sLayoutManager drawGlyphsForGlyphRange: allGlyphs atPoint: NSMakePoint(0.0, origin)];
////	[NSGraphicsContext restoreGraphicsState];
//}

//- (void) drawRect: (NSRect) aRect
//{
//	NSRect		myRect = NSMakeRect(0.0, origin, 640.0, height); //  Unflipped rect so IntersectsRect works
//	if (NSIntersectsRect(aRect, myRect))
//		[self drawInRect: aRect];
//}

//- (id) attribute: (NSString *) attrName atPoint: (NSPoint) aPoint
//{
//	[sLayoutManager replaceTextStorage: content];
//	float			fraction;
//	aPoint.y -= origin;
//	unsigned		index = [sLayoutManager glyphIndexForPoint: aPoint inTextContainer: sTextContainer fractionOfDistanceThroughGlyph: &fraction];
//	index = [sLayoutManager characterIndexForGlyphAtIndex: index];
//	
//	return [content attribute: attrName atIndex: index effectiveRange: NULL];
//}

//- (void) highlightFromPoint: (NSPoint) startPoint toPoint: (NSPoint) endPoint mode: (DragSelectionMode) mode
//{
//	[sLayoutManager replaceTextStorage: content];
//
//	float		fraction;
//	
//	startPoint.y -= origin;
//	selectionStart = [sLayoutManager glyphIndexForPoint: startPoint inTextContainer: sTextContainer fractionOfDistanceThroughGlyph: &fraction];
//	if (fraction > 0.5)
//		selectionStart++;
//	
//	endPoint.y -= origin;
//	selectionEnd = [sLayoutManager glyphIndexForPoint: endPoint inTextContainer: sTextContainer fractionOfDistanceThroughGlyph: &fraction];
//	if (fraction > 0.5)
//		selectionEnd++;
//	
//	//  Now adjust the selection for selection modes;
//	if (mode == selCharacterMode)
//		return;
//	
//	NSRange			glyphRange = NSMakeRange(MIN(selectionEnd, selectionStart),
//											MAX(selectionEnd, selectionStart) - MIN(selectionEnd, selectionStart));
//	NSRange			charRange = [sLayoutManager characterRangeForGlyphRange: glyphRange actualGlyphRange: NULL];
//	
//	NSString *		string = [content string];
//	unsigned		limit = [string length];
//	
//	if (mode == selWordMode) {
//		static NSCharacterSet *		sWordSet = nil;
//		if (!sWordSet)
//			sWordSet = [[NSCharacterSet characterSetWithCharactersInString:
//				@"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJLKMNOPQRSTUVWXYZ-_@."] retain];
//		
//		while (charRange.location > 0 && [sWordSet characterIsMember: [string characterAtIndex: charRange.location-1]]) {
//			charRange.location--;
//			charRange.length++;
//		}
//		
//		while (NSMaxRange(charRange) < limit && [sWordSet characterIsMember: [string characterAtIndex: NSMaxRange(charRange)]])
//			charRange.length++;		
//	}
//	else {
//		while (charRange.location > 0 && [string characterAtIndex: charRange.location-1] != '\n') {
//			charRange.location--;
//			charRange.length++;
//		}
//		while (NSMaxRange(charRange) < limit) {
//			charRange.length++;
//			if ([string characterAtIndex: NSMaxRange(charRange)] == '\n')
//				break;
//		}
//	}
//	
//	glyphRange = [sLayoutManager glyphRangeForCharacterRange: charRange actualCharacterRange: NULL];
//	selectionStart = glyphRange.location;
//	selectionEnd = NSMaxRange(glyphRange);
//}

//- (void) unhighlight
//{
//	selectionStart =
//		selectionEnd = 0;
//}

//- (NSString *) wordAtPoint: (NSPoint) aPoint
//{
//	[sLayoutManager replaceTextStorage: content];
//	
//	float			fraction;
//	aPoint.y -= origin;
//	unsigned		offset = [sLayoutManager glyphIndexForPoint: aPoint inTextContainer: sTextContainer fractionOfDistanceThroughGlyph: &fraction];
//	NSRange			range = NSMakeRange([sLayoutManager characterIndexForGlyphAtIndex: offset], 1);
//	NSString *		string = [content string];
//	unsigned		lineStart, lineEnd;
//	
//	[string getLineStart: &lineStart end: NULL contentsEnd: &lineEnd forRange: range];
//	
//	NSRange			lineRange = NSMakeRange(lineStart, lineEnd-lineStart);
//	
//	static NSCharacterSet *		sIncluded = nil;
//	if (!sIncluded)
//		sIncluded = [[NSCharacterSet characterSetWithCharactersInString:
//			@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJLKMNOPQRSTUVWXYZ-"] retain];
//	
//	while (NSMaxRange(range) < NSMaxRange(lineRange) && [sIncluded characterIsMember: [string characterAtIndex: NSMaxRange(range)]])
//		range.length++;
//	
//	while (range.location-1 >= lineRange.location && [sIncluded characterIsMember: [string characterAtIndex: range.location-1]]) {
//		range.length++;
//		range.location--;
//	}
//	
//	return [string substringWithRange: range];
//}

//- (void) selectWordAtPoint: (NSPoint) aPoint
//{
//	[sLayoutManager replaceTextStorage: content];
//
//	float			fraction;
//	aPoint.y -= origin;
//	unsigned		offset = [sLayoutManager glyphIndexForPoint: aPoint inTextContainer: sTextContainer fractionOfDistanceThroughGlyph: &fraction];
//	
//	NSRange			range = NSMakeRange([sLayoutManager characterIndexForGlyphAtIndex: offset], 1);
//	NSString *		string = [content string];
//
//	[string getLineStart: &selectionStart end: NULL contentsEnd: &selectionEnd forRange: range];
//	
//	NSRange			lineRange = NSMakeRange(selectionStart, selectionEnd-selectionStart);
//	
//	static NSCharacterSet *		sIncluded = nil;
//	if (!sIncluded)
//		sIncluded = [[NSCharacterSet characterSetWithCharactersInString:
//			@"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJLKMNOPQRSTUVWXYZ-_@."] retain];
//		
//	while (NSMaxRange(range) < NSMaxRange(lineRange) && [sIncluded characterIsMember: [string characterAtIndex: NSMaxRange(range)]])
//		range.length++;
//	
//	while (range.location-1 >= lineRange.location && [sIncluded characterIsMember: [string characterAtIndex: range.location-1]]) {
//		range.length++;
//		range.location--;
//	}
//	
//	range = [sLayoutManager glyphRangeForCharacterRange: range actualCharacterRange: NULL];
//	selectionStart = range.location;
//	selectionEnd = NSMaxRange(range);
//}

//- (void) selectLineAtPoint: (NSPoint) aPoint
//{
//	[sLayoutManager replaceTextStorage: content];
//
//	float			fraction;
//	aPoint.y -= origin;
//	unsigned		offset = [sLayoutManager glyphIndexForPoint: aPoint inTextContainer: sTextContainer fractionOfDistanceThroughGlyph: &fraction];
//	
//	NSRange			range = NSMakeRange([sLayoutManager characterIndexForGlyphAtIndex: offset], 1);
//	
//	[[content string] getLineStart: &selectionStart end: NULL contentsEnd: &selectionEnd forRange: range];
//	
//	range = NSMakeRange(selectionStart, selectionEnd-selectionStart);
//	range = [sLayoutManager glyphRangeForCharacterRange: range actualCharacterRange: NULL];
//	selectionStart = range.location;
//	selectionEnd = NSMaxRange(range);
//}

//- (float) topOfLineWithDepth: (float) depth
//{
//	[sLayoutManager replaceTextStorage: content];
//	depth -= origin;
//	
//	float			fraction;
//	unsigned		offset = [sLayoutManager glyphIndexForPoint: NSMakePoint(0.0, depth)
//												inTextContainer: sTextContainer
//								 fractionOfDistanceThroughGlyph: &fraction];
//	NSRectArray		rects;
//	unsigned		rectCount;
//	rects = [sLayoutManager rectArrayForGlyphRange: NSMakeRange(offset, 1)
//						  withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0)
//								   inTextContainer: sTextContainer
//										 rectCount: &rectCount];
//	return origin + NSMinY(rects[0]);
//}
#endif

#pragma mark ### NSCoding ###
#if 0
//  A SectionRecord that has been through NSCoding is immutable.
//  A descendant of SectionRecord that has been through NSCoding is demoted to SectionRecord.

- (void) encodeWithCoder: (NSCoder *) aCoder
{
	[aCoder encodeValueOfObjCType: @encode(float) at: &origin];
	[aCoder encodeValueOfObjCType: @encode(float) at: &height];
	[aCoder encodeValueOfObjCType: @encode(float) at: &heightOfLastLine];
	
	NSAttributedString *		temp = [[NSAttributedString alloc] initWithAttributedString: content];
	[aCoder encodeObject: temp];
	[temp release];
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
	if ([self class] != [SectionRecord class]) {
		[self release];
		self = [SectionRecord alloc];
	}
	
	[aDecoder decodeValueOfObjCType: @encode(float) at: &origin];
	[aDecoder decodeValueOfObjCType: @encode(float) at: &height];
	[aDecoder decodeValueOfObjCType: @encode(float) at: &heightOfLastLine];
	
	NSAttributedString *		temp = [aDecoder decodeObject];
	content = [[NSTextStorage alloc] initWithAttributedString: temp];
	
	selectionStart = selectionEnd = 0;
	
	return self;
}
#endif
#pragma mark ### Searching ###
#if 0
- (NSRange) searchStringBackwards: (NSString *) target ignoringCase: (BOOL) ignoreCase
{
	unsigned		glyphIndex = selectionStart;
	if (glyphIndex == 0)
		glyphIndex = [content length];
	unsigned		charIndex = [sLayoutManager characterIndexForGlyphAtIndex: glyphIndex];
	NSRange			fullRange = NSMakeRange(0, charIndex);
	NSString *		string = [content string];
	
	return [string rangeOfString: target
						 options: NSBackwardsSearch | (ignoreCase? NSCaseInsensitiveSearch: NSLiteralSearch)
						   range: fullRange];
}

- (NSRange) searchStringForwards: (NSString *) target ignoringCase: (BOOL) ignoreCase
{
	unsigned		charIndex = [sLayoutManager characterIndexForGlyphAtIndex: selectionEnd];
	NSRange			fullRange = NSMakeRange(charIndex, [content length] - charIndex);
	NSString *		string = [content string];
	
	return [string rangeOfString: target
						 options: (ignoreCase? NSCaseInsensitiveSearch: NSLiteralSearch)
						   range: fullRange];
}

- (BOOL) selectString: (NSString *) target backward: (BOOL) goBackFromSelection ignoringCase: (BOOL) ignoreCase
{
	[sLayoutManager replaceTextStorage: content];
	NSRange			newSelection;
	if (goBackFromSelection)
		newSelection = [self searchStringBackwards: target ignoringCase: ignoreCase];
	else
		newSelection = [self searchStringForwards: target ignoringCase: ignoreCase];
	
	if (newSelection.location == NSNotFound) {
		selectionStart = selectionEnd = 0;
		return NO;
	}
	
	newSelection = [sLayoutManager glyphRangeForCharacterRange: newSelection actualCharacterRange: NULL];
	selectionStart = newSelection.location;
	selectionEnd = NSMaxRange(newSelection);
	
	return YES;
}
#endif
@end
