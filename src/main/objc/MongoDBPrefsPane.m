//
//  mongodb.m
//  mongodb
//
//  Created by Rémy SAISSY on 20/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "MongoDBPrefsPane.h"

#include <sys/sysctl.h>
#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>

typedef struct kinfo_proc kinfo_proc;

//Get the full list of running processes.
//See: http://developer.apple.com/legacy/mac/library/#qa/qa2001/qa1123.html
static int GetBSDProcessList(kinfo_proc **procList, size_t *procCount)
// Returns a list of all BSD processes on the system.  This routine
// allocates the list and puts it in *procList and a count of the
// number of entries in *procCount.  You are responsible for freeing
// this list (use "free" from System framework).
// On success, the function returns 0.
// On error, the function returns a BSD errno value.
{
    int                 err;
    kinfo_proc *        result;
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
        *procCount = length / sizeof(kinfo_proc);
    }
    
    assert( (err == 0) == (*procList != NULL) );    
    return err;
}

@interface MongoDBPrefsPane()

//The last state of the server which is displayed on the UI.
@property (assign, nonatomic) BOOL  _isStarted;

//Check if their is a running process (and not only application) named processName.
- (BOOL)_isRunningProcessNamed:(NSString *)processName;

//Returns the list of pids running a process named processName.
- (NSArray *)_pidListForProcessesNamed:(NSString *)processName;

//Get informations about a running process.
- (NSDictionary *)_infoForPID:(pid_t)pid;

//Returns the fullpath of a binary. nil if it has not been found.
- (NSString *)_findBinaryNamed:(NSString *)binaryName;

//Configure the UI with the process started.
- (void)_setProcessAsStarted;

//Configure the UI with the process stopped.
- (void)_setProcessAsStopped;

//Blocking call to start the process and returns YES in case of success.
- (BOOL)_startProcess;

//Blocking call to stop the process and returns YES in case of success.
- (BOOL)_stopProcess;

@end

@implementation MongoDBPrefsPane

@synthesize instanceStatusStoppedImageView;
@synthesize instanceStatusStartedImageView;
@synthesize instanceStatusDescriptionTextField;
@synthesize instanceStatusTextField;
@synthesize instanceStartStopButton;
@synthesize instanceAutomaticStartButton;

//Private properties.
@synthesize _isStarted;

- (void)didSelect
{
    if ([self _isRunningProcessNamed:@"mongod"] == YES)
        [self _setProcessAsStarted];
    else
        [self _setProcessAsStopped];
}

- (IBAction)onStartStopButtonPushed:(id)sender
{
    if (self._isStarted == YES) {
        if ([self _stopProcess] == YES)
            [self _setProcessAsStopped];        
    } else {
        if ([self _startProcess] == YES) {
            NSLog(@"Process is running!");
            [self _setProcessAsStarted];
        }
    }
}

- (IBAction)onAutomaticStartButtonPushed:(id)sender
{
}

#pragma mark - Private methods.

- (NSString *)_findBinaryNamed:(NSString *)binaryName
{
    NSString *binaryFullPath = nil;
    NSString *path = [[[[NSProcessInfo processInfo] environment] objectForKey:@"PATH"] retain];
    NSArray *searchPath = [path componentsSeparatedByString:@":"];
    for (NSString *filePath in searchPath) {
        binaryFullPath = [filePath stringByAppendingPathComponent:binaryName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:binaryFullPath] == YES)
            break;
    }    
    return binaryFullPath;    
}

