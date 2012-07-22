//
//  Helpers+Launchd.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 22/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "Helpers+Private.h"
#import "Helpers+Launchd.h"

@implementation Helpers (Launchd)

+ (BOOL)_startProcessWithAutomaticStartup
{
    NSString *launchctlProcessPath = [Helpers _findBinaryNamed:@"launchctl"];
    NSArray *arguments = [NSArray arrayWithObjects:@"start", @"com.remysaissy.mongodbprefspane", nil];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:arguments];
    [task waitUntilExit];
    BOOL isStarted = [Helpers _isProcessRunningForProcessNamed:@"mongod"];
    if (isStarted == YES)
        NSLog(@"[STARTED] %@ %@", launchctlProcessPath, arguments);
    else
        NSLog(@"[FAILED] %@ %@", launchctlProcessPath, arguments);
    return isStarted;
}

+ (BOOL)_stopProcessWithAutomaticStartup
{
    NSString *launchctlProcessPath = [Helpers _findBinaryNamed:@"launchctl"];
    NSArray *arguments = [NSArray arrayWithObjects:@"stop", @"com.remysaissy.mongodbprefspane", nil];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:arguments];
    [task waitUntilExit];
    BOOL isStopped = ![Helpers _isProcessRunningForProcessNamed:@"mongod"];
    if (isStopped == YES)
        NSLog(@"[STOPPED] %@ %@", launchctlProcessPath, arguments);
    else
        NSLog(@"[FAIL] Failed to stop: %@ %@", launchctlProcessPath, arguments);
    return isStopped;
}

+ (BOOL)_installLaunchd
{    
    BOOL isInstalled = NO;
    NSString *launchDaemonPath = [Helpers _launchDaemonPath];
    NSMutableDictionary *launchAgentContent = [NSMutableDictionary dictionary];
    [launchAgentContent setValue:@"com.remysaissy.mongodbprefspane" forKey:@"Label"];
    NSString *processPath = [Helpers _findBinaryNamed:@"mongod"];
    NSMutableArray *programArguments = [NSMutableArray arrayWithArray:[Helpers _processArgumentsForProcessPath:processPath forLaunchctl:YES]];
    [programArguments insertObject:processPath atIndex:0];    
    [launchAgentContent setValue:programArguments forKey:@"ProgramArguments"];    
    if ([launchAgentContent writeToFile:launchDaemonPath atomically:YES] == YES) {
        NSLog(@"Wrote plist to file %@.", launchDaemonPath);
        NSString *launchctlProcessPath = [Helpers _findBinaryNamed:@"launchctl"];
        NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:[NSArray arrayWithObjects:@"load", launchDaemonPath, nil]];
        [task waitUntilExit];
        isInstalled = !task.terminationStatus;
        if (isInstalled == YES)
            NSLog(@"[LOAD] Agent %@ loaded.", launchDaemonPath);
        else
            NSLog(@"[FAIL] Failed to load agent %@.", launchDaemonPath);
    }    
    return isInstalled;
}

+ (BOOL)_uninstallLaunchd
{
    BOOL isUninstalled = NO;
    NSString *launchDaemonPath = [Helpers _launchDaemonPath];    
    NSString *launchctlProcessPath = [Helpers _findBinaryNamed:@"launchctl"];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:[NSArray arrayWithObjects:@"unload", launchDaemonPath, nil]];   
    [task waitUntilExit];
    if (!task.terminationStatus) {
        NSString *launchDaemonPath = [Helpers _launchDaemonPath];
        NSError *error = nil;
        if ([[NSFileManager defaultManager] removeItemAtPath:launchDaemonPath error:&error] == YES) {
            isUninstalled = YES;
            NSLog(@"[UNLOAD] %@ agent unloaded.", launchDaemonPath);
        } else {
            NSLog(@"[FAIL] Failed to delete agent plist %@: %@.", launchDaemonPath, error.localizedFailureReason);
        }
    } else {
        NSLog(@"[FAIL] Failed to unload agent %@.", launchDaemonPath);
    }
    return isUninstalled;
}

@end
