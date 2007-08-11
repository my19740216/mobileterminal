//
//  XTermEscapeLineFilter.m
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

#import "XTermEscapeLineFilter.h"
#import "XTermAltCharLineFilter.h"
#import "TextStorageTerminal.h"

enum {
	elfInitial,
	elfBracketNoParams,
	elfArrowKey,
	elfBang,
	elfQuery,
	elfEnable
};

@implementation XTermEscapeLineFilter

- (id) initWithFallback: (id) prevFilter terminal: (id) terminal
{
	[super initWithFallback: prevFilter terminal: terminal];
	state = elfInitial;
	paramCount = 0;
	ignore = NO;
	
	return self;
}

- (id) acceptCharArrow: (unsigned char) character
{
	switch (character) {
		case 'A':
			[terminalDevice cursorUp];
			break;
		case 'B':
			[terminalDevice cursorDown];
			break;
		case 'C':
			[terminalDevice cursorRight];
			break;
		case 'D':
			[terminalDevice cursorLeft];
			break;
	}
	
	return [self releaseToFallback];
}


- (id) acceptCharInitial: (unsigned char) character
{
	switch (character) {
		case 'c':
			[terminalDevice resetAll: YES];
			return [self resetToDefault];
		case '[':
			state = elfBracketNoParams;
			return self;
		case 'O':
			state = elfArrowKey;
			return self;
		case 'H':
			[terminalDevice setTabStop];
			return [self releaseToFallback];
		case 'M':
			[terminalDevice scrollDown];
			return [self releaseToFallback];
		case '>':
		case '=':
			//  These are at the end of rmkx and smkx.
			return [self releaseToFallback];
		case '(':
		case ')':
			state = elfEnable;
			charsetSelector = character;
			return self;
		case '7':
			[terminalDevice saveCursorPosition];
			return [self releaseToFallback];
		case '8':
			[terminalDevice restoreCursorPosition];
			return [self releaseToFallback];
			
	}
	
	return self;
}

- (id) acceptCharBang: (unsigned char) character
{
	if (character == 'p')
		NSLog(@"Some sort of XTerm initialization");
	return [self releaseToFallback];
}

- (id) acceptCharQuery: (unsigned char) character
{
	switch (character) {
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			if (paramCount == 0) {
				paramCount = 1;
				params[0] = -1;
			}
			if (params[paramCount-1] == -1)
				params[paramCount-1] = character - '0';
			else 
				params[paramCount-1] = (params[paramCount-1] * 10) + character - '0';
			return self;
		case '-':
		case ',':
		case ';':
			params[paramCount++] = -1;
			if (paramCount > 16) {
				paramCount = 16;
			}
				return self;
		case 'l':
			switch (params[0]) {
				case 1:
					NSLog(@"clear keypad transmit");
					break;
				case 3:
				case 4:
					break;
				case 5:
					[terminalDevice invertScreen: NO];
					break;
				case 7:
					[terminalDevice setWrapMode: NO];
					break;
				case 25:
					[terminalDevice setCursorVisible: NO];
					break;
				case 1049:
					//  rmcup
					NSLog(@"rmcup");
					break;
			}
			return [self releaseToFallback];
		case 'h':
			switch (params[0]) {
				case 1:
					NSLog(@"set keypad transmit");
					break;
				case 3:
				case 4:
					break;
				case 5:
					[terminalDevice invertScreen: YES];
					break;
				case 7:
					[terminalDevice setWrapMode: YES];
					break;
				case 25:
					[terminalDevice setCursorVisible: YES];
					break;
				case 1049:
					//  smcup
					NSLog(@"smcup");
					break;
			}
			return [self releaseToFallback];
		default:
			return [self releaseToFallback];
	}
}

