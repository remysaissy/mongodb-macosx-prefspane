//
//  Helpers.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 21/07/12.
//  Copyleft LGPL.
//

#import "Helpers.h"
#import "Helpers+Private.h"
#import "Helpers+Mongod.h"
#import "Helpers+Launchd.h"

#pragma mark - Public implementation.

@implementation Helpers

#pragma mark - Manual start/stop process methods.

+ (BOOL)startProcess
{
    if ([Helpers isAutomaticStartupInstalled] == YES)
        return [Helpers _startProcessWithAutomaticStartup];
    else
        return [Helpers _startMongodProcess];
}

+ (BOOL)stopProcess
{
    if ([Helpers isAutomaticStartupInstalled] == YES)
        return [Helpers _stopProcessWithAutomaticStartup];
    else
        return [Helpers _stopMongodProcess];
}

+ (BOOL)isProcessRunning
{
    return [Helpers _isProcessRunningForProcessNamed:@"mongod"];
}

#pragma mark - Launch agent methods.

+ (BOOL)isAutomaticStartupInstalled
{
    NSString *launchDaemonPath = [Helpers _launchDaemonPath];
    BOOL isInstalled = [[NSFileManager defaultManager] fileExistsAtPath:launchDaemonPath];
    if (isInstalled == NO) {
        if ([Helpers isProcessRunning] == YES
            && [Helpers _neutralizeAnotherLaunchdProcess] == YES) {
            isInstalled = [Helpers _installLaunchd];
        }
    }
    return isInstalled;
}

+ (BOOL)installAutomaticStartup
{
    BOOL wasRunning = [Helpers isProcessRunning];
    if (wasRunning == YES)
        [Helpers _stopMongodProcess];
    BOOL isInstalled = [Helpers _installLaunchd];
    if (wasRunning == YES)
        [Helpers startProcess];
    return isInstalled;
}

+ (BOOL)uninstallAutomaticStartup
{
    BOOL wasRunning = [Helpers isProcessRunning];
    if (wasRunning == YES)
        [Helpers _stopProcessWithAutomaticStartup];
    BOOL isUninstalled = [Helpers _uninstallLaunchd];
    if (wasRunning == YES)
        [Helpers startProcess];
    return isUninstalled;
}

@end
