//
//  ANSICharLineFilter.m
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

#import "ANSICharLineFilter.h"

#import "EscapeLineFilter.h"
#import "TextStorageTerminal.h"
#import "ANSIDefaultLineFilter.h"
#import "ControlCharLineFilter.h"

/**	Mapping between terminal codes and internal representations. */
typedef struct {
	unsigned char   vt100;		///<	Terminal code (from host)
	unichar			graphic;	///<	Internal representation (in text storage)
}   GraphicCharPair;

/**	Pair data characters with internal representations of special characters. Characters that are reliably of the same width as the rest of the Monaco font are mapped to their Unicode equivalents. Characters that TermLayoutManager must draw independently are mapped to ASCII characters; the presence of the alt-character text style cues the layout manager to render the graphical character. */
static GraphicCharPair  sGraphicCharPairs[] = {
#if 0
	{ '\234', 0x00A3 },	//  Pound sterling
	{ 25, 0x2193 },	//  Down arrow
	{ '\021', 0x2190 },	//  Left arrow
	{ '\020', 0x2192 },	//  Right arrow
	{ '\030', 0x2191 },	//  Up arrow
	{ '\260', 0x259A },	//  Board of squares FIX ME not very good
	{ '\376', 0x2022 },	//  Bullet
	{ '\261', 0x2593 },	//  Checkerboard (stipple)
	{ '\370', 0x00B0 },	//  Degree
	{ '\004', 0x25C7 },	//  Diamond
	{ '\362', 0x2265 },	//  >=
	{ '\343', 0x03c0 },	//  pi
	{ '\304', 0x2500 },	//  Horiz line
	{ '\305', 0x253C },	//  Crossover
	{ '\363', 0x2264 },	//  <=
	{ '\300', 0x2514 },	//  Lower left
	{ '\331', 0x2518 },	//  Lower right
	{ '\330', 0x2260 },	//  !=
	{ '\361', 0x00b1 },	//  +/-
	{ '~', 0x2581 },	//  "S1" 1/8 block
	{ '_', 0x2587 },	//  "S9" 7/8
	{ '\333', 0x2588 },	//  Full block
	{ '\302', 0x252C },	//  Top tee
	{ '\264', 0x2524 },	//  Right tee
	{ '\303', 0x251C },	//  Left tee
	{ '\301', 0x2534 },	//  Bottom tee
	{ '\332', 0x250C },	//  Upper left
	{ '\277', 0x2510 },	//  Upper right
	{ '\263', 0x2502 },	//  Vertical line
#else
	//  The Unicode equivalents have to be kept coordinated in the GSAttributedString category in GSTextStorageTerminal.m
	{ '\234', 0x00A3 },	//  Pound sterling
	{ 25, 0x2193 },	//  Down arrow
	{ '\021', 'L' },	//  Left arrow
	{ '\020', 'R' },	//  Right arrow
	{ '\030', 0x2191 },	//  Up arrow
	{ '\260', '%' },	//  Board of squares
	{ '\376', 0x2022 },	//  Bullet
	{ '\261', 'S' },	//  Checkerboard (stipple)
	{ '\370', 0x00B0 },	//  Degree
	{ '\004', 0x25C7 },	//  Diamond
	{ '\362', 0x2265 },	//  >=
	{ '\343', 0x03c0 },	//  pi
	{ '\304', '-' },	//  Horiz line
	{ '\305', '5' },	//  Crossover
	{ '\363', 0x2264 },	//  <=
	{ '\300', '1' },	//  Lower left
	{ '\331', '3' },	//  Lower right
	{ '\330', 0x2260 },	//  !=
	{ '\361', 0x00b1 },	//  +/-
	{ '~', '=' },	//  "S1" 1/8 block
	{ '_', '_' },	//  "S9" 7/8
	{ '\333', '#' },	//  Full block
	{ '\302', '8' },	//  Top tee
	{ '\264', '6' },	//  Right tee
	{ '\303', '4' },	//  Left tee
	{ '\301', '2' },	//  Bottom tee
	{ '\332', '7' },	//  Upper left
	{ '\277', '9' },	//  Upper right
	{ '\263', '0' },	//  Vertical line	
#endif	
	{ 0, 0 }
};

@implementation ANSICharLineFilter

#define BEL		7
#define CR		13
#define LF		10
#define TAB		9
#define BS		8
#define ESC		27
#define ALT		14
#define EX_ALT  15
#define CTRL    0x2022

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
			nextFilter = [[EscapeLineFilter alloc] initWithFallback: self terminal: terminalDevice];
			break;
        case CTRL:
            nextFilter = [[ControlCharLineFilter alloc] initWithFallback: self terminal: terminalDevice];
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