- (id) dispatchBracket: (unsigned char) character
{
	BOOL		wantsDefaultFilter = NO;
	
	switch (character) {
		case 'A':
			[terminalDevice cursorUp: (paramCount == 0)? 1: params[0]];
			break;
		case 'B':
			[terminalDevice cursorDown: (paramCount == 0)? 1: params[0]];
			break;
		case 'C':
			[terminalDevice cursorRight: (paramCount == 0)? 1: params[0]];
			break;
		case 'D':
			[terminalDevice cursorLeft: (paramCount == 0)? 1: params[0]];
			break;
		case 'G':
			[terminalDevice cursorToColumn: (paramCount == 0)? 0: params[0]-1];
			break;
		case 'H':
			if (paramCount < 2)
				[terminalDevice homeCursor];
			else
				[terminalDevice moveToRow: params[0]-1 column: params[1]-1];
			break;
		case 'J':
			if (params[0] == 0)
				[terminalDevice eraseToEndOfScreen];
			else if (params[0] == 1)
				[terminalDevice eraseToStartOfScreen];
			else
				[terminalDevice eraseScreen];
			break;
		case 'K':
			switch (params[0]) {
				case 0:
					[terminalDevice eraseToEndOfLine];
					break;
				case 1:
					[terminalDevice eraseToStartOfLine];
					break;
				case 2:
					[terminalDevice eraseLine];
					break;
			}
			break;
		case 'L':
			[terminalDevice insertLines: (paramCount == 0)? 1: params[0]];
			break;
		case 'M':
			[terminalDevice deleteLines: (paramCount == 0)? 1: params[0]];
			break;
		case 'P':
			[terminalDevice deleteCharacters: (paramCount == 0)? 1: params[0]];
			break;
		case 'X':
			[terminalDevice eraseCharacters: (paramCount == 0)? 1: params[0]];
			break;
		case 'Z':
			[terminalDevice backTab];
			break;
		case '@':
			[terminalDevice insertCharacters: (paramCount == 0)? 1: params[0]];
			break;
		case 'c':
			[terminalDevice reportDeviceCode];
			break;
		case 'd':
			[terminalDevice cursorToLine: (paramCount == 0)? 0: params[0]-1];
			break;
		case 'g':
			if (params[0] == 3) {
				[terminalDevice clearTabStops];
			}
			else
				[terminalDevice clearOneTabStop];
			break;
		case 'h':
			if (params[0] == 4)
				[terminalDevice setInsertMode: YES];
			else if (params[0] == 7)
				[terminalDevice setWrapMode: YES];
			break;
		case 'i':
			if (paramCount == 0)
			;//	[terminalDevice printScreen];
			else switch (params[0]) {
				case 1:
			//		[terminalDevice printLine];
					break;
				case 5:
			//		[terminalDevice startPrintLog];
					break;
				case 4:
			//		[terminalDevice endPrintLog];
					break;
			}
				break;
			
		case 'l':
			if (params[0] == 4)
				[terminalDevice setInsertMode: NO];
			else if (params[0] == 7)
				[terminalDevice setWrapMode: NO];
				break;
		case 'm': 
			if (paramCount == 0) {
				[terminalDevice resetCurrentAttributes];
				wantsDefaultFilter = YES;
			}
			else {			
				int		i;
				for (i = 0; i < paramCount; i++) {
					switch (params[i]) {
						case 0:
							[terminalDevice resetCurrentAttributes];
							wantsDefaultFilter = YES;
							break;
						case 1:
							[terminalDevice startBold];
							break;
						case 4:
							[terminalDevice startUnderline];
							break;
						case 5:
							[terminalDevice startBlink];
							break;
						case 7:
							[terminalDevice startInverse];
							break;
						case 8:
							[terminalDevice startInvisible];
							break;
								
						case 21:
							[terminalDevice endBold];
							break;
						case 24:
							[terminalDevice endUnderline];
							break;
						case 25:
							[terminalDevice endBlink];
							break;
						case 27:
							[terminalDevice endInverse];
							break;
						case 28:
							[terminalDevice endInvisible];
							break;
						case 30:		//  Black
							[terminalDevice setForeground: tcBlack];
							break;
						case 31:		//  Red
							[terminalDevice setForeground: tcRed];
							break;
						case 32:		//  Green
							[terminalDevice setForeground: tcGreen];
							break;
						case 33:		//  Yellow
							[terminalDevice setForeground: tcYellow];
							break;
						case 34:		//  Blue
							[terminalDevice setForeground: tcBlue];
							break;
						case 35:		//  Magenta
							[terminalDevice setForeground: tcMagenta];
							break;
						case 36:		//	Cyan
							[terminalDevice setForeground: tcCyan];
							break;
						case 37:		//  White
							[terminalDevice setForeground: tcWhite];
							break;
						case 39:
							[terminalDevice setPlainForeground];
							break;
						case 40:		//  Black
							[terminalDevice setBackground: tcBlack];
							break;
						case 41:		//  Red
							[terminalDevice setBackground: tcRed];
							break;
						case 42:		//  Green
							[terminalDevice setBackground: tcGreen];
							break;
						case 43:		//  Yellow
							[terminalDevice setBackground: tcYellow];
							break;
						case 44:		//  Blue
							[terminalDevice setBackground: tcBlue];
							break;
						case 45:		//  Magenta
							[terminalDevice setBackground: tcMagenta];
							break;
						case 46:		//	Cyan
							[terminalDevice setBackground: tcCyan];
							break;
						case 47:		//  White
							[terminalDevice setBackground: tcWhite];
							break;
						case 49:
							[terminalDevice setPlainBackground];
							break;
					}				
				}
			}
			break;
			
		case 'n':
			if (params[0] == 5)
				[terminalDevice reportDeviceStatus];
			else if (params[0] == 6)
				[terminalDevice reportCursorPosition];
				break;
		case 'r':
			if (paramCount == 0)
				[terminalDevice unsetScrollArea];
			else
				[terminalDevice setScrollAreaTop: params[0]-1 bottom: params[1]];
			break;
	}
	
	if (wantsDefaultFilter)
		return [self resetToDefault];
	else
		return [self releaseToFallback];
}

