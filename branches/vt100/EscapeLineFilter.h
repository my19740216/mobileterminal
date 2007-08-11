//
//  EscapeLineFilter.h
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
	The escape-character line filter for ANSI terminals. Uses a simple state machine to accumulate parameters until the command is complete, then composes a message to the target terminal.
*/
@interface EscapeLineFilter : CharacterLineFilter {
	int				state;				///<	Processing state.
	int				params[16];			///<	Numeric parameters (up to 16).
	int				paramCount;			///<	Number of parameters.
	unsigned char	charsetSelector;	///<	Character-set selector (recognized but not used).
	BOOL			ignore;				///<	Whether to accept the rest of the command and ignore it.
}

/**	Designated initializer. Initializes the parameter count and state variable. */
- (id) initWithFallback: (id) prevFilter terminal: (id) terminal;
/**	Process a character from the host. In a new EscapeLineFilter (state == 0), this will be the first character after the escape; characters will change the state of the filter and be interpreted in light of the accumulated state.
	\param[in]	character	The character from the host.
	\retval		CharacterLineFilter	The handler for the next character from the host.
*/
- (id) processCharacter: (unichar) character;

@end
