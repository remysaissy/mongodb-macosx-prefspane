//
//  Helpers+Process.m
//  Cassandra-PrefsPane
//
//  Created by Rémy SAISSY on 22/07/12.
//  Copyleft LGPL.
//

#import "Helpers+Private.h"
#import "Helpers+Process.h"

@implementation Helpers (Process)

+ (BOOL)_startProcess
{
    BOOL isStarted = NO;
    NSString *processPath = [Helpers _findBinaryNamed:@"cassandra"];
    if (processPath != nil) {
        NSTask *task = [[[NSTask alloc] init] autorelease];
    //    Check if there is a symlink, in which case the working dir is changed.
        NSString *realProcessPath = [processPath stringByResolvingSymlinksInPath];
        if ([realProcessPath isEqualToString:processPath] == NO) {
            NSString *workingDir = [realProcessPath stringByDeletingLastPathComponent];
            workingDir = [workingDir stringByDeletingLastPathComponent];
            [task setCurrentDirectoryPath:workingDir];
            processPath = realProcessPath;
        }
        [task setLaunchPath:processPath];
        [task launch];
        [task waitUntilExit];
        isStarted = [Helpers isProcessRunning];
    }
    if (isStarted == YES)
        INFO(@"Started process %@", processPath);
    else
        ERROR(@"Could not start process %@", processPath);
    return isStarted;
}

+ (BOOL)_stopProcess
{
    NSArray *pidList = [Helpers _pidListForProcesses];
    for (NSNumber *pid in pidList) {
        kill([pid intValue], SIGKILL);
        INFO(@"Stopped process ID %@.", pid);
    }
    BOOL isStopped = ![Helpers isProcessRunning];
    if (isStopped == NO)
        ERROR(@"Could not stop process.");
    return isStopped;
}

@end

