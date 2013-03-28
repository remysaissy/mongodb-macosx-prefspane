//
//  LaunchdHelper.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 24/03/13.
//  Copyright (c) 2013 Octo Technology. All rights reserved.
//

#import "LaunchdHelper.h"

@implementation LaunchdHelper

+ (BOOL)isAgentRunning:(NSString *)agentName
{
    BOOL ret = NO;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = [NSArray arrayWithObjects:@"-l", @"-c", [NSString stringWithFormat:@"launchctl list | grep %@ | head -1 | awk '{ print $1; }'", agentName], nil];
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    NSFileHandle *readHandle = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [readHandle readDataToEndOfFile];
    NSString *pidString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    If the process was not running, we would get a '-' instead of its PID.
    if (pidString.length > 0 && [@"-" isEqualToString:pidString] == NO)
        ret = YES;
    return ret;
}

+ (BOOL)startAgentNamed:(NSString *)agentName
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/launchctl";
    task.arguments = [NSArray arrayWithObjects:@"start", agentName, nil];
    [task launch];
    [task waitUntilExit];
    return (task.terminationStatus == 0);
}

+ (BOOL)stopAgentNamed:(NSString *)agentName
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/launchctl";
    task.arguments = [NSArray arrayWithObjects:@"stop", agentName, nil];
    [task launch];
    [task waitUntilExit];
    return (task.terminationStatus == 0);
}

+ (BOOL)isAgentInstalled:(NSString *)agentName
{
    BOOL ret = NO;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = [NSArray arrayWithObjects:@"-l", @"-c", [NSString stringWithFormat:@"launchctl list | grep %@ | wc -l", agentName], nil];
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    NSFileHandle *readHandle = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [readHandle readDataToEndOfFile];
    NSString *countString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //    If the process was not running, we would get a '-' instead of its PID.
    if (countString.length > 0 && [countString integerValue] > 0)
        ret = YES;
    return ret;
}

+ (BOOL)installAgentNamed:(NSString *)agentName withConfig:(NSDictionary *)conf atFullPath:(NSString *)agentInstallPath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:agentInstallPath] == YES) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:agentInstallPath error:&error];
    }
    BOOL isCreated = [conf writeToFile:agentInstallPath atomically:YES];
    if (isCreated == NO)
        return isCreated;
    return [LaunchdHelper enableAgentNamed:agentName  atFullPath:agentInstallPath];
}
        
+ (BOOL)enableAgentNamed:(NSString *)agentName atFullPath:(NSString *)agentInstallPath
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/launchctl";
    task.arguments = [NSArray arrayWithObjects:@"load", @"-w", agentInstallPath, nil];
    [task launch];
    [task waitUntilExit];
    return (task.terminationStatus == 0);
}


+ (BOOL)uninstallAgentNamed:(NSString *)agentName
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/launchctl";
    task.arguments = [NSArray arrayWithObjects:@"remove", agentName, nil];
    [task launch];
    [task waitUntilExit];
    return (task.terminationStatus == 0);
}

@end
