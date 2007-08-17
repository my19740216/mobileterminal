//
//  TallTextView.m
//  LargeText
//
//  Created by Fritz Anderson on Thu Oct 02 2003.
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

#import "TallTextView.h"
#import "SectionRecord.h"
//#import "TermLayoutManager.h"
#import "TextStorageTerminal.h"
#import "GSTextStorageTerminal.h"

#define INFINITELY_TALL 1.0e7

@implementation TallTextView

+ (void) initialize
{
	if (self == [TallTextView class]) {
		TermLayoutManager *		layout = [[TermLayoutManager alloc] init];
		[SectionRecord setSharedLayoutManager: layout];
		[layout release];
	}
}

- (id) initWithFrame: (NSRect) frame
{
    self = [super initWithFrame:frame];
    if (self) {
		SectionRecord * section = [[SectionRecord alloc] initWithOrigin: 0.0];
		sectionList = [[NSMutableArray alloc] initWithObjects: section, nil];
		[section release];
    }
    return self;
}

- (void) setPageInfo: (NSPrintInfo *) info
{
	[pageInfo release];
	pageInfo = [info retain];
	pageCount = 0;
}

- (NSEnumerator *) sectionEnumerator
{
	return [sectionList objectEnumerator];
}

- (NSEnumerator *) reverseSectionEnumerator
{
	return [sectionList reverseObjectEnumerator];
}

- (void) clearBuffer
{
	[sectionList removeAllObjects];
	SectionRecord * section = [[SectionRecord alloc] initWithOrigin: 0.0];
	[sectionList addObject: section];
	[section release];
	[self recalculateFrame];
}

- (void) dealloc
{
	[pageInfo release];
	[sectionList release];
	[super dealloc];
}

- (BOOL) isFlipped { return YES; }

- (BOOL) becomeFirstResponder
{
	NSAssert([[SectionRecord sharedLayoutManager] isKindOfClass: [TermLayoutManager class]],
			 @"Shared layout manager is expected to understand setParentView:");
	[(TermLayoutManager *) [SectionRecord sharedLayoutManager] setParentView: self];
	return YES;
}

- (void) fillBackground: (NSRect) rect
{
	if ([NSGraphicsContext currentContextDrawingToScreen]) {
		//[[NSColor blackColor] set];
		NSEraseRect(rect);
	}
}

- (void) drawRect: (NSRect) rect
{	
	[self fillBackground: rect];
	
	NSEnumerator *		iter = [self sectionEnumerator];
	SectionRecord *		section;
	
	//  Convert the rect to a non-flipped rect so sections can hit-test:
	//  rect.origin.y += rect.size.height;
	
	while (section = [iter nextObject])
		[section drawRect: rect];
}

- (IBAction) selectAll: (id) sender
{
	startSelSection = [sectionList objectAtIndex: 0];
	endSelSection = [[[self sectionEnumerator] allObjects] lastObject];
	startSelPoint = NSZeroPoint;
	NSRect			bounds = [self bounds];
	endSelPoint = NSMakePoint(NSMaxX(bounds), NSMaxY(bounds));
	[self setNeedsDisplay: YES];
}

- (BOOL) selectionIsEmpty { return endSelSection == nil; }

- (GSAttributedString *) selectedAttributedString
{
	if (endSelSection == nil)
		return nil;
	
	GSMutableAttributedString *		accum = [[GSMutableAttributedString alloc] init];
	NSEnumerator *					iter = [self sectionEnumerator];
	SectionRecord *					section;
	
	while (section = [iter nextObject]) {
		GSAttributedString *	curr = [section selectedAttributedString];
		if (curr)
			[accum appendAttributedString: curr];
	}
	
	return [accum autorelease];
}

- (GSAttributedString *) attributedString
{
	GSMutableAttributedString *		accum = [[GSMutableAttributedString alloc] init];
	NSEnumerator *					iter = [self sectionEnumerator];
	SectionRecord *					section;
	
	while (section = [iter nextObject]) {
		[accum appendAttributedString: [[section content] unicodeAttributedString]];
	}
	
	return [accum autorelease];
}

