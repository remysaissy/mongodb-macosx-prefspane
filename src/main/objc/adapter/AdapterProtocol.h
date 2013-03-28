//
//  AdapterProtocol.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 21/03/13.
//  Copyright (c) 2013 Octo Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AdapterProtocol <NSObject>

@required

//Returns the manual start command line argument for a given process.
- (NSArray *)getManualStartArgumentsForProcessNamed:(NSString *)processName;

//Returns the automatic start command line argument for a given process.
- (NSArray *)getAutomaticStartArgumentsForProcessNamed:(NSString *)processName;

//Returns the configuration file path.
- (NSString *)getConfigurationFileFullPathForProcessNamed:(NSString *)processName;

//Returns the log file path.
- (NSString *)getLogFileFullPathForProcessNamed:(NSString *)processName;

//Returns the launchd fullpath of the adapter.
- (NSString *)getLaunchdFullPathForProcessNamed:(NSString *)processName;

//Returns the launchd name of the adapter.
- (NSString *)getLaunchdNameForProcessNamed:(NSString *)processName;

//Returns the launchd plist for the process as an NSDictionary.
- (NSDictionary *)getLaunchdArgumentsDictionaryForProcessNamed:(NSString *)processName;

//Returns the path for the adapter.
+ (NSString *)getPath;

// Returns the process fullpath.
+ (NSString *)getProcessFullPathForProcessNamed:(NSString *)processName;

//Check if the process is available.
+ (BOOL)isActiveForProcessNamed:(NSString *)processName;

@end
