//
//  AutoUpdater.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 24/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "AutoUpdater.h"

@implementation AutoUpdater

+ (void)checkForUpdate
{
    NSString *versionString = [[[NSBundle bundleForClass:[AutoUpdater class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSNumberFormatter * f = [[[NSNumberFormatter alloc] init] autorelease];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    [f setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]]; 
    NSNumber *versionNumber = [f numberFromString:versionString];
    
}

@end
