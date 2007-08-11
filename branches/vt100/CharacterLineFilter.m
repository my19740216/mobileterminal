//
//  CharacterLineFilter.m
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

#import "CharacterLineFilter.h"
#import "DefaultLineFilter.h"
#include <stdio.h>

@implementation CharacterLineFilter

- (id) initWithFallback: (id) inFallback terminal: (id) terminal
{
//	NSAssert([inFallback class] != [self class], @"Shouldn't fall back to same class");
	if ([inFallback class] == [self class]) {
		NSLog(@"Offered same class as fallback. Merging...");
		[self release];
		return inFallback;
	}
	
	fallback = [inFallback retain];
	terminalDevice = terminal;
	return self;
}

- (id) initWithFallback: (id) another
{
	return [self initWithFallback: another terminal: [another terminalDevice]];
}

- (void) dealloc
{
	[fallback release];
	[super dealloc];
}

/**	Whether this is the default filter (no fallback below it). */
- (BOOL) isRootFilter
{
	return fallback == nil;
}

- (id) terminalDevice { return terminalDevice; }

- (id) releaseToFallback
{
	CharacterLineFilter *   retval = fallback;
	if (retval)
		[self release];
	else
		[NSException raise: NSInternalInconsistencyException format: @"%@ has no fallback and should not be released to fallback", self];
	
	return retval;
}

- (id) resetToDefault
{
	CharacterLineFilter *   curr = self;
	while (![curr isRootFilter]) {
		curr = [curr releaseToFallback];
	}
	return curr;
}

- (id) processCharacter: (unichar) aCharacter
{
	return self;
}

- (id) processData: (NSData *) someData
{
    id						current = self;
	unsigned				i, iLimit = [someData length];
    const unsigned char * data = [someData bytes];
	
	for (i = 0; i < iLimit; i++) {
		current = [current processCharacter: data[i]];
	}
	
    return current;
}

@end
