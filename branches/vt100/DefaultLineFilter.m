//
//  DefaultLineFilter.m
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

#import "DefaultLineFilter.h"
#import "EscapeLineFilter.h"
#import "ANSICharLineFilter.h"
#import "TextStorageTerminal.h"
#import "Debug.h"

#define BEL		7
#define BS		8
#define CR		13
#define LF		10
#define TAB		9
#define ESC		27
#define ALT		14
#define EX_ALT  15
#define CTRL     0x2022

@implementation DefaultLineFilter


- (id) initWithTerminal: terminal
{
	[super initWithFallback: nil terminal: terminal];
	return self;
}

- (CharacterLineFilter *) escapeLineFilter { return nil; }
- (CharacterLineFilter *) altCharLineFilter { return nil; }
- (CharacterLineFilter *) ctrlCharLineFilter { return nil; }

- (id) processCharacter: (unichar) aCharacter
{
	id		nextFilter = self;
DEBUG("processCharacter for DefaultLineFilter: 0x%04X\n", aCharacter);
    if (aCharacter == CTRL)
        nextFilter = [self ctrlCharLineFilter];
    else {
	aCharacter = aCharacter & 0x7f;
	
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
			nextFilter = [self escapeLineFilter];
			break;
		case ALT:
			[terminalDevice startAlternate];
			nextFilter = [self altCharLineFilter];
			break;
		default:
			if (aCharacter >= ' ')
				[terminalDevice acceptCharacter: aCharacter];
	}
    }
	return nextFilter;
}

//  The CharacterLineFilter processData: will work fine.
//  The hope is that this specialization will optimize the common case of strings of printable characters.

- (id) processData: (NSData *) someData
{
	NSRange					fullRange = NSMakeRange(0, [someData length]);
	NSRange					plainRange = NSMakeRange(0, 0);
	id						current = self;
    const unsigned char *data = [someData bytes];
	
	while (NSMaxRange(plainRange) < NSMaxRange(fullRange)) {
		//  Make plainRange extend to the length of printable characters
		while (NSMaxRange(plainRange) < NSMaxRange(fullRange) && data[NSMaxRange(plainRange)] >= ' ')
			plainRange.length++;
		
		//  Pass the run of printable characters
		if (plainRange.length)
			[terminalDevice acceptASCII: data + plainRange.location length: plainRange.length];
		
		//  zero out plainRange
		plainRange.location = NSMaxRange(plainRange);
		plainRange.length = 0;
		
		//  Slide plainRange through other filters and nonprintables.
		while (NSMaxRange(plainRange) < NSMaxRange(fullRange)) {
			current = [current processCharacter: data[plainRange.location++]];
			if (current == self && data[NSMaxRange(plainRange)] >= ' ')
				break;
		}
	}
	
	return current;
}


@end
