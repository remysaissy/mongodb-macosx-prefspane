//
//  Helpers+Launchd.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 22/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "Helpers.h"

@interface Helpers (Launchd)

// Start and fork the mongod process.
+ (BOOL)_startProcessWithAutomaticStartup;

// Stop a forked mongod process.
+ (BOOL)_stopProcessWithAutomaticStartup;

//Install mongod in launchd.
+ (BOOL)_installLaunchd;

//Uninstall mongod from launchd.
+ (BOOL)_uninstallLaunchd;

@end
