//
//  CharacterLineFilter.h
//  Crescat
//
//  Created by Fritz Anderson on Mon Sep 08 2003.
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

#import <Foundation/Foundation.h>
/**
    \defgroup	LineFilters	Character input filters.
    CharacterLineFilter is an abstract base class for filters that turn character sequences into terminal commands. The controller that receives data from the host (MyDocument in Crescat) passes the incoming data to the current filter object (a CharacterLineFilter subclass) which passes it to the terminal model (TextStorageTerminal) either as characters to be rendered, or as commands.
*/


/**
	\ingroup LineFilters
	Abstract base class for terminal state machines.
    CharacterLineFilter is an abstract base class for filters that turn character sequences into terminal commands. The controller that receives data from the host (MyDocument in Crescat) passes the incoming data to the current filter object (a CharacterLineFilter subclass) which passes it to the terminal model (TextStorageTerminal) either as characters to be rendered, or as commands.
 
	CharacterLineFilters stack; there is a default filter that represents the responses to characters the terminal makes when in its initial state, but a command from the host (an escape character is the common example) may throw the terminal into a state in which characters have a different interpretation. For each such state, stack up a corresponding subclass of CharacterLineFilter, with the current filter as the fallback. Handling the transient state causes the filter to be popped off and released (releaseToFallback). Some inputs pop all filters off down to the default filter (releaseToDefault).
*/
@interface CharacterLineFilter : NSObject
{
	CharacterLineFilter *   fallback;
	id						terminalDevice;
}

/**	Initialize and stack over the given CharacterLineFilter.
	This is a convenience initializer, which uses the same terminal object as the fallback filter.
	\param[in]	inFallback	the top of the line-filter stack. This is the filter that will become current when the receiver is released.
	\retval	self		if initialization succeeded.
	\retval	inFallback	if inFallback was of the same class as self.
*/
- (id) initWithFallback: (id) inFallback;
/**	Designated initializer: Stack over the given CharacterLineFilter, using the given terminal.
	Keep the result of this initializer as the top of the line-filter stack, and feed data from the host to it (#processCharacter: / #processData:). Data will be translated into events, and corresponding messages will be sent to the terminal.
	
	It is thought to be an error to enqueue the same filter twice in a row. If the receiver is of the same class as the inFallback filter, the receiver will be released and inFallback will be returned (thus ensuring that the returned value is always the proper top-of-stack). This stack-folding is noted in the console log.
	\param[in]	inFallback	the top of the line-filter stack. This is the filter that will become current when the receiver is released.
	\retval self		if initialization succeeds.
	\retval	inFallback	if inFallback was of the same class as self.
*/
- (id) initWithFallback: (id) inFallback terminal: (id) terminal;

/**	Process one character of input.
	Given one character from the host, respond by passing it to the terminal, changing the terminal state, or changing line filters. If the result involves a new line filter, this method allocates it and stacks it on top of the receiver. 
	
	The filter for the next character is returned, so always update the filter-stack variable with the result of this method.
	\param[in]	aCharacter	A character (expect ISO-Latin-1) from the host.
	\retval		self		If the next character is to be fed to this filter.
	\retval		CharacterLineFilter	A new filter, falling back to the receiver, if the character changes interpreter state.
*/
- (id) processCharacter: (unichar) aCharacter;
/**	Process many characters of input.
	This method iterates through the bytes of the given NSData, sending the first in a #processCharacter: message to the receiver, and the succeeding ones to whatever line filter is top. 

	The filter for the next character is returned, so always update the filter-stack variable with the result of this method.
	\param[in]	someData	NSData, characters (expect ISO-Latin-1) from the host.
	\retval		self		If the next character is to be fed to this filter.
	\retval		CharacterLineFilter	A new filter, falling back to the receiver, if the character changes interpreter state.
*/
- (id) processData: (NSData *) someData;

/**	Release the receiver and return the next filter on the stack.
	This method is sent by the filter itself when it reaches end-of-state. End-of-state means that the filter is spent, and must be released; and the previous top-of-stack filter becomes top-of-stack again.
	\retval		CharacterLineFilter	the fallback line filter, the handler for the next character.
*/
- (id) releaseToFallback;
/**	Release all filters down to the default; return default.
	Sends #releaseToFallback to self, and to the results, until the result is the root filter (#isRootFilter). A command, like a general reset, may terminate all character modes. This message takes all the character modes but the default off the handler stack and returns the default.
*/
- (id) resetToDefault;

/**	Getter for the target terminal device. */
- (id) terminalDevice;

@end
