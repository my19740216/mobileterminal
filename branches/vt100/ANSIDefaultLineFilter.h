//
//  ANSIDefaultLineFilter.h
//  Crescat
//
//  Created by Fritz Anderson on Sun Nov 09 2003.
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

#import "DefaultLineFilter.h"

/** \ingroup LineFilters
	The concrete default line filter for ANSI terminals.
	This class differs from the abstract DefaultLineFilter only in that it defers to EscapeLineFilter when an escape arrives, and to ANSICharLineFilter (note the deceptive name) when an 0xE arrives.
*/

@interface ANSIDefaultLineFilter : DefaultLineFilter {

}

@end
