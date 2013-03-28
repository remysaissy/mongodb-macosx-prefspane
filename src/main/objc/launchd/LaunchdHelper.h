//
//  LaunchdHelper.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 24/03/13.
//  Copyright (c) 2013 Octo Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LaunchdHelper : NSObject

//Check if a give Agent is running.
+ (BOOL)isAgentRunning:(NSString *)agentName;

//Start an already installed Agent.
+ (BOOL)startAgentNamed:(NSString *)agentName;

//Stop a running Agent.
+ (BOOL)stopAgentNamed:(NSString *)agentName;

//Check if the Agent is installed.
+ (BOOL)isAgentInstalled:(NSString *)agentName;

//Install a Agent in ~/Library/LaunchAgents with the given conf.
+ (BOOL)installAgentNamed:(NSString *)agentName withConfig:(NSDictionary *)conf atFullPath:(NSString *)agentInstallPath;

//Enable an Agent.
+ (BOOL)enableAgentNamed:(NSString *)agentName atFullPath:(NSString *)agentInstallPath;

//Uninstall an Agent.
+ (BOOL)uninstallAgentNamed:(NSString *)agentName;

@end
