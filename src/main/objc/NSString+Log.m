//
//  NSString+Log.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 23/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "NSString+Log.h"

static NSString * const loggingFile = @"~/Library/Logs/mongodb-prefspane.log";

@implementation NSString (Log)

+ (void)logInfoFromClass:(Class)class withSelector:(SEL)selector withFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4)
{
    va_list ap;
    va_start(ap, format);
    NSString *logMessage = [NSString stringWithFormat:@"[INFO]%@:%@::%@", NSStringFromClass(class), NSStringFromSelector(selector), 
                            [[[NSString alloc] initWithFormat:format arguments:ap] autorelease]];
    va_end(ap);
    NSLog(@"%@", logMessage);
}

+ (void)logErrorFromClass:(Class)class withSelector:(SEL)selector withFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4)
{
    va_list ap;
    va_start(ap, format);
    NSString *logMessage = [NSString stringWithFormat:@"[ERROR]%@:%@::%@", NSStringFromClass(class), NSStringFromSelector(selector), 
                            [[[NSString alloc] initWithFormat:format arguments:ap] autorelease]];
    va_end(ap);
    NSLog(@"%@", logMessage);
}

@end