- (NSString *) string
{
	NSMutableString *	accum = [[NSMutableString alloc] init];
	NSEnumerator *		iter = [self sectionEnumerator];
	SectionRecord *		section;
	
	while (section = [iter nextObject]) {
		[accum appendString: [[section content] unicodeString]];
	}
	
	return [accum autorelease];
}

- (BOOL) writeSelectionToPasteboard: (NSPasteboard *) pboard types: (NSArray *) types
{
	if (! [types containsObject: NSStringPboardType] && ! [types containsObject: NSRTFPboardType])
		return NO;
	
	GSAttributedString *	accum = [self selectedAttributedString];
	[pboard declareTypes: [NSArray arrayWithObjects: NSRTFPboardType, NSStringPboardType, nil]
							  owner: nil];
	[pboard setString: [accum unicodeString] forType: NSStringPboardType];
	[pboard setData: [accum RTFFromRange: NSMakeRange(0, [accum length]) documentAttributes: nil] forType: NSRTFPboardType];
	
	return YES;
}

- (IBAction) copy: (id) sender
{
	GSAttributedString *	accum = [self selectedAttributedString];
	NSPasteboard *			pb = [NSPasteboard generalPasteboard];
	[pb declareTypes: [NSArray arrayWithObjects: NSRTFPboardType, NSStringPboardType, nil]
						owner: nil];
	[pb setString: [accum unicodeString] forType: NSStringPboardType];
	[pb setData: [accum RTFFromRange: NSMakeRange(0, [accum length]) documentAttributes: nil] forType: NSRTFPboardType];
}

- (BOOL) doSearch: (NSString *) target backward: (BOOL) backward caseSensitive: (BOOL) caseSensitive wraps: (BOOL) wraps
{
	if (!target)
		return NO;
	
	SectionRecord *		startingSection;
	NSEnumerator *		iter;
	BOOL				success;
	id					section;

	if (backward) {
		//  Backward search
		startingSection = startSelSection;
		if (!startingSection)
			startingSection = [[[self sectionEnumerator] allObjects] lastObject];
		
		iter = [self reverseSectionEnumerator];
		while ((section = [iter nextObject]) && section != startingSection)
			;
		
		success = NO;
		do {
			success = [section selectString: target
								   backward: YES
							   ignoringCase: !caseSensitive];
			if (success) {
				startSelSection = endSelSection = section;
				return YES;
			}
		} while (!success && (section = [iter nextObject]));
		
		if (! success) {
			NSBeep();
			if (wraps) {
				iter = [self reverseSectionEnumerator];
				while ((section = [iter nextObject]) && !success) {
					success = [section selectString: target
										   backward: YES
									   ignoringCase: !caseSensitive];
					
					if (success) {
						startSelSection = endSelSection = section;
						return YES;
					}
					if (section == startingSection)
						success = YES;
				}
			}
		}
	}
	else {
		//  Forward search
		startingSection = endSelSection;
		if (!startingSection)
			startingSection = startSelSection;
		if (!startingSection)
			startingSection = [sectionList objectAtIndex: 0];
		
		iter = [self sectionEnumerator];
		
		while ((section = [iter nextObject]) && section != startingSection)
			;
		
		success = NO;
		do {
			success = [section selectString: target
								   backward: NO
							   ignoringCase: ! caseSensitive];
			if (success) {
				startSelSection = endSelSection = section;
				return YES;
			}
		} while (!success && (section = [iter nextObject]));
		
		if (! success) {
			NSBeep();
			if (wraps) {
				iter = [self sectionEnumerator];
				while ((section = [iter nextObject]) && !success) {
					success = [section selectString: target
										   backward: NO
									   ignoringCase: ! caseSensitive];
					
					if (success) {
						startSelSection = endSelSection = section;
						return YES;
					}
					if (section == startingSection)
						success = YES;
				}
			}
		}
	}
	
	return NO;
}
/*
- (IBAction) performFindPanelAction: (id) sender
{
	NSString *			target;
	
	switch ([sender tag]) {
		case 2:
			//  Forward search
			target = [CrescatAppDelegate searchString];
			[self doSearch: target backward: NO
			 caseSensitive: [CrescatAppDelegate searchCaseSensitive]
					 wraps: [CrescatAppDelegate searchWraps]];
			[self centerSelectionInVisibleArea: sender];
			[self setNeedsDisplay: YES];
			break;
		case 3: 
			//  Backward search
			target = [CrescatAppDelegate searchString];
			[self doSearch: target backward: YES
			 caseSensitive: [CrescatAppDelegate searchCaseSensitive]
					 wraps: [CrescatAppDelegate searchWraps]];
			[self centerSelectionInVisibleArea: sender];
			[self setNeedsDisplay: YES];
			break;
		case 7: {
			//  Enter selection
			GSAttributedString *	selection = [self selectedAttributedString];
			NSPasteboard *			board = [NSPasteboard pasteboardWithName: NSFindPboard];
			[board declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
			[board setString: [selection string] forType: NSStringPboardType];
		}
			break;
		default:
			[NSApp sendAction: @selector(performFindPanelAction:) to: [self nextResponder] from: sender];
			break;
	}
}*/

