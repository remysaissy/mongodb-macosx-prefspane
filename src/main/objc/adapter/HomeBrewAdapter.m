//
//  HomeBrewAdapter.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 21/03/13.
//  Copyright (c) 2013 Octo Technology. All rights reserved.
//

#import "HomeBrewAdapter.h"

@implementation HomeBrewAdapter

- (NSArray *)getManualStartArgumentsForProcessNamed:(NSString *)processName
{
    NSString *configFile = [self getConfigurationFileFullPathForProcessNamed:processName];
    NSString *logFile = [self getLogFileFullPathForProcessNamed:processName];
    return [NSArray arrayWithObjects:@"run", @"--fork", @"--config", configFile, @"--logpath", logFile, nil];
}

- (NSArray *)getAutomaticStartArgumentsForProcessNamed:(NSString *)processName
{
    NSString *configFile = [self getConfigurationFileFullPathForProcessNamed:processName];
    NSString *logFile = [self getLogFileFullPathForProcessNamed:processName];
    return [NSArray arrayWithObjects:@"run", @"--config", configFile, @"--logpath", logFile, nil];
}

- (NSString *)getConfigurationFileFullPathForProcessNamed:(NSString *)processName
{
    return [NSString stringWithFormat:@"/usr/local/etc/%@.conf", processName];
}

- (NSString *)getLogFileFullPathForProcessNamed:(NSString *)processName
{
    return [[NSString stringWithFormat:@"~/Library/Logs/%@.log", processName] stringByExpandingTildeInPath];
}

- (NSString *)getLaunchdFullPathForProcessNamed:(NSString *)processName;
{
    NSString *launchdName = [self getLaunchdNameForProcessNamed:processName];
    return [[NSString stringWithFormat:@"~/Library/LaunchAgents/%@.plist", launchdName] stringByExpandingTildeInPath];
}

- (NSString *)getLaunchdNameForProcessNamed:(NSString *)processName
{
    return [NSString stringWithFormat:@"homebrew.mxcl.%@", processName];
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
    return @"/usr/local/bin";
}

+ (NSString *)getProcessFullPathForProcessNamed:(NSString *)processName
{
    return [NSString stringWithFormat:@"%@/%@", [HomeBrewAdapter getPath], processName];
}

+ (BOOL)isActiveForProcessNamed:(NSString *)processName
{
    BOOL isActive = NO;
    
    NSString *processPath = [HomeBrewAdapter getProcessFullPathForProcessNamed:processName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:processPath] == YES) {
        isActive = YES;
    }
    return isActive;
}


@end
