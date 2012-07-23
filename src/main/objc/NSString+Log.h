//
//  NSString+Log.h
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 23/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Log)

//Log informational message.
+ (void)logInfoFromClass:(Class)class withSelector:(SEL)selector withFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4);

//Log error message.
+ (void)logErrorFromClass:(Class)class withSelector:(SEL)selector withFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4);

@end
