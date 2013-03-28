//
//  MacPortsAdapter.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 21/03/13.
//  Copyright (c) 2013 Octo Technology. All rights reserved.
//

#import "MacPortsAdapter.h"

@implementation MacPortsAdapter

- (NSArray *)getManualStartArgumentsForProcessNamed:(NSString *)processName
{
    NSMutableArray *cmdline = [NSMutableArray array];
    NSString *logPath = [self getLogFileFullPathForProcessNamed:processName];
    if ([@"mongod" isEqualToString:processName]) {
            NSString *dbPath = @"/opt/local/var/db/mongodb";
            [cmdline addObject:@"run"];
            [cmdline addObject:@"--fork"];
            [cmdline addObject:@"--dbpath"];
            [cmdline addObject:dbPath];
            [cmdline addObject:@"--logpath"];
            [cmdline addObject:logPath];
            [cmdline addObject:@"--logappend"];
            [cmdline addObject:@";"];
    }
    return cmdline;
}

- (NSArray *)getAutomaticStartArgumentsForProcessNamed:(NSString *)processName
{
    NSString *logFile = [self getLogFileFullPathForProcessNamed:processName];
    NSString *dbPath = @"/opt/local/var/db/mongodb";
    return [NSArray arrayWithObjects:@"run", @"--dbpath", dbPath, @"--logpath", logFile, @"--logappend", @";", nil];
}

- (NSString *)getConfigurationFileFullPathForProcessNamed:(NSString *)processName
{
    return nil;
}

- (NSString *)getLogFileFullPathForProcessNamed:(NSString *)processName
{
//    return [NSString stringWithFormat:@"/opt/local/var/log/%@/%@.log", processName, processName];
    return [[NSString stringWithFormat:@"~/Library/Logs/%@.log", processName] stringByExpandingTildeInPath];    
}

- (NSString *)getLaunchdFullPathForProcessNamed:(NSString *)processName;
{
//    NSString *launchdFullPath = nil;
//    NSString *launchdName = [self getLaunchdNameForProcessNamed:processName];
//      launchdFullPath = [NSString stringWithFormat:@"/opt/local/etc/LaunchDaemons/%@/%@.plist", launchdName, launchdName];
//    return launchdFullPath;
    NSString *launchdName = [self getLaunchdNameForProcessNamed:processName];
    return [[NSString stringWithFormat:@"~/Library/LaunchAgents/%@.plist", launchdName] stringByExpandingTildeInPath];    
}

- (NSString *)getLaunchdNameForProcessNamed:(NSString *)processName
{
    NSString *launchName = nil;
    if ([@"mongod" isEqualToString:processName]) {
        launchName = @"org.macports.mongodb";
    }
    return launchName;
}

- (NSDictionary *)getLaunchdArgumentsDictionaryForProcessNamed:(NSString *)processName
{
    NSMutableDictionary *launchAgentContent = [NSMutableDictionary dictionary];
    [launchAgentContent setObject:[self getLaunchdNameForProcessNamed:processName] forKey:@"Label"];
    NSString *processPath = [[self class] getProcessFullPathForProcessNamed:processName];
    NSMutableArray *arguments = [NSMutableArray arrayWithObject:processPath];
    [arguments addObjectsFromArray:[self getAutomaticStartArgumentsForProcessNamed:processName]];
    [launchAgentContent setObject:arguments forKey:@"ProgramArguments"];
    [launchAgentContent setObject:[NSNumber numberWithBool:YES] forKey:@"RunAtLoad"];
    [launchAgentContent setObject:[NSNumber numberWithBool:NO] forKey:@"KeepAlive"];
    [launchAgentContent setObject:NSUserName() forKey:@"UserName"];
    NSString *logFile = [self getLogFileFullPathForProcessNamed:processName];
    [launchAgentContent setObject:logFile forKey:@"StandardErrorPath"];
    [launchAgentContent setObject:logFile forKey:@"StandardOutPath"];
    NSString *processWorkingDirectory = [[processPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    [launchAgentContent setObject:processWorkingDirectory forKey:@"WorkingDirectory"];
    return [launchAgentContent copy];
}

#pragma mark - Static methods.

+ (NSString *)getPath
{
    return @"/opt/local/bin";
}

+ (NSString *)getProcessFullPathForProcessNamed:(NSString *)processName
{
    return [NSString stringWithFormat:@"%@/%@", [MacPortsAdapter getPath], processName];
}

+ (BOOL)isActiveForProcessNamed:(NSString *)processName
{
    BOOL isActive = NO;
    
    NSString *processPath = [MacPortsAdapter getProcessFullPathForProcessNamed:processName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:processPath] == YES) {
        isActive = YES;
    }
    return isActive;
}

@end
