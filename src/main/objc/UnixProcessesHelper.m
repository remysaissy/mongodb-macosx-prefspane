//
//  UnixProcessesHelper.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 19/03/13.
//  Copyright (c) 2013 Octo Technology. All rights reserved.
//

#include <sys/sysctl.h>
#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>

#import "UnixProcessesHelper.h"

@implementation UnixProcessesHelper

+ (NSString *)getEnv:(NSString *)key
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:[NSArray arrayWithObjects:@"-l", @"-c", [NSString stringWithFormat:@"env | grep %@", key], nil]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *readHandle = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [readHandle readDataToEndOfFile];
    NSString *pathString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSRange range = [pathString rangeOfString:@"="];
    NSString *pathValue = [pathString substringFromIndex:range.location+1];
    return pathValue;
}

+ (NSString *)findBinaryNamed:(NSString *)processName
{
    NSString *binaryFullPath = nil;    
    NSString *path = [UnixProcessesHelper getEnv:@"PATH"];
    NSArray *searchPath = [path componentsSeparatedByString:@":"];
    for (NSString *filePath in searchPath) {
        binaryFullPath = [filePath stringByAppendingPathComponent:processName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:binaryFullPath] == YES)
            break;
    }
    return binaryFullPath;
}

+ (BOOL)isProcessRunningForProcessNamed:(NSString *)processName
{
    BOOL    isRunning = NO;
    struct kinfo_proc *processList = NULL;
    size_t processCount = 0;
    [UnixProcessesHelper getBSDProcessListForProcList:&processList withProcCount:&processCount];
    assert(processList != NULL);
    for (int k = 0; k < processCount; k++) {
        struct kinfo_proc *proc = NULL;
        proc = &processList[k];
        NSString *fullName = [[UnixProcessesHelper infoForPID:proc->kp_proc.p_pid] objectForKey:(id)kCFBundleNameKey];
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

+ (NSArray *)pidListForProcessesNamed:(NSString *)processName
{
    NSMutableArray *pidList = [NSMutableArray array];
    struct kinfo_proc *processList = NULL;
    size_t processCount = 0;
    [UnixProcessesHelper getBSDProcessListForProcList:&processList withProcCount:&processCount];
    assert(processList != NULL);
    for (int k = 0; k < processCount; k++) {
        struct kinfo_proc *proc = NULL;
        proc = &processList[k];
        NSString *fullName = [[UnixProcessesHelper infoForPID:proc->kp_proc.p_pid] objectForKey:(id)kCFBundleNameKey];
        if (fullName == nil)
            fullName = [NSString stringWithFormat:@"%s",proc->kp_proc.p_comm];
        if ([processName isEqualToString:fullName] == YES)
            [pidList addObject:[NSNumber numberWithInt:proc->kp_proc.p_pid]];
    }
    free(processList);
    return pidList;
}

+ (NSDictionary *)infoForPID:(pid_t)pid
{
    NSDictionary *ret = nil;
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    if (GetProcessForPID(pid, &psn) == noErr) {
        CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,kProcessDictionaryIncludeAllInformationMask);
        ret = [NSDictionary dictionaryWithDictionary:( NSDictionary *)CFBridgingRelease(cfDict)];
        CFRelease(cfDict);
    }
    return ret;
}

//Get the full list of running processes.
//See: http://developer.apple.com/legacy/mac/library/#qa/qa2001/qa1123.html
+ (NSInteger)getBSDProcessListForProcList:(struct kinfo_proc **)procList withProcCount:(size_t *)procCount
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
