//
//  SectionRecord.h
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

#import <Foundation/Foundation.h>
#import "GSTextStorage.h"

/**
    \file
    Vertical text component for TallTextView
    The TallTextView, a selectable and scrollable styled text view that accepts only tail-appends as modifications, consists internally of a visual stack of SectionRecords. Each SectionRecord has its own GSTextStorage, knows its origin and how tall it is, and can borrow an NSLayoutManager for drawing and hit testing.
*/

/**
    How selections of text should grow.
    Mouse-down events are asynchronous affairs, so TallText keeps a selection mode to indicate what sort of mouse-down is currently in effect. Selection can be grown by the appropriate unit in the case of multiple clicks, and drag-and-drop of displayed text can be detected.
*/
typedef enum {
	selCharacterMode,	///<	Select by character
	selWordMode,		///<	Select by word
	selLineMode,		///<	Select by line
	selDragMode,		///<	Mouse down in an existing selection, prepare for drag-and-drop.
	selDidDragMode		///<	Drag-and-drop in progress.
}   DragSelectionMode;


/**	Vertical text component for TallTextView.
    The TallTextView, a selectable and scrollable styled text view that accepts only tail-appends as modifications, consists internally of a visual stack of SectionRecords. Each SectionRecord has its own GSTextStorage, knows its origin and how tall it is, and can borrow an NSLayoutManager for drawing and hit testing.
 
	SectionRecord is not an NSView, but it has drawing methods. It is expected that its owner, a view, will defer the drawing of individual sections to the sections themselves.
	\ingroup	Presentation
*/
@interface  SectionRecord : NSObject //<NSCoding>
{
	float				origin;
	float				height;
	float				heightOfLastLine;
	GSTextStorage *		content;
	unsigned			selectionStart;
	unsigned			selectionEnd;
}

/**
    Singleton layout manager for TallTextView/SectionRecord.
    Returns the NSLayoutManager used for all layout and hit-test operations in SectionRecords. All SectionRecords, which keep the several GSTextStorages of TallTextViews, share a single NSLayoutManager.
    @retval     NSLayoutManager the shared layout manager.
*/
//+ (NSLayoutManager *) sharedLayoutManager;
/**
    Set the singleton layout manager for TallTextView/SectionRecord
    The layout manager passed to this method will be used by all SectionRecords in every TallTextView for drawing and hit-testing. Defaults to an NSLayoutManager. Once set, it is assigned the sharedTextContainer, which is defined to be VERY_LARGE x VERY_LARGE. 
 
	In Crescat, TallTextView sets this to be a TermLayoutManager, the specialized layout manager for terminal output.
    @param      manager NSLayoutManager, the layout manager to use.
*/
//+ (void) setSharedLayoutManager: (NSLayoutManager *) manager;
/**
    The text container used in all layout of SectionRecords.
    The singleton text container is created at +initialize time for SectionRecord, and is simply a rectangle of VERY_LARGE x VERY_LARGE, where VERY_LARGE is 1.0e7.
    @retval     The singleton text container.
*/
//+ (NSTextContainer *) sharedTextContainer;
/**
    Initialize section with known content.
    This is a convenience initializer that calls initWithOrigin: and then appendAttributedString:. Use it when you know both the origin and initial content of the section.
    @param      yCoord The depth in the view of the top-left corner of the section.
    @param      initialContent GSAttributedString, the content of the section.
    @retval     self unless the text storage could not be allocated, in which case nil.
*/
- (id) initWithOrigin: (float) yCoord content: (GSAttributedString *) initialContent;
/**
    Designated initializer.
    Creates a SectionRecord with empty text storage, zero height, no selection, and top-left corner at the given origin.
    @param      yCoord Depth in the view of the top-left corner of the section.
    @retval     self or nil if the text storage could not be allocated.
*/
- (id) initWithOrigin: (float) yCoord;

