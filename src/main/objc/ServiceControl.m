//
//  ServiceControl.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 21/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "ServiceControl.h"
#import "UnixProcessesHelper.h"
#import "Adapter.h"
#import "LaunchdHelper.h"

#pragma mark - Private interface.

@interface ServiceControl ()

//The adapter for this service control instance.
@property (strong, nonatomic)   Adapter *_adapter;

#pragma mark - Manual Start/Stop process private methods. They do the actual work.

// Start and fork the process.
- (BOOL)_startProcess;

// Stop a forked process.
- (BOOL)_stopProcess;

#pragma mark - Launchd based private methods. They do the actual work.

//Install mongod in launchd.
//- (BOOL)_installLaunchd;

//Uninstall mongod from launchd.
//- (BOOL)_uninstallLaunchd;

//Neutralize any other launchd process. Returns YES if there was a launchd running process.
//One interesting point here is that a previous plist from homebrew for example will simply
//be migrated and not deleted. So your customizations to the file won't be erased.
//- (BOOL)_neutralizeAnotherLaunchdProcess;

@end

#pragma mark - Public implementation.

@implementation ServiceControl

@synthesize delegate;
@synthesize _adapter;

- (void)setDelegate:(id<ServiceControlDelegate>)newDelegate
{
    delegate = newDelegate;
    self._adapter = nil;
    if (delegate != nil) {
        self._adapter = [[Adapter alloc] init];
        self._adapter.processName = [delegate processNameForServiceControl:self];
    }
}

#pragma mark - Manual start/stop process methods.

- (BOOL)startProcess
{
    if ([self isAutomaticStartupInstalled] == YES) {
        [NSString logInfoFromClass:[self class] withSelector:_cmd withFormat:@"--> isAutomaticStartupInstalled"];
            return [LaunchdHelper startAgentNamed:[self._adapter getLaunchdName]];
    } else {
        return [self _startProcess];
    }
}

- (BOOL)stopProcess
{
    if ([self isAutomaticStartupInstalled] == YES) {
        return [LaunchdHelper stopAgentNamed:[self._adapter getLaunchdName]];
    } else {
        return [self _stopProcess];
    }
}

- (BOOL)isProcessRunning
{
    return [UnixProcessesHelper isProcessRunningForProcessNamed:[self.delegate processNameForServiceControl:self]];
}

- (NSArray *)getProcessLocationsList
{
    return [NSArray array];
}

#pragma mark - Launch agent methods.

- (BOOL)isAutomaticStartupInstalled
{
    return [LaunchdHelper isAgentInstalled:[self._adapter getLaunchdName]];
}

- (BOOL)installAutomaticStartup
{
    BOOL wasRunning = [self isProcessRunning];
    if (wasRunning == YES)
        [self _stopProcess];
    NSString *agentName = [self._adapter getLaunchdName];
    NSString *agentFullPath = [self._adapter getLaunchdFullPath];
    NSDictionary *conf = [self._adapter getLaunchdArgumentsDictionary];
    BOOL isInstalled = [LaunchdHelper installAgentNamed:agentName withConfig:conf atFullPath:agentFullPath];
    if (isInstalled == YES)
        [NSString logInfoFromClass:[self class] withSelector:_cmd withFormat:@"Installed"];
    else
        [NSString logInfoFromClass:[self class] withSelector:_cmd withFormat:@"Not installed"];
    if (wasRunning == YES)
        [self startProcess];
    return isInstalled;
}

- (BOOL)uninstallAutomaticStartup
{
    BOOL wasRunning = [self isProcessRunning];
    if (wasRunning == YES)
        [self _stopProcess];
    BOOL isUninstalled = [LaunchdHelper uninstallAgentNamed:[self._adapter getLaunchdName]];
    if (wasRunning == YES)
        [self startProcess];
    return isUninstalled;
}

- (NSString *)launchDaemonName
{
    return [self._adapter getLaunchdName];
}

