//
//  Helpers+Private.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 22/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "Helpers+Private.h"

#include <sys/sysctl.h>
#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>

#pragma mark - Static methods.

@implementation Helpers (Private)

+ (BOOL)_isProcessRunningForProcessNamed:(NSString *)processName
{
    BOOL    isRunning = NO;
    struct kinfo_proc *processList = NULL;
    size_t processCount = 0;
    [Helpers _getBSDProcessListForProcList:&processList withProcCount:&processCount];
    assert(processList != NULL);
    for (int k = 0; k < processCount; k++) {
        struct kinfo_proc *proc = NULL;
        proc = &processList[k];
        NSString *fullName = [[self _infoForPID:proc->kp_proc.p_pid] objectForKey:(id)kCFBundleNameKey];
        if (fullName == nil) 
            fullName = [NSString stringWithFormat:@"%s",proc->kp_proc.p_comm];
        if ([processName isEqualToString:fullName] == YES) {
            isRunning = YES;
            break;
        }
    }
    free(processList);  
    return isRunning;
}

+ (NSString *)_launchDaemonPath
{
    return [@"~/Library/LaunchAgents/com.remysaissy.mongodbprefspane.plist" stringByExpandingTildeInPath];    
}

+ (NSArray *)_processArgumentsForProcessPath:(NSString *)processPath forLaunchctl:(BOOL)useLaunchctl
{    
    NSMutableArray *configPathArray = [[[processPath pathComponents] mutableCopy] autorelease];
    [configPathArray replaceObjectAtIndex:[configPathArray count] - 2  withObject:@"etc"];
    [configPathArray replaceObjectAtIndex:[configPathArray count] - 1  withObject:@"mongod.conf"];
    NSString *configPath = [NSString pathWithComponents:configPathArray];
    NSString *logPath = [@"~/Library/Logs/mongod.log" stringByExpandingTildeInPath];
    NSArray *arguments = nil;
    if (useLaunchctl == YES)
        arguments = [NSArray arrayWithObjects:@"run", @"--logpath", logPath, @"--config", configPath, nil];
    else
        arguments = [NSArray arrayWithObjects:@"run", @"--fork", @"--logpath", logPath, @"--config", configPath, nil];
    return arguments;
}

+ (NSString *)_findBinaryNamed:(NSString *)processName
{
    NSString *binaryFullPath = nil;
    NSString *path = [[[[[NSProcessInfo processInfo] environment] objectForKey:@"PATH"] retain] autorelease];
    NSArray *searchPath = [path componentsSeparatedByString:@":"];
    for (NSString *filePath in searchPath) {
        binaryFullPath = [filePath stringByAppendingPathComponent:processName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:binaryFullPath] == YES)
            break;
    }    
    return binaryFullPath;    
}

+ (NSArray *)_pidListForProcesses
{
    NSMutableArray *pidList = [NSMutableArray array];
    struct kinfo_proc *processList = NULL;
    size_t processCount = 0;
    [Helpers _getBSDProcessListForProcList:&processList withProcCount:&processCount];
    assert(processList != NULL);
    for (int k = 0; k < processCount; k++) {
        struct kinfo_proc *proc = NULL;
        proc = &processList[k];
        NSString *fullName = [[self _infoForPID:proc->kp_proc.p_pid] objectForKey:(id)kCFBundleNameKey];
        if (fullName == nil) 
            fullName = [NSString stringWithFormat:@"%s",proc->kp_proc.p_comm];
        if ([@"mongod" isEqualToString:fullName] == YES)
            [pidList addObject:[NSNumber numberWithInt:proc->kp_proc.p_pid]];
    }
    free(processList);  
    return pidList;
}

+ (NSDictionary *)_infoForPID:(pid_t)pid 
{
    NSDictionary *ret = nil;
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    if (GetProcessForPID(pid, &psn) == noErr) {
        CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,kProcessDictionaryIncludeAllInformationMask); 
        ret = [NSDictionary dictionaryWithDictionary:(NSDictionary *)cfDict];
        CFRelease(cfDict);
    }
    return ret;
}

//Get the full list of running processes.
//See: http://developer.apple.com/legacy/mac/library/#qa/qa2001/qa1123.html
+ (NSInteger)_getBSDProcessListForProcList:(struct kinfo_proc **)procList withProcCount:(size_t *)procCount
{
    int                 err;
    struct kinfo_proc   *result;
    bool                done;
    static const int    name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    // Declaring name as const requires us to cast it when passing it to
    // sysctl because the prototype doesn't include the const modifier.
    size_t              length;
    
    assert(procList != NULL);
    assert(*procList == NULL);
    assert(procCount != NULL);
    
    *procCount = 0;
    
    // We start by calling sysctl with result == NULL and length == 0.
    // That will succeed, and set length to the appropriate length.
    // We then allocate a buffer of that size and call sysctl again
    // with that buffer.  If that succeeds, we're done.  If that fails
    // with ENOMEM, we have to throw away our buffer and loop.  Note
    // that the loop causes use to call sysctl with NULL again; this
    // is necessary because the ENOMEM failure case sets length to
    // the amount of data returned, not the amount of data that
    // could have been returned.
    
    result = NULL;
    done = false;
    do {
        assert(result == NULL);
        // Call sysctl with a NULL buffer.
        
        length = 0;
        err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
                     NULL, &length,
                     NULL, 0);
        if (err == -1) {
            err = errno;
        }
        
        // Allocate an appropriately sized buffer based on the results
        // from the previous call.
        
        if (err == 0) {
            result = malloc(length);
            if (result == NULL) {
                err = ENOMEM;
            }
        }
        
        // Call sysctl again with the new buffer.  If we get an ENOMEM
        // error, toss away our buffer and start again.
        
        if (err == 0) {
            err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
                         result, &length,
                         NULL, 0);
            if (err == -1) {
                err = errno;
            }
            if (err == 0) {
                done = true;
            } else if (err == ENOMEM) {
                assert(result != NULL);
                free(result);
                result = NULL;
                err = 0;
            }
        }
    } while (err == 0 && ! done);
    
    // Clean up and establish post conditions.
    
    if (err != 0 && result != NULL) {
        free(result);
        result = NULL;
    }
    
    *procList = result;
    
    if (err == 0) {
        *procCount = length / sizeof(struct kinfo_proc);
    }
    
    assert( (err == 0) == (*procList != NULL) );    
    return err;
}

@end