/**
    Add content to the end of the section.
    This method appends the given attributed string to the section's text storage, and adjusts the section's height according to the changes. This is done by querying the layout manager for defaultLineHeightForFont:, rather than doing an actual layout, so discrepancies with drawn layout are conceivable, but have never been observed.
    @param      moreContent GSAttributedString, the content to append to the section.
*/
- (void) appendAttributedString: (GSAttributedString *) moreContent;
/**
    The y-coordinate of the top of the section.
    This is a direct accessor for the origin instance variable. It represents the y-coordinate in flipped (positive-down) coordinates of the top-left corner of the section within the enclosing view.
    @retval     float the y-coordinate of the top of the section.
*/
//- (float) origin;
/**
    Total height of the section.
    This is a direct accessor for the height instance variable. The variable is updated whenever content is added to the section, so it always represents how much vertical screen space will be subtended by the section.
    @retval     float the height of the section.
*/
//- (float) height;
/**
    The bottom coordinate of the section.
    By definition, this is origin + height: The first coordinate that doesn't belong to this section, the place to put the next section.
    @retval     float the bottom y-coordinate of the section.
*/
//- (float) foot;
/**
    Whether a y-coordinate falls within the section.
    A depth (a y-coordinate) is contained in a section if it is >= origin and < foot. This method is useful as the first pass of hit-testing.
    @param      depth float, the y-coordinate to test.
    @retval     BOOL YES if the y-coordinate falls within the section.
*/
//- (BOOL) containsDepth: (float) depth;
/**
    Round a depth down to a line break.
    Given a y-coordinate, return the first y-coordinate above it that is between lines of text. This is useful if the y-coordinate is a proposed page break; adjusting the break to the result of this method will prevent the page break from splitting the line through the middle.
    @param      depth float, a y-coordinate within the section, in the coordinates of the enclosing view.
    @retval     float the y-coordinate of the interline space just above the given depth.
*/
//- (float) topOfLineWithDepth: (float) depth;

/**
    The background color for the section.
    This method returns the first explicitly-set background color in its text storage. If none is set, or the storage is empty, returns white.
    @retval     The empirical background color.
*/
//- (NSColor *) backgroundColor;

/**
    The section's text storage.
    This is a direct accessor for the SectionRecord's GSTextStorage.
    @retval     GSTextStorage the text storage for this SectionRecord.
*/
- (GSTextStorage *) content;
/**
    Set the section's text storage.
    Setter for the SectionRecord's text storage. The existing storage is released.
    @param      newContent GSTextStorage, the new text storage.
*/
- (void) setContent: (GSTextStorage *) newContent;
/**
    The length of the text.
    This is the length of the SectionRecord's GSTextStorage, in characters.
    @retval     Unsigned integer, the length of the section's text.
*/
- (unsigned) length;
/**
    Retrieve substring from attributed content.
    Given a range, retrieves the attributed substring of the section's GSTextStorage that occupies that range. A front for attributedSubstringFromRange: method, with substitutions made for certain graphical characters (see GSAttributedString(attributedCharacter) unicodeAttributedString).
    @param      range NSRange, the portion of the section's text to extract.
    @retval     GSAttributedString the extracted text.
*/
- (GSAttributedString *) attributedSubstringFromRange: (NSRange) range;
/**
    Retrieve the selected substring.
    This is equivalent to deriving an NSRange from the section's selection, and passing it in an -attributedSubstringFromRange: message.
    @retval     GSAttributedString the extracted text.
*/
//- (GSAttributedString *) selectedAttributedString;
/**
    Retrieve text attribute at a location.
    Given a point within the section, determine whether the named attribute is present in the text at that point, and return the value of that attribute if it is. Return nil if it isn't.
    @param      attrName NSString, the attribute sought.
    @param      aPoint NSPoint, the point, in the enclosing view's coordinates, to test.
    @retval     id the value of the attribute in the text at that point, or nil if text or attribute are absent at that point.
*/
//- (id) attribute: (NSString *) attrName atPoint: (NSPoint) aPoint;

