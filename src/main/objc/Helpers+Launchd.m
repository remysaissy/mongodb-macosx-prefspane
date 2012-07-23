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
        [NSString logInfoFromClass:[Helpers class] withSelector:_cmd withFormat:@"Started %@ %@", launchctlProcessPath, arguments];
    else
        [NSString logErrorFromClass:[Helpers class] withSelector:_cmd withFormat:@"Cannot start %@ %@", launchctlProcessPath, arguments];
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
        [NSString logInfoFromClass:[Helpers class] withSelector:_cmd withFormat:@"Stopped %@ %@", launchctlProcessPath, arguments];
    else
        [NSString logErrorFromClass:[Helpers class] withSelector:_cmd withFormat:@"Cannot stop %@ %@", launchctlProcessPath, arguments];
    return isStopped;
}

+ (BOOL)_installLaunchd
{    
    BOOL isInstalled = NO;
    NSString *launchDaemonPath = [Helpers _launchDaemonPath];
    NSString *disabledLaunchDaemonPath = [launchDaemonPath stringByAppendingPathExtension:@"disabled"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:disabledLaunchDaemonPath] == YES) {
        [NSString logInfoFromClass:[Helpers class] withSelector:_cmd withFormat:@"Previous agent plist found at %@. Restoring...", disabledLaunchDaemonPath];
        NSMutableDictionary *newPlist = [NSMutableDictionary dictionaryWithContentsOfFile:disabledLaunchDaemonPath];
//        Ensure of the value of two critical keys.
        [newPlist setObject:@"com.remysaissy.mongodbprefspane" forKey:@"Label"];        
        [newPlist setObject:[NSNumber numberWithBool:YES] forKey:@"RunAtLoad"];
        NSError *error = nil;
        if ([[NSFileManager defaultManager] removeItemAtPath:disabledLaunchDaemonPath error:&error] == NO)
            [NSString logErrorFromClass:[Helpers class] withSelector:_cmd withFormat:@"Cannot delete previous agent plist in %@.", disabledLaunchDaemonPath];
        if ([newPlist writeToFile:launchDaemonPath atomically:YES] == NO) {
            [NSString logErrorFromClass:[Helpers class] withSelector:_cmd withFormat:@"Cannot restore previous agent plist in %@.", launchDaemonPath];
            [Helpers _createLaunchdPlistForDaemonPath:launchDaemonPath];
        }
    } else if ([Helpers _createLaunchdPlistForDaemonPath:launchDaemonPath] == NO)
        return isInstalled;
    
    //    At this point the agent plist file has been created if needed. Now load it.
    NSString *launchctlProcessPath = [Helpers _findBinaryNamed:@"launchctl"];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:[NSArray arrayWithObjects:@"load", launchDaemonPath, nil]];
    [task waitUntilExit];
    isInstalled = !task.terminationStatus;
    if (isInstalled == YES)
        [NSString logInfoFromClass:[Helpers class] withSelector:_cmd withFormat:@"Agent %@ loaded.", launchDaemonPath];
    else
        [NSString logErrorFromClass:[Helpers class] withSelector:_cmd withFormat:@"Cannot load agent %@.", launchDaemonPath];
    return isInstalled;
}

+ (BOOL)_uninstallLaunchd
{
    BOOL isUninstalled = NO;
    NSString *launchDaemonPath = [Helpers _launchDaemonPath];    
    NSString *launchctlProcessPath = [Helpers _findBinaryNamed:@"launchctl"];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:[NSArray arrayWithObjects:@"unload", launchDaemonPath, nil]];   
    [task waitUntilExit];
    if (!task.terminationStatus)
        [NSString logInfoFromClass:[Helpers class] withSelector:_cmd withFormat:@"Agent %@ unloaded.", launchDaemonPath];
    else
        [NSString logErrorFromClass:[Helpers class] withSelector:_cmd withFormat:@"Cannot unload agent %@.", launchDaemonPath];
    NSString *disabledLaunchDaemonPath = [launchDaemonPath stringByAppendingPathExtension:@"disabled"];
    NSError *error = nil;
    isUninstalled = [[NSFileManager defaultManager] moveItemAtPath:launchDaemonPath toPath:disabledLaunchDaemonPath error:&error];
    return isUninstalled;
}

