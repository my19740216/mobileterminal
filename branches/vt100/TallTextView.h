//
//  TallTextView.h
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

/**
    \file
    Large-text view.
    A TallTextView is a view that presents a large amount of text, changeable only by appending at the end. The text can be selected, copied, printed, searched, and of course displayed.
*/

#import <Foundation/Foundation.h>
#import "GSAttributedString.h"
#import "GSMutableAttributedString.h"

/*
 A TallTextView displays and makes available for selection a large amount of attributed text.
 
 The text arrives serially, and is immutable once appended.
 
 It uses GSTextStorage/NSTextContainer/NSLayoutManager (or my subclasses/specializations)
 to display them, but allocates NSTextView only as needed to service mouse events.
 OR:
 Uses NSLayoutManager to cobble mouse-handling together itself.
 
 First cut, all text is in a single GSTextStorage.
 Second cut, if needed, text is divvied into 500-line TextStorages, with only the last mutable. The rest can comfortably cache dimensions, counts, even images.
 */

#import "SectionRecord.h"

/**	\ingroup	Presentation
	Large-text view.
    A TallTextView is a view that presents a large amount of text, changeable only by appending at the end. The text can be selected, copied, printed, searched, and of course displayed.

	It is implemented by visually stacking sectionRecords, which contain GSTextStorage and know their origin and height in the visual stack. The sectionRecords, and particularly their GSTextStorage, are the model objects underlying this view.
 
	All section records share an NSLayoutManager for purposes of drawing, hit-testing, and highlighting.
*/
@interface TallTextView : NSView <NSUserInterfaceValidations> 
{
	NSMutableArray *		sectionList;
	
	SectionRecord *			startSelSection;
	SectionRecord *			endSelSection;
	NSPoint					startSelPoint;
	NSPoint					endSelPoint;
	DragSelectionMode		selectionMode;
	
	int						pageCount;
	NSPrintInfo *			pageInfo;
}

/**
    Standard Copy action.
    This is an IBAction method for the Copy command. It composes the attributed string from the selected range and fills the pasteboard with both rich- and plain-text versions.
    @param      sender id, the sender by the IBAction protocol.
*/
- (IBAction) copy: (id) sender;
/**
    Find-panel actions.
    The standard Find menu uses a single action (this one) for all commands, distinguishing them by the tags of the menu items. Sender must respond to tag. The search string is shared with, and taken from, the find pasteboard. This method responds to tags 2 (search forward), 3 (search backward), and 7 (enter selection). Anything else is sent up the responder chain.
    @param      sender id, the sender by the IBAction protocol.
*/
//- (IBAction) performFindPanelAction: (id) sender;
/**
    String-search implementation.
    This method implements string search, in all its possible permutations, on the TallTextView. It will search forward or back; case-sensitively or not; wrap at the end or not. If the search succeeds, the found text is selected. If it wraps, it beeps.
    @param      target the string to search for.
    @param      backward whether to search backward from the current selection.
    @param      caseSensitive whether case is significant in matching.
    @param      wraps whether to resume the search at the top if it fails by the end of the document.
    @retval     BOOL whether the target string was found.
*/
//- (BOOL) doSearch: (NSString *) target backward: (BOOL) backward caseSensitive: (BOOL) caseSensitive wraps: (BOOL) wraps;

/**
    Append text to the view.
    Appends the attributed string aString to the GSTextStorage in the last section in line. The last section is the only one subject to revision by appending in this way. If appending makes the section tall enough (currently 10000 pixels), a new section is allocated and added to the end of the list.
    @param      aString GSAttributedString, the text to append to the view.
*/
- (void) appendAttributedString: (GSAttributedString *) aString;
/**
    Empty the view.
    Discards all the sections in the section list and puts a new, empty section in the list. This has the effect of erasing all the contents of the view.
*/
- (void) clearBuffer;
/**
    Replace the view's contents with an attributed string.
    This method starts with a clearBuffer, then adds the aString parameter to the view in large chunks using appendAttributedString:, so that reasonable sectioning will occur.
    @param      aString GSAttributedString, the new contents for the view.
*/
- (void) setAttributedString: (GSAttributedString *) aString;

/**
    Archive of the view's contents.
    This method uses NSArchiver to make an NSData archive of all the sections of the view. This is substantively all you want to save of a TallTextView.
    @retval     An NSData, the archived contents of the view.
*/
- (NSData *) content;
/**
    Set the view's contents from an archive.
    This method uses NSUnarchiver to replace the view's contents with the archived sections in the someContent parameter. 
    @param      someContent NSData, an archive generated with the -content method.
*/
- (void) setContent: (NSData *) someContent;
/**
    Enumerator of text-storage sections.
    This method returns an NSEnumerator that steps through the text sections of the view from first to last. This enumerator is simple in the case of TallTextView, but becomes more interesting in the case of IntegratedTSView, in which the last section is a terminal view.
    @retval     NSEnumerator a forward iterator through the section list.
*/
- (NSEnumerator *) sectionEnumerator;
/**
    Reverse enumerator of text-storage sections.
	This method returns an NSEnumerator that steps through the text sections of the view from last to first. This enumerator is simple in the case of TallTextView, but becomes more interesting in the case of IntegratedTSView, in which the last section is a terminal view.
	@retval     NSEnumerator a reverse iterator through the section list.
*/
- (NSEnumerator *) reverseSectionEnumerator;

/**
    Whether the current selection is empty.
    Returns YES if the current selection has no extent, that is, is just a position between two characters. Useful for determining whether Copy should be active, for instance.
    @retval     BOOL YES if the selection ends where it starts.
*/
- (BOOL) selectionIsEmpty;
/**
    The selected text, as attributed string.
    Returns the selected text as an attributed string, or nil if no text is selected.
    @retval     GSAttributedString the contents of the current selection, or nil if no contents.
*/
- (GSAttributedString *) selectedAttributedString;
/**
    The entire contents as attributed string.
    Returns the entire contents of this view, as an attributed string.
    @retval     GSAttributedString the entire contents of the view.
*/
- (GSAttributedString *) attributedString;
/**
    The entire contents as a plain string.
    Returns the entire contents of this view, as a plain string.
    @retval     NSString the entire contents of the view, without styles.
*/
- (NSString *) string;

/**
    Adjust the total height of the view and redraw.
    Recalculates the height of the view by summing the heights of the sections. Sets the view's frame height accordingly, and then calls setNeedsDisplay: YES.
 
	This is necessary whenever the content of the view changes (or at least whenever a line is added to it). It's how scroll bars get updated.
*/
- (void) recalculateFrame;

/**
    Setter for print settings.
    Accepts and retains NSPrintInfo from the Page Setup dialog.
    @param      info NSPageInfo, the result of a Page Setup dialog.
*/
- (void) setPageInfo: (NSPrintInfo *) info;
/**
    Associate view with a MyDocument.
    This is a cheat, breaking the separation of TallTextView from the details of Crescat. In drawPageBorderWithSize:, one of the adornments for the printed page is the user ID and host address, which are obtained through the MyDocument instance set through this method. I feel so dirty.
    @param      doc MyDocument, the supplier of user and host strings.
*/
//- (void) setDocument: (MyDocument *) doc;

@end