/**
    Draw the background for the section text.
    This method uses the shared layout manager to draw the background for all the glyphs in the section's text storage. It is assumed that the layout manager has been set to use the section's text storage.
    @param      sectionArea The area to redraw. Ignored.
*/
//- (void) drawBackground: (NSRect) sectionArea;
/**
    Unconditionally draw background, selection, and text.
    This method points the shared layout manager at this section's text storage, then draws the background. If there is a selection, the selection area is filled with the text-selection color. Finally, the layout manager is used to draw the section's glyphs.
*/
//- (void) drawInRect: (NSRect) aRect;
/**
    Handler for view's drawRect:.
    This is the method the owning NSView would call as it loops through its SectionRecords during -drawRect:. It would pass the NSRect parameter down to this method; if the target rectangle intersects the section's rectangle, the -draw method is called.
    @param      aRect (description)
*/
//- (void) drawRect: (NSRect) aRect;
/**
    Convert drags into selection ranges.
    This is the method an owning view would call while a drag-highlight operation is in progress. The initial point of the drag is passed in startPoint, and the current location in endPoint; the selection mode -- by character, word, or line -- defines how the selection extends. The method converts the endpoints into a selection range.
    @param      startPoint The anchor point of the selection. It is first in time, not position.
    @param      endPoint The end, or current, point of the selection.
    @param      mode DragSelectionMode, selCharacterMode, selWordMode, or (assumed) selLineMode, how to extend the selection.
*/
//- (void) highlightFromPoint: (NSPoint) startPoint toPoint: (NSPoint) endPoint mode: (DragSelectionMode) mode;
/**
    Clear text selection.
    Resets the start and end offsets of the selection to zero, indicating there is no selection in this section.
*/
//- (void) unhighlight;

/**
    Select the word intersecting a given point.
    Select the word under the given NSPoint. The response to a double-click.
    @param      aPoint NSPoint, a point in the enclosing view's coordinates, within this section.
*/
//- (void) selectWordAtPoint: (NSPoint) aPoint;
/**
    The word intersecting a given point.
    Return the word under the given NSPoint. Used in constructing contextual menus, to present to the spelling checker for alternatives.
    @param      aPoint NSPoint, a point in the enclosing view's coordinates, within this section.
    @retval     NSString the word under the point, or nil if none.
*/
//- (NSString *) wordAtPoint: (NSPoint) aPoint;
/**
    Select the line of text intersecting a given point.
    Select the line of text under the given NSPoint. This is the response to a treble-click.
    @param      aPoint NSPoint, a point in the enclosing view's coordinates, within this section.
*/
//- (void) selectLineAtPoint: (NSPoint) aPoint;
/**
    The one NSRect fully enclosing the selection.
    This method calls -selectionRects: to obtain the detailed selection area. If there is no selection, returns NSZeroRect. Otherwise, performs NSUnionRect on all the selection rectangles, and returns the result, the smallest NSRect that encompasses them all.
    @retval     NSRect NSZeroRect if there is no selection, otherwise the smallest NSRect enclosing the selection.
*/
//- (NSRect) selectionUnionRect;
/**
    Selection rectangles (up to three).
    A text selection may be a single rectangle encompassing part of a line. It may also be one rectangle running to the end of a line, another containing one or more whole lines, and a third running from the beginning of the next line; or any ordered combination of those three. This method returns a pointer to an array of three NSRects, describing the section's selection. The reference parameter howMany indicates how many of the NSRects in the array are significant.
 
	The returned array is a static, and is subject to change whenever this method is called.
    @param      howMany Pointer to unsigned int, returns how many of the returned array of NSRects are valid.
    @retval     Pointer to NSRect[3], up to three NSRects describing the selection area.
*/
//- (NSRect *) selectionRects: (unsigned *) howMany;
/**
    Whether a point falls within the text selection.
    This method calls -selectionRects: and returns YES if the given point falls within any of the NSRects describing the selection area.
    @param      aPoint NSPoint, a point in the enclosing view's coordinates, within this section.
    @retval     BOOL YES if the point falls within the selection area.
*/
//- (BOOL) pointWithinSelection: (NSPoint) aPoint;

/**
    Find text in the section.
    This is the implementation of the Find command. Searches start from the end of the current selection for forward searches, or from the beginning of the selection for backward searches. If the search succeeds, the found text is selected.
    @param      target NSString, the text to find.
    @param      goBackFromSelection BOOL, whether to search backwards.
    @param      ignoreCase BOOL, whether to ignore case in the search.
    @retval     BOOL YES if the search succeeded.
*/
//- (BOOL) selectString: (NSString *) target backward: (BOOL) goBackFromSelection ignoringCase: (BOOL) ignoreCase;
@end;

