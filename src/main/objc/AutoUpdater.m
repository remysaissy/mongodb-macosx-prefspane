//
//  AutoUpdater.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 24/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "AutoUpdater.h"

enum AutoUpdateSteps 
{
    AutoUpdateStepCheckLatest,
    AutoUpdateStepDownloadLatest
};

@interface AutoUpdater()

//The data received from the network connection.
@property (retain, nonatomic) NSMutableData *_data;

//The update step.
@property (assign, nonatomic) enum AutoUpdateSteps _updateStep;

//Called to process the end of a check update call. It might trigger a download call.
- (void)_checkingUpdateDidFinish;

//Called when the nwe binary has been downloaded. It will replace the old binary.
- (void)_downloadingUpdateDidFinish;

@end

@implementation AutoUpdater

@synthesize _data;
@synthesize _updateStep;

- (void)checkForUpdate
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://github.com/remysaissy/mongodb-macosx-prefspane/raw/master/download/LATEST_VERSION"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:6];
    self._updateStep = AutoUpdateStepCheckLatest;
    self._data = nil;
    NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode != 200 || httpResponse.statusCode != 201) {
        self._data = nil;
        [connection cancel];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!self._data)
        self._data = [NSMutableData dataWithData:data];
    else 
        [self._data appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self._updateStep == AutoUpdateStepCheckLatest)
        [self _checkingUpdateDidFinish];
    else
        [self _downloadingUpdateDidFinish];    
}

#pragma mark - Private methods.

- (void)_checkingUpdateDidFinish
{
    NSNumberFormatter * f = [[[NSNumberFormatter alloc] init] autorelease];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    [f setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]]; 
    
    NSString *versionString = [[[NSBundle bundleForClass:[AutoUpdater class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSNumber *versionNumber = [f numberFromString:versionString];
    
    NSString *latestVersionString = [[[NSString alloc] initWithData:self._data encoding:NSUTF8StringEncoding] autorelease];
    NSNumber *latestVersionNumber = [f numberFromString:latestVersionString];
    self._data = nil;
    
    if ([versionNumber floatValue] < [latestVersionNumber floatValue]) {
        [NSString logInfoFromClass:[self class] withSelector:_cmd withFormat:@"A new version (%@) has been found. Downloading...", latestVersionNumber];
        self._updateStep = AutoUpdateStepDownloadLatest;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://github.com/remysaissy/mongodb-macosx-prefspane/raw/master/download/MongoDB.prefPane.zip"]];
        self._updateStep = AutoUpdateStepCheckLatest;
        self._data = nil;
        NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];
        [connection start];        
    }    
}

- (void)_downloadingUpdateDidFinish
{
    NSString *prefsPanePath = [[NSBundle bundleForClass:[self class]] bundlePath];
    NSLog(@"PrefsPanePath: %@.", prefsPanePath);
}


@end
