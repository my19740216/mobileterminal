//
//  PTYTask.h
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

/**
    \file
    Forking and I/O for pseudo-tty tasks.
    A PTYTask launches a BSD process in a pseudo-terminal session, and mediates the I/O between the child process and the process that spawned it. While PTYTask can be thought of as like an NSTask, it does not use NSTask to do its work. Its major difference from NSTask is that clients communicate with the child process through PTYTask itself, and not through ancillary NSFileHandles. PTYTask also provides for terminal-service signals to the pseudo-tty.
 
		The methods needed to configure a PTYTask and launch the subprocess are to be found in the main interface to the class.
 
		Terminal-service tasks, such as changing the size of the "screen" or stalling input, are covered in the terminalTasks category.
 
		Input and events are handled by a delegate object, which should implement the ptyTaskDelegate informal protocol. The streamTasks category covers the methods for getting bytes into and out of the subprocess.
 
		Also: PTYTask forwards all unrecognized methods to the NSFileHandle that services I/O to the task. 
*/


#import <Foundation/Foundation.h>
#import <sys/ioctl.h>

/**
        Configure and launch pseudo-terminal subprocesses.
    PTYTask forks a process in a pseudo-tty. The main interface provides for setting the path to the executable, setting the arguments and environment, setting a delegate to handle I/O and other events, and launching and singaling the process. 
 
	Terminal configuration and stalling are found in the terminalTasks category.
 
	I/O is handled through the streamTasks category and the ptyTaskDelegate informal protocol. PTYTask forwards all unrecognized methods to the NSFileHandle that services I/O to the task.
*/
@interface SubProcess : NSObject {
	NSString *			executablePath;	///<	Path to the process executable.
	NSArray *			arguments;		///<	List of arguments for the executable.
	NSDictionary *		environment;	///<	Dictionary of environment variables.
	NSFileHandle *		masterHandle;	///<	Handler for device descriptor for ptty; forwardInvocation target.
	int					masterFD;		///<	POSIX device descriptor for ptty.
	int					processID;		///<	PID for the ptty process.
	
	NSMutableData *		dataRead;		///<	Accumulator for incoming ptty data.
	NSLock *			incomingData;	///<	Coherence for dataRead between read loop and delegate.
	id					delegate;		///<	Handler for incoming data and end-of-session.
	
	struct winsize		winsize;		///<	Window-size struct for the terminal window.
	BOOL				stalled;		///<	Whether ptty output has been stalled.
}

/**
    Designated initializer.
    Initialize a newly-allocated PTYTask with the path to the task's executable. The input path is copied, and the terminal size is initialized to 24 rows of 80 columns.
	@param		aPath	NSString, the path to the file to be executed. This is in no wise checked.
    @retval     self; never returns nil.
*/
- (id) initWithPath: (NSString *) aPath;

/**
    Return the path to the file to execute.
    Returns the BSD path to the file that will be execve'd after a pseudo-tty process is forked.
    @retval     The path to the file to execute.
*/
- (NSString *) executablePath;
/**
    Set the file to be executed in the pseudo-tty.
    Copies the parameter and, once a pseudo-tty process is forked, the file system representation of the string is used as a path name to a file to be executed in the pseudo-tty. No sanity checking is done on the string, but an exception will be thrown if the task has already been launched.
	@param		newPath	An NSString, which should be the fully-qualified BSD path of the file to execute. This is not checked.
	@throw		NSInternalInconsistencyException
*/
- (void) setExecutablePath: (NSString *) newPath;

/**
    The list of arguments for the task.
    This is exactly the NSArray of argument strings as copied in the setArguments: call. Defaults to nil, in which case there will be no command-line arguments.
    @retval     An array of (it is hoped) NSStrings to be passed, in order, as arguments to the executable, not including the name of the executable. This may be nil if no arguments are specified.
*/
- (NSArray *) arguments;
/**
    Set the arguments to be passed to the task.
    The parameter should be an NSArray of NSStrings, being, in order, the command-line arguments the task is to receive at launch. Do not make provision for the name of the executable being the first entry; PTYTask takes care of that. Note that no interpretation is made of the parameters: Glob expressions and variables will be passed in literally, and a single string with a space in the middle of it is a single argument. The NSArray is copied, but its contents are not. Defaults to nil, signifying no command-line arguments. Raises an exception if attempted after launching the task.
	@param		newArguments	An NSArray of NSStrings specifying each command-line argument. The array will be copied, but the strings will not. The strings will be encoded as UTF-8 when passed as parameters.
	@throw		NSInternalInconsistencyException
*/
- (void) setArguments: (NSArray *) newArguments;

