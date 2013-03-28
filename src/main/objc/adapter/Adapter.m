//
//  Adapter.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 24/03/13.
//  Copyright (c) 2013 Octo Technology. All rights reserved.
//

#import "Adapter.h"

#import "HomeBrewAdapter.h"
#import "MacPortsAdapter.h"

@interface Adapter()

//The adapter in use.
@property (strong, nonatomic) id<AdapterProtocol>   _currentAdapter;

//Find an adapter for _currentAdapter.
- (BOOL)_findAdapter;

@end

@implementation Adapter

@synthesize processName;
@synthesize _currentAdapter;

- (NSString *)getPath
{
    NSString *path = nil;
    if (self._currentAdapter != nil
        || [self _findAdapter] == YES) {
        path = [[self._currentAdapter class] getPath];
    }
    return path;
}

- (NSString *)getProcessFullPath
{
    NSString *result = nil;
    if (self._currentAdapter != nil
        || [self _findAdapter] == YES) {
        result = [[self._currentAdapter class] getProcessFullPathForProcessNamed:self.processName];
    }
    return result;
}

- (NSArray *)getManualStartArguments
{
    NSArray *result = nil;
    if (self._currentAdapter != nil
        || [self _findAdapter] == YES) {
        result = [self._currentAdapter getManualStartArgumentsForProcessNamed:self.processName];
    }
    return result;
}

- (NSArray *)getAutomaticStartArguments
{
    NSArray *result = nil;
    if (self._currentAdapter != nil
        || [self _findAdapter] == YES) {
        result = [self._currentAdapter getAutomaticStartArgumentsForProcessNamed:self.processName];
    }
    return result;
}

- (NSString *)getConfigurationFileFullPath
{
    NSString *result = nil;
    if (self._currentAdapter != nil
        || [self _findAdapter] == YES) {
        result = [self._currentAdapter getConfigurationFileFullPathForProcessNamed:self.processName];
    }
    return result;
}

- (NSString *)getLogFileFullPath
{
    NSString *result = nil;
    if (self._currentAdapter != nil
        || [self _findAdapter] == YES) {
        result = [self._currentAdapter getLogFileFullPathForProcessNamed:self.processName];
    }
    return result;
}

- (NSString *)getLaunchdFullPath
{
    NSString *result = nil;
    if (self._currentAdapter != nil
        || [self _findAdapter] == YES) {
        result = [self._currentAdapter getLaunchdFullPathForProcessNamed:self.processName];
    }
    return result;
}

- (NSString *)getLaunchdName
{
    NSString *result = nil;
    if (self._currentAdapter != nil
        || [self _findAdapter] == YES) {
        result = [self._currentAdapter getLaunchdNameForProcessNamed:self.processName];
    }
    return result;
}

- (NSDictionary *)getLaunchdArgumentsDictionary
{
    NSDictionary *result = nil;
    if (self._currentAdapter != nil
        || [self _findAdapter] == YES) {
        result = [self._currentAdapter getLaunchdArgumentsDictionaryForProcessNamed:self.processName];
    }
    return result;
}

#pragma mark - Private methods.

- (BOOL)_findAdapter
{
    BOOL result = NO;
    if (self.processName != nil) {
        if ([HomeBrewAdapter isActiveForProcessNamed:self.processName]) {
            self._currentAdapter = [[HomeBrewAdapter alloc] init];
            result = YES;
        } else if ([MacPortsAdapter isActiveForProcessNamed:self.processName]) {
            self._currentAdapter = [[MacPortsAdapter alloc] init];
            result = YES;            
        }
    }
    return result;
}

@end
