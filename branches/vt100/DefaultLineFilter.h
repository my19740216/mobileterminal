//
//  DefaultLineFilter.h
//  Crescat
//
//  Created by Fritz Anderson on Fri Sep 05 2003.
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

#import "CharacterLineFilter.h"

/**	\ingroup LineFilters
	Base class for default line filters.
	This class encompasses behavior common to ANSI and xterm line filters. The default filters behave the same, but the escape and alt-char line filters differ. Subclasses just produce the proper CharacterLineFilter subclasses for those filter types.
*/
@interface DefaultLineFilter : CharacterLineFilter {
}

/**	Initialize as the default line filter.
	A DefaultLineFilter has no fallback, so none need be specified, but it must be told of its target terminal. 
	\param[in]	terminal	The target terminal.
	\retval		self		The receiver.
*/
- (id) initWithTerminal: (id) terminal;
/**	Process a character in the manner common to ANSI and xterm terminals.
	If an escape or start-alt-char character comes in, the result of #escapeLineFilter or #altCharLineFilter is returned.
	\param[in]	aCharacter	A character (expect ISO-Latin-1) from the host.
	\retval		self		if the receiver is the next-character handler.
	\retval		escapeLineFilter if aCharacter was escape.
	\retval		altCharLineFilter if aCharacter was 0xE.
*/
- (id) processCharacter: (unichar) aCharacter;

/**	A new instance of the escape-sequence filter handler.
	\retval		nil		because this class is abstract.
*/
- (CharacterLineFilter *) escapeLineFilter;
/** A new instance of the alt-sequence filter handler.
	\retval		nil		because this class is abstract.
*/
- (CharacterLineFilter *) altCharLineFilter;
- (CharacterLineFilter *) ctrlCharLineFilter;
@end
