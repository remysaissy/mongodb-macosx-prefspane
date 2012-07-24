//
//  AutoUpdater.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 24/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoUpdater : NSObject

//Check for a new version.
+ (void)checkForUpdate;

@end