- (NSString *)launchDaemonPath
{
    return [self._adapter getLaunchdFullPath];
}

#pragma mark - Private implementation.

#pragma mark - Process related methods. These does the actual work.

- (BOOL)_startProcess
{
    NSString *processPath = [self._adapter getProcessFullPath];
    NSArray *arguments = [self._adapter getManualStartArguments];
    if (processPath == nil || arguments == nil)
        return NO;
    NSTask *task = [NSTask launchedTaskWithLaunchPath:processPath arguments:arguments];
    [task waitUntilExit];
    BOOL isStarted = [self isProcessRunning];
    if (isStarted == YES)
        [NSString logInfoFromClass:self.class withSelector:_cmd withFormat:@"%@ %@", processPath, arguments];
    else
        [NSString logErrorFromClass:self.class withSelector:_cmd withFormat:@"%@ %@", processPath, arguments];
    return isStarted;
}

- (BOOL)_stopProcess
{
    NSArray *pidList = [UnixProcessesHelper pidListForProcessesNamed:[self.delegate processNameForServiceControl:self]];
    for (NSNumber *pid in pidList) {
        if (kill([pid intValue], SIGINT) == -1) {
            [NSString logInfoFromClass:self.class withSelector:_cmd withFormat:@"Process %@ not terminating properly, sending SIGKILL...", pid];
            kill([pid intValue], SIGKILL);
        }
        [NSString logInfoFromClass:self.class withSelector:_cmd withFormat:@"Process %@ terminated.", pid];
    }
    return YES;
}

#pragma mark - Launchd related methods. They do the actual work.

