//
//  PTYTask.m
//  Crescat
//
//  Created by Fritz Anderson on Wed Sep 17 2003.
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

#import "SubProcess.h"
#import <unistd.h>
#import <util.h>
#import <termios.h>
#import <sys/ttydefaults.h>

#define READ_BUFFER_SIZE	160
#define HOLDING_CAPACITY	(4 * 1024L)

static cc_t	ttydefchars[NCCS] = {
	CEOF,	CEOL,	CEOL,	CERASE, CWERASE, CKILL, CREPRINT,
	_POSIX_VDISABLE, CINTR,	CQUIT,	CSUSP,	CDSUSP,	CSTART,	CSTOP,	CLNEXT,
	CDISCARD, CMIN,	CTIME,  CSTATUS, _POSIX_VDISABLE
};

@implementation SubProcess


- (id) initWithPath: (NSString *) aPath
{
	processID = -1;
	executablePath = [aPath copy];
	
	winsize.ws_row = 24;
	winsize.ws_col = 80;
	winsize.ws_xpixel = 0;
	winsize.ws_ypixel = 0;
	stalled = NO;
	
	dataRead = [[NSMutableData alloc] initWithCapacity: HOLDING_CAPACITY];
	incomingData = [[NSLock alloc] init];
	
	return self;
}

- (NSString *) executablePath { return executablePath; }

- (void) setExecutablePath: (NSString *) newPath
{
	if (processID != 0)
		[NSException raise: NSInternalInconsistencyException format: @"Can't change executable of launched %@", [self class]];
	
	if (newPath != executablePath) {
		[executablePath release];
		executablePath = [newPath copy];
	}
}

- (NSArray *) arguments { return arguments; }

- (void) setArguments: (NSArray *) newArguments
{
	if (processID != 0)
		[NSException raise: NSInternalInconsistencyException format: @"Can't change arguments of launched %@", [self class]];
	
	if (arguments != newArguments) {
		[arguments release];
		arguments = [newArguments copy];
	}
}

- (NSDictionary *) environment { return environment; }

- (void) setEnvironment: (NSDictionary *) newEnvironment
{
	if (processID != 0)
		[NSException raise: NSInternalInconsistencyException format: @"Can't change environment of launched %@", [self class]];
	
	if (environment != newEnvironment) {
		[environment release];
		environment = [newEnvironment copy];
	}
}