+ (BOOL)_neutralizeAnotherLaunchdProcess
{
    BOOL hasAnotherLaunchdProcess = NO;
    NSString *homeBrewMongodLaunchdPlist = [@"~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist" stringByExpandingTildeInPath];
    NSString *targetMongodLaunchdPlist = [@"~/Library/LaunchAgents/com.remysaissy.mongodbprefspane.plist.disabled" stringByExpandingTildeInPath];    
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:homeBrewMongodLaunchdPlist] == YES) {
        [NSString logInfoFromClass:[Helpers class] withSelector:_cmd withFormat:@"Homebrew agent found. Migrating..."];
        NSString *launchctlProcessPath = [Helpers _findBinaryNamed:@"launchctl"];
        if ([Helpers _isProcessRunningForProcessNamed:@"mongod"] == YES)
            hasAnotherLaunchdProcess = YES;
        NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:[NSArray arrayWithObjects:@"unload", homeBrewMongodLaunchdPlist, nil]];   
        [task waitUntilExit];
        if (task.terminationStatus)
            [NSString logErrorFromClass:[Helpers class] withSelector:_cmd withFormat:@"Cannot unload agent %@.", homeBrewMongodLaunchdPlist];
        NSMutableDictionary *homeBrewPlist = [NSMutableDictionary dictionaryWithContentsOfFile:homeBrewMongodLaunchdPlist];
        [homeBrewPlist setObject:@"com.remysaissy.mongodbprefspane" forKey:@"Label"];
        [homeBrewPlist setObject:[NSNumber numberWithBool:YES] forKey:@"RunAtLoad"];
        [homeBrewPlist writeToFile:targetMongodLaunchdPlist atomically:YES];        
        if ([[NSFileManager defaultManager] removeItemAtPath:homeBrewMongodLaunchdPlist error:&error] == NO)
            [NSString logErrorFromClass:[Helpers class] withSelector:_cmd withFormat:@"Cannot delete agent plist %@.", homeBrewMongodLaunchdPlist];
    }
    return hasAnotherLaunchdProcess;
}

+ (NSDictionary *)_createLaunchdPlistDictionary
{
    NSMutableDictionary *launchAgentContent = [NSMutableDictionary dictionary];
    [launchAgentContent setObject:@"com.remysaissy.mongodbprefspane" forKey:@"Label"];
    NSString *processPath = [Helpers _findBinaryNamed:@"mongod"];
    NSMutableArray *programArguments = [NSMutableArray arrayWithArray:[Helpers _processArgumentsForProcessPath:processPath forLaunchctl:YES]];
    [programArguments insertObject:processPath atIndex:0];    
    [launchAgentContent setObject:programArguments forKey:@"ProgramArguments"];    
    [launchAgentContent setObject:[NSNumber numberWithBool:YES] forKey:@"RunAtLoad"];
    [launchAgentContent setObject:[NSNumber numberWithBool:NO] forKey:@"KeepAlive"];
    [launchAgentContent setObject:NSUserName() forKey:@"UserName"];
    NSString *processLogPath = [@"~/Library/Logs/mongod.log" stringByExpandingTildeInPath];
    [launchAgentContent setObject:processLogPath forKey:@"StandardErrorPath"];
    [launchAgentContent setObject:processLogPath forKey:@"StandardOutPath"];
    NSString *processWorkingDirectory = [[processPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    [launchAgentContent setObject:processWorkingDirectory forKey:@"WorkingDirectory"];    
    return launchAgentContent;
}

+ (BOOL)_createLaunchdPlistForDaemonPath:(NSString *)launchDaemonPath
{
    BOOL isCreated = NO;
    [NSString logInfoFromClass:[Helpers class] withSelector:_cmd withFormat:@"No agent plist found at %@. Creating one...", launchDaemonPath];
    NSDictionary *launchAgentContent = [Helpers _createLaunchdPlistDictionary];
    isCreated = [launchAgentContent writeToFile:launchDaemonPath atomically:YES];
    if (isCreated)
        [NSString logInfoFromClass:[Helpers class] withSelector:_cmd withFormat:@"Wrote agent plist in %@.", launchDaemonPath];
    else
        [NSString logInfoFromClass:[Helpers class] withSelector:_cmd withFormat:@"Cannot create agent plist in %@.", launchDaemonPath];
    return isCreated;
}

@end