- (IBAction) centerSelectionInVisibleArea: (id) sender
{
	NSRect			myBounds = [self bounds];
	
	if (!endSelSection) {
		//  If there's no selection, just scroll to the bottom.
		NSRect		bottomRect = myBounds;
		bottomRect.origin.y = NSMaxY(bottomRect) - 20.0;
		bottomRect.size.height = 20.0;
		[self scrollRectToVisible: bottomRect];
		return;
	}
	
	NSRect			selectionBounds = [startSelSection selectionUnionRect];
	if (!NSEqualRects(selectionBounds, NSZeroRect))
		[self scrollRectToVisible: selectionBounds];	
}

- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>) anItem
{
	if ([anItem action] == @selector(copy:))
		return endSelSection != nil;
	else if ([anItem action] == @selector(centerSelectionInVisibleArea:))
		return YES;
	/*else if ([anItem action] == @selector(performFindPanelAction:)) {
		switch ([anItem tag]) {
			case 7:		return endSelSection != nil;
			case 3:
			case 2:		return [CrescatAppDelegate searchString] != nil;
			default:	return YES;
		}
	}*/
	else
		return NO;
}

- (void) resetCursorRects
{
	NSRect			visibleRect = [self visibleRect];
		
	//  Look for selection rects in all the sections
	NSEnumerator *  iter = [self sectionEnumerator];
	id				curr;
	float			height = 0.0;
	while (curr = [iter nextObject]) {
		NSRect		currRect = visibleRect;
		currRect.origin.y = height;
		currRect.size.height = [curr height];
		height += [curr height];
		
		if (NSIntersectsRect(currRect, visibleRect)) {
			//  Look only in the visible sections
			unsigned		howMany;
			NSRect *		selArea = [curr selectionRects: &howMany];
			//  Any selection rectangles?
			if (selArea) {
				int			i;
				for (i = 0; i < howMany; i++) {
					//  Register the visible portions for the arrow cursor
					NSRect		cursorRect = NSIntersectionRect(selArea[i], visibleRect);
					[self addCursorRect: cursorRect cursor: [NSCursor arrowCursor]];
				}
			}
		}
	}
	
	//  Everything else gets an i-beam
	[self addCursorRect: visibleRect cursor: [NSCursor IBeamCursor]];
}

- (void) recalculateFrame
{
	//  Determine my height (the total of section heights)
	float			totalHeight = 0.0;
	NSEnumerator *  iter = [self sectionEnumerator];
	SectionRecord * section;
	while (section = [iter nextObject])
		totalHeight += [section height];
	
	//  Make sure my frame matches that height
	NSRect				frameRect = [self frame];
//	if (totalHeight > frameRect.size.height) {
		frameRect.size.height = totalHeight;
		[self setFrame: frameRect];
//	}
	
	//  Redraw.
	[self setNeedsDisplay: YES];	
}


- (NSData *) content
{
	NSEnumerator *		iter = [self sectionEnumerator];
	return [NSArchiver archivedDataWithRootObject: [iter allObjects]];
}