//- (BOOL)_installLaunchd
//{
//    BOOL isInstalled = NO;
//    NSString *launchDaemonPath = [self launchDaemonPath];
//    NSString *disabledLaunchDaemonPath = [launchDaemonPath stringByAppendingPathExtension:@"disabled"];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:disabledLaunchDaemonPath] == YES) {
//        [NSString logInfoFromClass:self.class withSelector:_cmd withFormat:@"Previous agent plist found at %@. Restoring...", disabledLaunchDaemonPath];
//        NSMutableDictionary *newPlist = [NSMutableDictionary dictionaryWithContentsOfFile:disabledLaunchDaemonPath];
//            //        Ensure of the value of two critical keys.
//        [newPlist setObject:[self launchDaemonName] forKey:@"Label"];
//        [newPlist setObject:[NSNumber numberWithBool:YES] forKey:@"RunAtLoad"];
//        NSError *error = nil;
//        if ([[NSFileManager defaultManager] removeItemAtPath:disabledLaunchDaemonPath error:&error] == NO)
//            [NSString logErrorFromClass:self.class withSelector:_cmd withFormat:@"Cannot delete previous agent plist in %@.", disabledLaunchDaemonPath];
//        if ([newPlist writeToFile:launchDaemonPath atomically:YES] == NO) {
//            [NSString logErrorFromClass:self.class withSelector:_cmd withFormat:@"Cannot restore previous agent plist in %@.", launchDaemonPath];
//            [self _createLaunchdPlistForDaemonPath:launchDaemonPath];
//        }
//    } else if ([self _createLaunchdPlistForDaemonPath:launchDaemonPath] == NO)
//        return isInstalled;
//    
//        //    At this point the agent plist file has been created if needed. Now load it.
//    NSString *launchctlProcessPath = [UnixProcessesHelper findBinaryNamed:@"launchctl"];
//    NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:[NSArray arrayWithObjects:@"load", launchDaemonPath, nil]];
//    [task waitUntilExit];
//    isInstalled = !task.terminationStatus;
//    if (isInstalled == YES)
//        [NSString logInfoFromClass:[self class] withSelector:_cmd withFormat:@"Agent %@ loaded.", launchDaemonPath];
//    else
//        [NSString logErrorFromClass:[self class] withSelector:_cmd withFormat:@"Cannot load agent %@.", launchDaemonPath];
//    return isInstalled;
//}
//
//- (BOOL)_uninstallLaunchd
//{
//    BOOL isUninstalled = NO;
//    NSString *launchDaemonPath = [self launchDaemonPath];
//    NSString *launchctlProcessPath = [UnixProcessesHelper findBinaryNamed:@"launchctl"];
//    NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:[NSArray arrayWithObjects:@"unload", launchDaemonPath, nil]];
//    [task waitUntilExit];
//    if (!task.terminationStatus)
//        [NSString logInfoFromClass:self.class withSelector:_cmd withFormat:@"Agent %@ unloaded.", launchDaemonPath];
//    else
//        [NSString logErrorFromClass:self.class withSelector:_cmd withFormat:@"Cannot unload agent %@.", launchDaemonPath];
//    NSString *disabledLaunchDaemonPath = [launchDaemonPath stringByAppendingPathExtension:@"disabled"];
//    NSError *error = nil;
//    isUninstalled = [[NSFileManager defaultManager] moveItemAtPath:launchDaemonPath toPath:disabledLaunchDaemonPath error:&error];
//    return isUninstalled;
//}
//
//- (BOOL)_neutralizeAnotherLaunchdProcess
//{
//    NSString *processName = [self.delegate processNameForServiceControl:self];
//    BOOL hasAnotherLaunchdProcess = NO;
//    NSString *targetLaunchdPlist =  [[self launchDaemonPath] stringByAppendingPathExtension:@"disabled"];
//    NSArray *alternativeLaunchDaemonNameArray = nil;
//    if ([self.delegate respondsToSelector:@selector(getAlternativeLaunchDaemonNameArray)]) {
//        alternativeLaunchDaemonNameArray = [self.delegate getAlternativeLaunchDaemonNameArrayForServiceControl:self];
//
//        for (NSString *alternativeLaunchDaemonName in alternativeLaunchDaemonNameArray) {
//            NSError *error = nil;
//            NSString *alternativeLaunchDaemonPath = [alternativeLaunchDaemonName stringByAppendingPathExtension:@"plist"];
//            alternativeLaunchDaemonPath = [[NSString stringWithFormat:@"~/Library/LaunchAgents/%@", alternativeLaunchDaemonPath] stringByExpandingTildeInPath];
//            
//        if ([[NSFileManager defaultManager] fileExistsAtPath:alternativeLaunchDaemonPath] == YES) {
//            [NSString logInfoFromClass:self.class withSelector:_cmd withFormat:@"%@ agent found. Migrating...", alternativeLaunchDaemonName];
//            NSString *launchctlProcessPath = [UnixProcessesHelper findBinaryNamed:@"launchctl"];
//            if ([UnixProcessesHelper isProcessRunningForProcessNamed:processName] == YES)
//                hasAnotherLaunchdProcess = YES;
//            NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlProcessPath arguments:[NSArray arrayWithObjects:@"unload", alternativeLaunchDaemonPath, nil]];
//            [task waitUntilExit];
//            if (task.terminationStatus)
//                [NSString logErrorFromClass:self.class withSelector:_cmd withFormat:@"Cannot unload agent %@.", alternativeLaunchDaemonPath];
//            NSMutableDictionary *agentPlist = [NSMutableDictionary dictionaryWithContentsOfFile:alternativeLaunchDaemonPath];
//            [agentPlist setObject:[self launchDaemonName] forKey:@"Label"];
//            [agentPlist setObject:[NSNumber numberWithBool:YES] forKey:@"RunAtLoad"];
//            [agentPlist writeToFile:targetLaunchdPlist atomically:YES];
//            if ([[NSFileManager defaultManager] removeItemAtPath:alternativeLaunchDaemonPath error:&error] == NO)
//                [NSString logErrorFromClass:self.class withSelector:_cmd withFormat:@"Cannot delete agent plist %@.", alternativeLaunchDaemonPath];
//        }
//        }
//    }
//    return hasAnotherLaunchdProcess;
//}

@end