- (BOOL)_isRunningProcessNamed:(NSString *)processName
{
    BOOL    isRunning = NO;
    kinfo_proc *processList = NULL;
    size_t processCount = 0;
    GetBSDProcessList(&processList, &processCount);
    assert(processList != NULL);
    for (int k = 0; k < processCount; k++) {
        kinfo_proc *proc = NULL;
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

- (NSArray *)_pidListForProcessesNamed:(NSString *)processName
{
    NSMutableArray *pidList = [NSMutableArray array];
    kinfo_proc *processList = NULL;
    size_t processCount = 0;
    GetBSDProcessList(&processList, &processCount);
    assert(processList != NULL);
    for (int k = 0; k < processCount; k++) {
        kinfo_proc *proc = NULL;
        proc = &processList[k];
        NSString *fullName = [[self _infoForPID:proc->kp_proc.p_pid] objectForKey:(id)kCFBundleNameKey];
        if (fullName == nil) 
            fullName = [NSString stringWithFormat:@"%s",proc->kp_proc.p_comm];
        if ([processName isEqualToString:fullName] == YES)
            [pidList addObject:[NSNumber numberWithInt:proc->kp_proc.p_pid]];
    }
    free(processList);  
    return pidList;
}

- (NSDictionary *)_infoForPID:(pid_t)pid 
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

- (void)_setProcessAsStarted
{
    [self.instanceStatusTextField setStringValue:NSLocalizedString(@"started", nil)];
    [self.instanceStatusTextField setTextColor:[NSColor greenColor]];
    [self.instanceStartStopButton setTitle:NSLocalizedString(@"Stop MongoDB Server", nil)];
    [self.instanceStatusDescriptionTextField setStringValue:NSLocalizedString(@"The MongoDB Database Server is currently started. To stop it, use the \"Stop MongoDB Server\" button.", nil)];    
    [self.instanceStatusStartedImageView setHidden:NO];
    [self.instanceStatusStoppedImageView setHidden:YES];
    self._isStarted = YES;
}

- (void)_setProcessAsStopped
{
    [self.instanceStatusTextField setStringValue:NSLocalizedString(@"stopped", nil)];
    [self.instanceStatusTextField setTextColor:[NSColor redColor]];
    [self.instanceStartStopButton setTitle:NSLocalizedString(@"Start MongoDB Server", nil)];
    [self.instanceStatusDescriptionTextField setStringValue:NSLocalizedString(@"The MongoDB Database Server is currently stopped. To start it, use the \"Start MongoDB Server\" button.", nil)];
    [self.instanceStatusStartedImageView setHidden:YES];
    [self.instanceStatusStoppedImageView setHidden:NO];
    self._isStarted = NO;    
}

- (BOOL)_startProcess
{
    NSString *processPath = [self _findBinaryNamed:@"mongod"];
    if (processPath == nil)
        return NO;
    NSMutableArray *configPathArray = [[processPath pathComponents] mutableCopy];
    [configPathArray replaceObjectAtIndex:[configPathArray count] - 2  withObject:@"etc"];
    [configPathArray replaceObjectAtIndex:[configPathArray count] - 1  withObject:@"mongod.conf"];
    NSString *configPath = [NSString pathWithComponents:configPathArray];
    NSString *logPath = [@"~/Library/Logs/mongod.log" stringByExpandingTildeInPath];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:processPath arguments:[NSArray arrayWithObjects:@"run", @"--fork", @"--logpath", logPath, @"--config", configPath, nil]];
    [task waitUntilExit];
    BOOL isStarted = [self _isRunningProcessNamed:@"mongod"];
    if (isStarted == YES)
        NSLog(@"[STARTED]%@ run --fork --logpath %@ --config %@", processPath, logPath, configPath);
    else
        NSLog(@"[FAILED]%@ run --fork --logpath %@ --config %@", processPath, logPath, configPath);
    return isStarted;
}

- (BOOL)_stopProcess
{
    NSArray *pidList = [self _pidListForProcessesNamed:@"mongod"];
    for (NSNumber *pid in pidList) {
        if (kill([pid intValue], SIGINT) == -1) {
            NSLog(@"[STOPPED]Process %@ not terminating properly, sending SIGKILL...", pid);
            kill([pid intValue], SIGKILL);
        }
        NSLog(@"[STOPPED]Process %@ terminated.", pid);
    }
    return YES;
}

@end