- (void) setContent: (NSData *) someContent
{
	//  NSData should be an archived NSArray of SectionRecords.
	//  NOTE WELL that this is not the strict inverse of -content. In the case of IntegratedTSView, the last-archived section will be the terminal section, and this method will put that section into the scrollback.
	[sectionList release];
	sectionList = [[NSUnarchiver unarchiveObjectWithData: someContent] retain];
	NSAssert([sectionList isKindOfClass: [NSArray class]], @"archived content should have been an array");
	[self recalculateFrame];
}


#define MAX_SECTION_HEIGHT  10000.0

- (void) appendAttributedString: (GSAttributedString *) aString
{
	SectionRecord *		section = [sectionList lastObject];
	[section appendAttributedString: aString];
	
	//  If the current section is too tall, retire it by appending a new, empty one.
	if ([section height] > MAX_SECTION_HEIGHT) {
		section = [[SectionRecord alloc] initWithOrigin: [section foot]];
		[sectionList addObject: section];
		[section release];
	}
	
	[self recalculateFrame];
}

- (void) setAttributedString: (GSAttributedString *) aString
{
	NSRange			fullRange = NSMakeRange(0, [aString length]);
	NSRange			currRange = NSMakeRange(0, 0);
	NSString *		string = [aString string];
	
	[self clearBuffer];
	
	while (NSMaxRange(currRange) < NSMaxRange(fullRange)) {
		currRange.length = 20480;
		if (NSMaxRange(currRange) > NSMaxRange(fullRange))
			currRange.length = NSMaxRange(fullRange) - currRange.location;
		
		while (NSMaxRange(currRange) < NSMaxRange(fullRange) && [string characterAtIndex: NSMaxRange(currRange)-1] != '\n')
			currRange.length++;
		
		SectionRecord *		section = [sectionList lastObject];
		[section appendAttributedString: [aString attributedSubstringFromRange: currRange]];
		section = [[SectionRecord alloc] initWithOrigin: [section foot]];
		[sectionList addObject: section];
		[section release];
		
		currRange.location = NSMaxRange(currRange);
		currRange.length = 0;
	}
	
	[self recalculateFrame];
}

- (BOOL) acceptsFirstResponder { return YES; }

- (void) clearSelection
{
	startSelSection = endSelSection = nil;
	startSelPoint = endSelPoint = NSZeroPoint;
	NSEnumerator *		iter = [self sectionEnumerator];
	SectionRecord *		section;
	while (section = [iter nextObject]) {
		[section unhighlight];
	}
	[self setNeedsDisplay: YES];
}

- (void) setEndOfSelection: (NSPoint) endPoint
{
	endSelPoint = endPoint;
	
	NSEnumerator *		iter = [self sectionEnumerator];
	while (endSelSection = [iter nextObject])
		if ([endSelSection containsDepth: endSelPoint.y])
			break;
	
	if (startSelSection == endSelSection) {
		[startSelSection highlightFromPoint: startSelPoint toPoint: endSelPoint mode: selectionMode];
	}
	else {
		iter = [self sectionEnumerator];
		SectionRecord *		section;
		BOOL				highlight = NO;
		while (section = [iter nextObject]) {
			if (section == startSelSection || section == endSelSection) {
				highlight = ! highlight;
				[section highlightFromPoint: startSelPoint toPoint: endSelPoint mode: selectionMode];
			}
			else if (highlight)
				[section highlightFromPoint: startSelPoint toPoint: endSelPoint mode: selectionMode];
		}
	}
	
	[self setNeedsDisplay: YES];
}

- (void) setStartSelSection: (NSPoint) clickPoint
{
	startSelPoint = clickPoint;
	NSEnumerator *		iter = [self sectionEnumerator];
	while (startSelSection = [iter nextObject])
		if ([startSelSection containsDepth: clickPoint.y])
			break;
}

- (BOOL) pointWithinSelection: (NSPoint) aPoint
{
	NSEnumerator *		iter = [self sectionEnumerator];
	id					curr;
	
	while (curr = [iter nextObject]) {
		if ([curr pointWithinSelection: aPoint])
			return YES;
	}
	
	return NO;
}

