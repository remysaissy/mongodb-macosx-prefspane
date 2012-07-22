//
//  Helpers+Mongod.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 22/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "Helpers+Private.h"
#import "Helpers+Mongod.h"

@implementation Helpers (Mongod)

+ (BOOL)_startMongodProcess
{    
    NSString *processPath = [Helpers _findBinaryNamed:@"mongod"];
    if (processPath == nil)
        return NO;
    NSArray *arguments = [Helpers _processArgumentsForProcessPath:processPath forLaunchctl:NO];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:processPath arguments:arguments];
    [task waitUntilExit];
    BOOL isStarted = [Helpers isProcessRunning];
    if (isStarted == YES)
        NSLog(@"[STARTED] %@ %@", processPath, arguments);
    else
        NSLog(@"[FAILED] %@ %@", processPath, arguments);
    return isStarted;
}

+ (BOOL)_stopMongodProcess
{
    NSArray *pidList = [Helpers _pidListForProcesses];
    for (NSNumber *pid in pidList) {
        if (kill([pid intValue], SIGINT) == -1) {
            NSLog(@"[STOPPED] Process %@ not terminating properly, sending SIGKILL...", pid);
            kill([pid intValue], SIGKILL);
        }
        NSLog(@"[STOPPED] Process %@ terminated.", pid);
    }
    return YES;
}

@end
