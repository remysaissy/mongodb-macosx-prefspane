//
//  Helpers.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 21/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//Name of the process.
extern NSString * const HelpersProcessName;

@interface Helpers : NSObject

//Blocking call to start the process and returns YES in case of success.
+ (BOOL)startProcess;

//Blocking call to stop the process and returns YES in case of success.
+ (BOOL)stopProcess;

//Check if their is a running process (and not only application) named processName.
+ (BOOL)isProcessRunning;

//Returns the list of pids running a process named processName.
+ (NSArray *)pidListForProcesses;

//Returns the fullpath of a binary. nil if it has not been found.
+ (NSString *)findBinary;

@end
