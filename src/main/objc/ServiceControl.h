//
//  ServiceControl.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 21/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ServiceControl;

@protocol ServiceControlDelegate <NSObject>

@required

//The name of the process to find.
- (NSString *)processNameForServiceControl:(ServiceControl *)serviceControl;

@optional

//Returns a list of the alternative launch daemons.
- (NSArray *)getAlternativeLaunchDaemonNameArrayForServiceControl:(ServiceControl *)serviceControl;

@end

@interface ServiceControl : NSObject

//Delegate required for the service control to work.
@property (assign, nonatomic) id<ServiceControlDelegate>    delegate;

#pragma mark - Process related methods.

//Blocking call to start the process and returns YES in case of success.
- (BOOL)startProcess;

//Blocking call to stop the process and returns YES in case of success.
- (BOOL)stopProcess;

//Check if their is a running process (and not only application) named processName.
- (BOOL)isProcessRunning;

//Return the list of locations where the process has been detected on the system.
- (NSArray *)getProcessLocationsList;

#pragma mark - Launchd related methods.

//Check if the launch agent is installed.
- (BOOL)isAutomaticStartupInstalled;

//Install the launch agent.
- (BOOL)installAutomaticStartup;

//Removes the launch agent.
- (BOOL)uninstallAutomaticStartup;

//Returns the launch daemon plist name (which is also the filename without the .plist extension).
- (NSString *)launchDaemonName;

//Returns the launch daemon plist fullpath.
- (NSString *)launchDaemonPath;

@end
