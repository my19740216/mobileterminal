//
//  ANSICharLineFilter.h
//  Crescat
//
//  Created by Fritz Anderson on Sat Sep 13 2003.
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
	Concrete \em alternate line filter for ANSI terminals. 
	The class name is misleading.
*/
@interface ANSICharLineFilter : CharacterLineFilter {
}

/**	Process a character from the host and return the next filter. Most characters are matched against a table of alternate characters and translated into an internal representation that will have the proper appearance on-screen.
	\param[in]	nextCharacter	The character from the host.
	\retval	self	in most cases.
	\retval fallback if nextCharacter was 0xF.
	\retval EscapeLineFilter if nextCharacter was escape.
*/
- (id) processCharacter: (unichar) nextCharacter;

@end
