//
//  UnixProcessesHelper.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 19/03/13.
//  Copyright (c) 2013 Octo Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

struct kinfo_proc;

@interface UnixProcessesHelper : NSObject

//Returns an env key based on the user's shell env and not the ~/Library/.../environment.plist one.
//[[[NSProcessInfo processInfo] environment] objectForKey:@"PATH"] does not return the user PATH.
+ (NSString *)getEnv:(NSString *)key;

//Returns the fullpath of a binary. nil if it has not been found.
+ (NSString *)findBinaryNamed:(NSString *)processName;

//Check if a process is running. The pid of the process is provided if the parameter is not nil and the method returns YES.
+ (BOOL)isProcessRunningForProcessNamed:(NSString *)processName;

//Get a list of BSD process.
+ (NSInteger)getBSDProcessListForProcList:(struct kinfo_proc **)procList withProcCount:(size_t *)procCount;

//Returns the list of pids running a process named processName.
+ (NSArray *)pidListForProcessesNamed:(NSString *)processName;

//Get informations about a running process.
+ (NSDictionary *)infoForPID:(pid_t)pid;

@end