- (void) readThread: (id) param
{
	NSAutoreleasePool *		pool = [[NSAutoreleasePool alloc] init];
	unsigned char			buffer[READ_BUFFER_SIZE];
	int						total;
	
	do {
		total = read(masterFD, buffer, sizeof(buffer));
		if (total > 0) {
			[incomingData lock];
			[dataRead appendBytes: buffer length: total];
			if ([dataRead length] > (HOLDING_CAPACITY/2))
				[self stall];
			[incomingData unlock];
			if (delegate)
				[delegate performSelectorOnMainThread: @selector(dataArrivedFromPty:) withObject: self waitUntilDone: NO];
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	} while (total > 0);
	
	if (delegate) {
		[delegate performSelectorOnMainThread: @selector(ptyTaskCompleted:) withObject: self waitUntilDone: NO];
		processID = -1;
	}
	
	[pool release];
}

- (id) delegate { return delegate; }

- (void) setDelegate: (id) newDelegate
{
	if (newDelegate != delegate) {
		[delegate release];
		delegate = [newDelegate retain];
	}
}

- (void) launchTask
{
	struct termios  term;
		
	memcpy(term.c_cc, ttydefchars, sizeof(ttydefchars));

	term.c_iflag = TTYDEF_IFLAG;	/* input flags */
	term.c_oflag = TTYDEF_OFLAG;	/* output flags */
	term.c_cflag = TTYDEF_CFLAG | CLOCAL;	/* control flags */
	term.c_lflag = (ECHO | ISIG | IEXTEN | ECHOE|ECHOKE|ECHOCTL);	/* local flags */
    term.c_cc[VLNEXT] = 0xff;
    term.c_cc[VDISCARD] = 0xff;
	term.c_ispeed = B38400;	/* input speed */
	term.c_ospeed = B38400;	/* output speed */
	
	
	processID = forkpty(&masterFD, NULL, NULL, &winsize);
	if (processID > 0) {
		//  Parent process, success
		masterHandle = [[NSFileHandle alloc] initWithFileDescriptor: masterFD
													 closeOnDealloc: YES];
		[NSThread detachNewThreadSelector: @selector(readThread:) toTarget: self withObject: nil];
	}
	else if (processID < 0) {
		//  Parent process, failure
		[NSException raise: NSObjectInaccessibleException
							 format: @"Could not fork pty."];
	}
	else {
		//  Child process
		char **			argv = (char **) malloc(sizeof(char *) * (1 + arguments? [arguments count]: 0));
		char **			envp = (char **) malloc(sizeof(char *) * (1 + environment? [environment count]: 0));
		int				i = 0;
		NSEnumerator *	iter;
		NSString *		curr;
		const char *	source;
		
		if (arguments) {
			iter = [arguments objectEnumerator];
			i = 0;
			while ((curr = [iter nextObject])) {
				source = [curr UTF8String];
				argv[i] = malloc(strlen(source) + 1);
				strcpy(argv[i], source);
				i++;
			}			
		}
		argv[i] = NULL;
		
		if (environment) {
			i = 0;
			iter = [environment keyEnumerator];
			while ((curr = [iter nextObject])) {
				source = [[NSString stringWithFormat: @"%@=%@", curr, [environment objectForKey: curr]] UTF8String];
				envp[i] = malloc(strlen(source) + 1);
				strcpy(envp[i], source);
				i++;
			}
		}
		envp[i] = NULL;
		
		execve([executablePath fileSystemRepresentation], argv, envp);
	}
}

- (void) sendTaskSignal: (int) signal
{
	if (processID == -1)
		[NSException raise: NSInternalInconsistencyException format: @"Can't signal: %@ hasn't been launched yet", self];
	
	kill(processID, signal);
}

- (int) processID { return processID; }

- (int) masterDescriptor { return masterFD; }

- (NSFileHandle *) master { return masterHandle; }

- (void) forwardInvocation: (NSInvocation *) anInvocation
{
	if ([masterHandle respondsToSelector: [anInvocation selector]])
		[anInvocation invokeWithTarget: masterHandle];
	else
		[self doesNotRecognizeSelector: [anInvocation selector]];
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL) aSelector
{
	if ([masterHandle respondsToSelector: aSelector])
		return [masterHandle methodSignatureForSelector: aSelector];
	else 
		return [super methodSignatureForSelector: aSelector];
}

@end

@implementation SubProcess (terminalTasks)

- (void) rows: (int *) rows columns: (int *) columns
{
	if (processID != -1)
		ioctl(masterFD, TIOCGWINSZ, &winsize);
	*rows = winsize.ws_row;
	*columns = winsize.ws_col;
}

- (void) setRows: (int) rows columns: (int) columns
{
	winsize.ws_row = rows;
	winsize.ws_col = columns;
	if (processID != -1)
		ioctl(masterFD, TIOCSWINSZ, &winsize);
}

- (void) stall
{
	if (processID == -1)
		[NSException raise: NSInternalInconsistencyException format: @"Can't stall: %@ hasn't been launched yet", self];
	if (! stalled) {
		ioctl(masterFD, TIOCSTOP, NULL);
		stalled = YES;
	}
}

- (void) unstall
{
	if (processID == -1)
		[NSException raise: NSInternalInconsistencyException format: @"Can't unstall: %@ hasn't been launched yet", self];
	
	if (stalled) {
		ioctl(masterFD, TIOCSTART, NULL);
		stalled = NO;
	}
}


@end

@implementation SubProcess (streamTasks)

- (void) writeData: (NSData *) someData
{
	if (processID == -1)
		[NSException raise: NSInternalInconsistencyException format: @"Can't write: %@ hasn't been launched yet", self];

	write(masterFD, [someData bytes], [someData length]);
//	NSLog(@"Write of %d bytes, result = %d", [someData length], result);
}

- (NSData *) availableData
{
	[incomingData lock];
	NSData *		retval = [dataRead autorelease];
	dataRead = [[NSMutableData alloc] initWithCapacity: HOLDING_CAPACITY];
	[self unstall];
	[incomingData unlock];
	return retval;
}

@end

