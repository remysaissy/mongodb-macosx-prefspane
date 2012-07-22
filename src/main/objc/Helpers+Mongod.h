//
//  Helpers+Mongod.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 22/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "Helpers.h"

@interface Helpers (Mongod)

// Start and fork the mongod process.
+ (BOOL)_startMongodProcess;

// Stop a forked mongod process.
+ (BOOL)_stopMongodProcess;

@end
