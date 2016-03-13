//
//  Helpers+Private.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 22/07/12.
//  Copyleft LGPL.
//

#import "Helpers.h"

struct kinfo_proc;

@interface Helpers (Private)

//Check if a process is running. The pid of the process is provided if the parameter is not nil and the method returns YES.
+ (BOOL)_isProcessRunningForProcessNamed:(NSString *)processName;

//Get a list of BSD process.
+ (NSInteger)_getBSDProcessListForProcList:(struct kinfo_proc **)procList withProcCount:(size_t *)procCount;

//Returns the launch daemon plist file.
+ (NSString *)_launchDaemonPath;

//Returns the process arguments
+ (NSArray *)_processArgumentsForProcessPath:(NSString *)processPath forLaunchctl:(BOOL)useLaunchctl;

//Returns the fullpath of a binary. nil if it has not been found.
+ (NSString *)_findBinaryNamed:(NSString *)processName;

//Returns the list of pids running a process named processName.
+ (NSArray *)_pidListForProcesses;

//Get informations about a running process.
+ (NSDictionary *)_infoForPID:(pid_t)pid;

@end
