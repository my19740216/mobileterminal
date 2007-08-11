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

enum {
	elfInitial,
	elfBracketNoParams,
	elfArrowKey,
	elfAwaitSoftReset,
	elfEnable
};

@implementation EscapeLineFilter

- (id) initWithFallback: (id) prevFilter terminal: (id) terminal
{
	[super initWithFallback: prevFilter terminal: terminal];
	state = elfInitial;
	paramCount = 0;
	ignore = NO;
	
	return self;
}

- (id) acceptCharInitial: (unsigned char) character
{
	switch (character) {
		case 'c':
			[terminalDevice resetAll: YES];
			return self;
		case '!':
			state = elfAwaitSoftReset;
			return self;
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
		case '(':
		case ')':
		case '*':
		case '+':
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
		case 'I':
			[terminalDevice hardwareTab];
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
		case 'S':
			if (paramCount == 0) {
				[terminalDevice lineFeed];
			}
			else while (params[0]--) {
				[terminalDevice lineFeed];
			}
				break;
		case 'T':		//  reverse index
			[terminalDevice reverseIndex: (paramCount == 0)? 1: params[0]];
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
		case 'b':
			[terminalDevice repeatLastCharacter: params[1]];
			break;
		case 'c':
			[terminalDevice reportDeviceCode];
			break;
		case 'd':
			[terminalDevice cursorToLine: (paramCount == 0)? 0: params[0]-1];
			break;
		case 'g':
			if (params[0] == 2) {
				[terminalDevice clearTabStops];
			}
			else
				[terminalDevice clearOneTabStop];
			break;
		case 'h':
			if (params[0] == 4)
				[terminalDevice setInsertMode: YES];
			break;
		case 'i':
			if (paramCount == 0)
				;//[terminalDevice printScreen];
			else switch (params[0]) {
				case 1:
					//[terminalDevice printLine];
					break;
				case 5:
					//[terminalDevice startPrintLog];
					break;
				case 4:
					//[terminalDevice endPrintLog];
					break;
			}
				break;
			
		case 'l':
			if (params[0] == 4)
				[terminalDevice setInsertMode: NO];
			break;
		case 'm': 
			if (paramCount == 0) {
				[terminalDevice resetCurrentAttributes];
			}
			else {			
			int		i;
			for (i = 0; i < paramCount; i++) {
				switch (params[i]) {
					case 0:
						[terminalDevice resetCurrentAttributes];
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
						
						//  ANSI start- and end-alt character codes
						//  The reason I'm pulling the overall start- and endAlternate is that I'm doubling up the semantics of some ASCII characters in the alternate mode.
					case 11:
						//  [terminalDevice startAlternate];
						return [[ANSICharLineFilter alloc] initWithFallback: [self releaseToFallback]];
					case 10:
						//  [terminalDevice endAlternate];
						wantsDefaultFilter = YES;
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
				[terminalDevice setScrollAreaTop: params[0]-1 bottom: params[1]-1];
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
			ignore = YES;
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

- (id) acceptCharEnable: (unsigned char) character
{
	if (character == 'B')
		[terminalDevice enableAlternateCharacters];
	return [self releaseToFallback];
}

- (id) acceptSoftReset: (unsigned char) character
{
	if (character == 'p')
		[terminalDevice resetAll: NO];
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
		case elfArrowKey:
			nextHandler = [self acceptCharArrow: character];
			break;
		case elfAwaitSoftReset:
			nextHandler = [self acceptSoftReset: character];
			break;
		case elfEnable:
			nextHandler = [self acceptCharEnable: character];
			break;
	}
	
	return nextHandler;
}

@end

/*
 FIX ME -- 
 Query Device Code       <ESC>[c
	 Requests a Report Device Code response from the device.
	 
	 
Report Device Code      <ESC>[{code}0c
	Generated by the device in response to Query Device Code request.
	
	
Query Device Status     <ESC>[5n
	Requests a Report Device Status response from the device.
	
	
Report Device OK        <ESC>[0n
	Generated by the device in response to a Query Device Status request; indicates that device is functioning correctly.
	
	
Report Device Failure   <ESC>[3n
	Generated by the device in response to a Query Device Status request; indicates that device is functioning improperly.
	
Query Cursor Position   <ESC>[6n
	Requests a Report Cursor Position response from the device.
	
Report Cursor Position  <ESC>[{ROW};{COLUMN}R
	Generated by the device in response to a Query Cursor Position request; reports current cursor position.

 FIX ME -- the following can't be done by accumulating bits into an int32:
 
 Set Attribute Mode      <ESC>[{attr1};...;{attrn}m
	 Sets multiple display attribute settings. The following lists standard attributes:
	 0       Reset all attributes
	 1       Bright
	 2       Dim
	 4       Underscore      
	 5       Blink
	 7       Reverse
	 8       Hidden
	 
	 Foreground Colors
	 30      Black
	 31      Red
	 32      Green
	 33      Yellow
	 34      Blue
	 35      Magenta
	 36      Cyan
	 37      White
	 
	 Background Colors
	 40      Black
	 41      Red
	 42      Green
	 43      Yellow
	 44      Blue
	 45      Magenta
	 46      Cyan
	 47      White
	 
 
 */