/**
    The execution environment for the task.
    If nil, no environment variables will be set for the pseudo-tty task. Otherwise, the returned value will be an NSDictionary whose string keys specify environment variables, and with NSString values for those variables. Nil by default. 
    @retval     A dictionary matching environment variables with values, or nil.
*/
- (NSDictionary *) environment;
/**
    Set environment variables for the task.
    The parameter is nil if there are to be no environment variables when the pseudo-tty task is launched. Otherwise, it is an NSDictionary associating variable names with string values. The environment dictionary will be shallow-copied (the dictionary and its keys will be copied, the values won't). Defaults to nil. Raises an exception if attempted after launching the task.
	@param		newEnvironment	An NSDictionary with string keys and values; this is not checked, but bad things will happen if it is not so. Nil is also permissible. All strings will be encoded as UTF-8 when used.
*/
- (void) setEnvironment: (NSDictionary *) newEnvironment;

/**
    Launch the pseudo-terminal task.
	Forks a process for a pseudo-terminal, then uses execve to launch the designated file in the tty, with the configured arguments and environment. The I/O streams will be captured and will be available directly through -masterDescriptor and the -master NSFileHandle, but normal practice will be to use streamTasks and ptyTaskDelegate methods to handle I/O asynchronously.
 
	If the fork succeeds, the PTYTask will spawn a thread in the parent process that blocks on a read(2) of the pseudo-tty's output. Anything coming out of the tty will be reported to the PTYTask's delegate through the ptyTaskDelegate informal protocol.
 
	The task can usually be killed by sending -closeFile to the PTYTask. This will be forwarded to the NSFileHandle for the process I/O, closing the pseudo-tty. The read-stream thread will awaken with an error on the read, notify the delegate that the task closed, and reset the process ID to -1.
 
	An exception will be raised if the fork could not be done.
	@throw		NSObjectInaccessibleException
*/
- (void) launchTask;
/**
    Use kill(2) to signal the task.
    Given a signal ID, sends that signal to the pseudo-tty task using the kill(2) system call. Attempting this when the task is not running will raise an exception. 
	@param		signal	A small integer for the signal to raise in the task. Not checked.
	@throw		NSInternalInconsistencyException
*/
- (void) sendTaskSignal: (int) signal;

/**
    PID of the pseudo-tty process.
    This is the process ID returned by forkpty(3) when the pseudo-terminal is created. The value is set to -1 at initialization and when the task is closed. When PTYTask checks for whether the task is running before permitting an operation like -sendTaskSignal:, it compares -processID to -1.
    @retval     The process ID of the pseudo-tty process, or -1 if none.
*/
- (int) processID;
/**
    Device descriptor for the pseudo-tty.
    This is the descriptor through which all input, output, and control are done for the pseudo-tty. In general, clients should not need to use this descriptor, as higher-level methods exist for almost anything that can be done with the ptty. In particular, launching the PTYTask starts a thread that keeps a read(2) continually waiting to report incoming data to the delegate.
    @retval     int	The POSIX device descriptor for the pseudo-tty.
*/
- (int) masterDescriptor;

/**	NSFileHandle object for the pseudo-tty.
	As soon as a device descriptor is available for the pseudo-tty, an NSFileDescriptor object is initialized as a convenience in communicating with it. PTYTask itself does not use this object, but unrecognized messages to a PTYTask are forwarded to the NSFileDescriptor object.
	\retval	NSFileHandle	the Cocoa object for communicating over the ptty fd.
*/
- (NSFileHandle *) master;

/**	Getter for the task delegate. Returns the actual delegate pointer. */
- (id) delegate;
/**	Setter for the task delegate.
	The delegate object is retained. The object is expected to adhere to the ptyTaskDelegate informal protocol, but this is not checked.
	\param	newDelegate		the object to be made delegate.
*/
- (void) setDelegate: (id) newDelegate;

