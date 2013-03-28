//
//  Adapter.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 24/03/13.
//  Copyright (c) 2013 Octo Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AdapterProtocol.h"

@interface Adapter : NSObject

//The process on which the adapter works.
@property (strong, nonatomic) NSString *processName;

//Returns the path for the adapter.
- (NSString *)getPath;

// Returns the process fullpath.
- (NSString *)getProcessFullPath;

//Returns the manual start command line argument for a given process.
- (NSArray *)getManualStartArguments;

//Returns the configuration file path.
- (NSString *)getConfigurationFileFullPath;

//Returns the launchd name of the adapter.
- (NSString *)getLaunchdName;

//Returns the launchd fullpath of the adapter.
- (NSString *)getLaunchdFullPath;

//Returns the log file path.
- (NSString *)getLogFileFullPath;

//Returns the launchd plist for the process as an NSDictionary.
- (NSDictionary *)getLaunchdArgumentsDictionary;

@end
