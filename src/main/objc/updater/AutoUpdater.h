//
//  AutoUpdater.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 24/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AutoUpdater;

@protocol AutoUpdaterDelegate <NSObject>

@required

//Returns the URL to check the latest version.
- (NSURL *)checkLatestVersionURLForAutoUpdater:(AutoUpdater *)autoUpdater;

//Returns the URL to retrieve the binary's latest version.
- (NSURL *)downloadLatestVersionURLForAutoUpdater:(AutoUpdater *)autoUpdater;

@end

@interface AutoUpdater : NSObject<NSURLConnectionDelegate>

//Delegate which give informations about the remote server to contact.
@property (assign, nonatomic) id<AutoUpdaterDelegate> delegate;

//YES if a new version has been installed.
@property (assign, nonatomic) BOOL  hasUpdated;

//Check for a new version.
- (void)checkForUpdate;

@end