@end

/**
    Terminal-management methods for PTYTask
    This category encompasses methods of PTYTask that deal with the properties of its pseudo-terminal. This includes getting and setting the size of the terminal, and stalling and restarting terminal output.
*/
@interface SubProcess (terminalTasks)

/**
    Read the terminal geometry.
    Returns the number of rows and columns in the pseudo-terminal in the respective integer-pointer parameters. This will return the default or user-set dimensions if the task has not yet been launched.
	@param		rows	Pointer to an integer to receive the number of rows in the pseudo-terminal. Must not be NULL; not checked.
	@param		columns	Pointer to an integer to receive the number of columns in the pseudo-terminal. Must not be NULL; not checked.
*/
- (void) rows: (int *) rows columns: (int *) columns;
/**
    Change the geometry of the pseudo-terminal.
    Sets the pseudo-terminal's height in rows and width in columns to the respective integer parameters. If the task is not running, the settings are saved and used to initialize the pseudo-terminal.
	@param		rows	Integer, the number of rows the terminal is to have. Must be at least one, but is not checked.
	@param		columns	Integer, the number of columns the terminal is to have. Must be at least one, but is not checked.
*/
- (void) setRows: (int) rows columns: (int) columns;

/**
    Suspend output from the pseudo-terminal.
    Signals the pseudo-terminal to halt (usually suspend) task output. In practice, this is sent when the incoming-data buffer exceeds a limit size (half its absolute limit). An exception is raised if the task is not running when this message is sent.
	@throw		NSInternalInconsistencyException
*/
- (void) stall;
/**
    Resume stalled output from pseudo-terminal.
    Signals the pseudo-terminal to resume output after it has been halted by a call to -stall. An exception is raised if the task is not running when this message is sent.
	@throw		NSInternalInconsistencyException if the task is not running.
*/
- (void) unstall;

@end

/**
    I/O stream methods for PTYTask
    The methods in this category do the basic insertion and retrieval of data between the PTYTask and its client. The output method -writeData wraps a call to write(2) to the tty's device descriptor. The -availableData method pulls the accumulated input from the tty in a thread-safe manner; it's expected the delegate will call -availableData in response to receiving -dataArrivedFromPty: in the ptyTaskDelegate informal protocol.
*/
@interface SubProcess (streamTasks)

/**
    Send bytes to the pseudo-terminal.
    This method writes the bytes represented by the NSData it is passed to the device descriptor for the pseudo-terminal. No check is made of the contents of the NSData. An exception is raised if the task has not yet been launched.
	@param		someData	NSData, the bytes to send. In no wise checked.
*/
- (void) writeData: (NSData *) someData;
/**
    Get all accumulated data from the pseudo-terminal.
    This method essentially swaps out the buffer into which the PTYTask has been accumulating the output of the pseudo-terminal, and returns that buffer. If the terminal had been stalled due to an overfull buffer, it is unstalled.
    @retval     NSData the accumulated bytes since the last time you called -availableData. You are responsible for retaining this object if you want to keep it.
*/
- (NSData *) availableData;

@end

/** Methods for data-handling and other events sent to PTYTask delegates.
    PTYTask does not handle the events that befall it. It is expected that a delegate object, set through -[PTYTask setDelegate], will handle incoming data and end-of-task events. This informal protocol defines the methods a PTYTask delegate must implement.
*/
@interface NSObject (ptyTaskDelegate)

/**
    Notification that data has arrived from the task.
    This message is sent to the delegate object whenever data comes in from the task over the pseudo-terminal. PTYTask reads the terminal on a dedicated thread, but posts this notification on the main thread. This is purely a notice; to access the data, you must harvest the accumulated buffer with -[PTYTask availableData].
    @param      task Pointer to the PTYTask on which data arrived.
*/
- (void) dataArrivedFromPty: (SubProcess *) task;
/**
    Notification that the task has ended.
    PTYTask's read-loop thread sends this message on the main thread when an error is detected in the read. In practice, this happens whenever the task has relinquished the pseudo-terminal by exiting, or the parent task has closed the pseudo-terminal device descriptor (thus terminating the task). 
    @param      task Pointer to the PTYTask that has terminated.
*/
- (void) ptyTaskCompleted: (SubProcess *) task;

@end
