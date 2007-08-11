//
//  EscapeLineFilter.m
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

#import "EscapeLineFilter.h"
#import "TextStorageTerminal.h"
#import "ANSIDefaultLineFilter.h"
#import "ANSICharLineFilter.h"
#import "ControlCharLineFilter.h"
#import "Debug.h"
@implementation ControlCharLineFilter

- (id) initWithFallback: (id) prevFilter terminal: (id) terminal
{
	[super initWithFallback: prevFilter terminal: terminal];
	
	return self;
}

- (id) processCharacter: (unichar) character
{
    DEBUG("processCharacter: %C\n", character);
    if (character == 0x2022)
		return self;
    
    if (character < 0x60 && character > 0x40)
        [terminalDevice acceptCharacter: character - 0x40];
    else if (character < 0x7B && character > 0x60)
        [terminalDevice acceptCharacter: character - 0x60];
	return [self releaseToFallback];
}

@end
