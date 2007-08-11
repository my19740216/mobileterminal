//
//  XTermAltCharLineFilter.m
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

#import "XTermAltCharLineFilter.h"
#import "XTermEscapeLineFilter.h"
#import "XTermDefaultLineFilter.h"
#import "TextStorageTerminal.h"

typedef struct {
	unsigned char   vt100;
	unichar			graphic;
}   GraphicCharPair;

static GraphicCharPair  sGraphicCharPairs[] = {
	{'`', 0x25C7 },
	{'a', 'S' },
	{'f', 0x00b0 },
	{'g', 0x00b1 },
	{'i', 0x2302 },
	{'j', '3' },
	{'k', '9' },
	{'l', '7' },
	{'m', '1' },
	{'n', '5' },
	{'o', '=' },
	{'p', 0x25AC },
	{'q', '-' },
	{'r', 0x23AF },
	{'s', '_' },
	{'t', '4' },
	{'u', '6' },
	{'v', '2' },
	{'w', '8' },
	{'x', '0' },
	{'y', 0x2264 },
	{'z', 0x2265 },
	{'{', 0x03c0 },
	{'|', 0x2260 },
	{'}', 0x00A3 },
	{'~', 0x2022 },
	
	{ 0, 0 }
};

@implementation XTermAltCharLineFilter

#define BEL		7
#define CR		13
#define LF		10
#define TAB		9
#define BS		8
#define ESC		27
#define ALT		14
#define EX_ALT  15

- (id) processCharacter: (unichar) aCharacter
{
	id		nextFilter = self;
	
	//  aCharacter &= 0x0FF;
	
	switch (aCharacter) {
		case BEL:
			[terminalDevice soundBell];
			break;
		case BS:
			[terminalDevice cursorLeft];
			break;
		case CR:
			[terminalDevice carriageReturn];
			break;
		case LF:
			[terminalDevice lineFeed];
			break;
		case TAB:
			[terminalDevice horizontalTab];
			break;
		case ESC:
			nextFilter = [[XTermEscapeLineFilter alloc] initWithFallback: self terminal: terminalDevice];
			break;
		case EX_ALT:
			// [terminalDevice endAlternate];
			nextFilter = [self releaseToFallback];
			break;
		default: {
			GraphicCharPair *   cursor = sGraphicCharPairs;
			for (cursor = sGraphicCharPairs; cursor->vt100; cursor++) {
				if (cursor->vt100 == aCharacter) {
					[terminalDevice startAlternate];
					[terminalDevice acceptCharacter: cursor->graphic];
					[terminalDevice endAlternate];
					break;
				}				
			}
			if (!cursor->vt100 && aCharacter >= ' ')
				[terminalDevice acceptCharacter: aCharacter];			
		}
			break;
	}
	
	return nextFilter;
}

@end