- (id) acceptCharBracket: (unsigned char) character
{
	switch (character) {
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			if (paramCount == 0) {
				paramCount = 1;
				params[0] = -1;
			}
			if (params[paramCount-1] == -1)
				params[paramCount-1] = character - '0';
			else 
				params[paramCount-1] = (params[paramCount-1] * 10) + character - '0';
			return self;
		case '?':
			state = elfQuery;
			return self;
		case '!':
			state = elfBang;
			return self;
		case '-':
		case ',':
		case ';':
			params[paramCount++] = -1;
			if (paramCount > 16)
				paramCount = 16;
				return self;
		default:
			if (ignore)
				return [self releaseToFallback];
			else
				return [self dispatchBracket: character];
	}
}

- (id) acceptCharEnable: (unsigned char) character
{
	if (character == 'B')
		[terminalDevice enableAlternateCharacters];
	return [self releaseToFallback];
}



- (id) processCharacter: (unichar) character
{
	id			nextHandler = self;
	
	if (character == '\033') {
		//  An error condition, in which somehow we got out of
		//  synch, and a new escape code arrived. Take it from the
		//  top of the new code.
		state = elfInitial;
		return self;
	}
	
	switch (state) {
		case elfInitial:
			nextHandler = [self acceptCharInitial: character];
			break;
		case elfBracketNoParams:
			nextHandler = [self acceptCharBracket: character];
			break;
		case elfQuery:
			nextHandler = [self acceptCharQuery: character];
			break;
		case elfBang:
			nextHandler = [self acceptCharBang: character];
			break;
		case elfArrowKey:
			nextHandler = [self acceptCharArrow: character];
			break;
		case elfEnable:
			nextHandler = [self acceptCharEnable: character];
			break;
	}
	
	return nextHandler;
}


@end