- (unsigned) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	return NSDragOperationCopy;
}

- (void) mouseDown: (NSEvent *) theEvent
{
	if ([theEvent modifierFlags] & NSControlKeyMask) { 
		[super mouseDown: theEvent];
		return;
	}
	
	NSPoint		mousePoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];	
	
	switch ([theEvent clickCount]) {
		default:
			if (startSelSection && ([theEvent modifierFlags] & NSShiftKeyMask)) {
				[self setEndOfSelection: mousePoint];
				selectionMode = selCharacterMode;
			}
			else if ([self pointWithinSelection: mousePoint] && [theEvent clickCount] == 1) {
				//  Possible start of drag
				selectionMode = selDragMode;
			}
			else {
				//  Normal case: Start of selection
				[self clearSelection];
				[self setStartSelSection: mousePoint];
				selectionMode = selCharacterMode;
			}
				break;
			
		case 2:
			//  [self setStartSelSection: mousePoint];
			[startSelSection selectWordAtPoint: mousePoint];
			endSelSection = startSelSection;
			[self setNeedsDisplay: YES];
			selectionMode = selWordMode;
			break;
			
		case 3:
			//  [self setStartSelSection: mousePoint];
			[startSelSection selectLineAtPoint: mousePoint];
			endSelSection = startSelSection;
			[self setNeedsDisplay: YES];
			selectionMode = selLineMode;
			break;
	}
	
}

- (void) mouseDragged: (NSEvent *) theEvent
{
	NSPoint		mousePoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];

	if (selectionMode == selDragMode) {
		selectionMode = selDidDragMode;
		NSPasteboard *		board = [NSPasteboard pasteboardWithName: NSDragPboard];
		[self writeSelectionToPasteboard: board types:[NSArray arrayWithObjects: NSRTFPboardType, NSStringPboardType, nil]];
		
		NSImage *			tempImage = [[NSImage alloc] initWithSize: NSMakeSize(128, 128)];
		[tempImage lockFocus];
		[[self selectedAttributedString] drawInRect: NSMakeRect(0, 0, [self visibleRect].size.width, 128)];
		[tempImage unlockFocus];
		
		mousePoint.y += 120;
		
		[self dragImage: tempImage 
					 at: mousePoint 
				 offset: NSZeroSize 
				  event: theEvent 
			 pasteboard: board 
				 source: self 
			  slideBack: YES];
		
		[tempImage release];
	}
	else {
		[self autoscroll: theEvent];
		[self setEndOfSelection: mousePoint];
	}
}

- (void) mouseUp: (NSEvent *) theEvent
{
	NSPoint		mousePoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];

	if (selectionMode == selDragMode) {
		//  Click in selection but no drag
		[self clearSelection];
		[self setStartSelSection: mousePoint];
		selectionMode = selCharacterMode;
	}
	else if ((startSelSection == endSelSection || !endSelSection) &&
			ABS(mousePoint.x - startSelPoint.x) < 3.0 &&
			ABS(mousePoint.y - startSelPoint.y) < 3.0) {
		//  So far, we're only interested in seeing if a link was clicked.
		NSURL *			url = [startSelSection attribute: NSLinkAttributeName atPoint: mousePoint];
		NSURL *			email = [startSelSection attribute: TSTEmailAttribute atPoint: mousePoint];
		if (url)
			[[NSWorkspace sharedWorkspace] openURL: url];
		if (email)
			[[NSWorkspace sharedWorkspace] openURL: email];
	}
	[[self window] invalidateCursorRectsForView: self];
}

- (void) adjustPageHeightNew: (float *) newBottom top: (float) top bottom: (float) proposedBottom limit: (float) minBottom
{
	*newBottom = proposedBottom;
	
	NSEnumerator *		iter = [self sectionEnumerator];
	SectionRecord *		section;
	while (section = [iter nextObject])
		if ([section containsDepth: proposedBottom])
			break;
	
	if (section) {
		float		bottom = [section topOfLineWithDepth: proposedBottom];
		if (bottom > minBottom)
			*newBottom = bottom;
	}
}


@end
