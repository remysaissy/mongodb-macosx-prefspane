//
//  AutoUpdater.m
//  MongoDB-PrefsPane
//
//  Created by Rémy SAISSY on 24/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "AutoUpdater.h"
#import "Helpers+Private.h"

enum AutoUpdateSteps 
{
    AutoUpdateStepIdle,
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

@synthesize hasUpdated;

@synthesize _data;
@synthesize _updateStep;


- (void)setHasUpdated:(BOOL)value
{
    [self willChangeValueForKey:@"hasUpdated"];
    hasUpdated = value;
    [self didChangeValueForKey:@"hasUpdated"];
}

- (id)init
{
    self = [super init];
    if (self) {
        _updateStep = AutoUpdateStepIdle;    
        hasUpdated = NO;
    }
    return self;
}

- (void)checkForUpdate
{
    if (self._updateStep != AutoUpdateStepIdle)
        return;
    self.hasUpdated = NO;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://github.com/remysaissy/mongodb-macosx-prefspane/raw/master/download/LATEST_VERSION"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:6];
    self._updateStep = AutoUpdateStepCheckLatest;
    self._data = nil;
    NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode != 200 && httpResponse.statusCode != 201) {    
        self._updateStep = AutoUpdateStepIdle;        
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


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self._updateStep = AutoUpdateStepIdle;
    self._data = nil;
    [NSString logErrorFromClass:[self class] withSelector:_cmd withFormat:@"Failed to check for an update: %@.", error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self._updateStep == AutoUpdateStepCheckLatest)
        [self _checkingUpdateDidFinish];
    else if (self._updateStep == AutoUpdateStepDownloadLatest)
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
    latestVersionString = [latestVersionString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t\n "]];
    NSNumber *latestVersionNumber = [f numberFromString:latestVersionString];
    self._updateStep = AutoUpdateStepIdle;    
    self._data = nil;
    
    if ([versionNumber floatValue] < [latestVersionNumber floatValue]) {
        [NSString logInfoFromClass:[self class] withSelector:_cmd withFormat:@"A new version (%@) has been found. Downloading...", latestVersionNumber];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://github.com/remysaissy/mongodb-macosx-prefspane/raw/master/download/MongoDB.prefPane.zip"]];
        self._updateStep = AutoUpdateStepDownloadLatest;
        NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];
        [connection start];        
    }    
}

- (void)_downloadingUpdateDidFinish
{
    [NSString logInfoFromClass:[self class] withSelector:_cmd withFormat:@"Installing new version..."];
    NSString *prefsPaneBinary = [[NSBundle bundleForClass:[self class]] bundlePath];
    NSString *prefsPanePath = [prefsPaneBinary stringByDeletingLastPathComponent];
    NSString *updatedBinaryZipped = [NSTemporaryDirectory() stringByAppendingPathComponent:@"MongoDB.prefPane.zip"];
    NSString *updatedBinaryPath = [updatedBinaryZipped stringByDeletingLastPathComponent];    
    NSString *updatedBinary = [updatedBinaryZipped stringByDeletingPathExtension];
    [self._data writeToFile:updatedBinaryZipped atomically:YES];
    self._updateStep = AutoUpdateStepIdle;    
    self._data = nil;
    NSTask *task = [NSTask launchedTaskWithLaunchPath:[Helpers _findBinaryNamed:@"unzip"] arguments:[NSArray arrayWithObjects:@"-o", updatedBinaryZipped, @"-d", updatedBinaryPath, nil]];
    [task waitUntilExit];
    if (!task.terminationStatus) {
        NSString *cpTool = [Helpers _findBinaryNamed:@"cp"];
        task = [NSTask launchedTaskWithLaunchPath:cpTool arguments:[NSArray arrayWithObjects:@"-vfR", updatedBinary, prefsPanePath, nil]];
        [task waitUntilExit];
        if (task.terminationStatus) {
            AuthorizationRef authorizationRef;
            AuthorizationRights rights;            
            AuthorizationFlags flags;            
            OSStatus status;
            AuthorizationItem items[1];
            items[0].name = kAuthorizationRightExecute;            
            items[0].value = (char *)[cpTool UTF8String];            
            items[0].valueLength = cpTool.length;
            items[0].flags = 0;
            rights.count = 1;
            rights.items = items;
            flags = kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
            AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &authorizationRef);            
            status = AuthorizationCopyRights(authorizationRef, &rights, kAuthorizationEmptyEnvironment, flags, NULL);
            if (status == errAuthorizationSuccess) {
                char *arguments[4];
                arguments[0] = "-vfR";
                arguments[1] = (char *)[updatedBinary UTF8String];
                arguments[2] = (char *)[prefsPanePath UTF8String];
                status = AuthorizationExecuteWithPrivileges(authorizationRef, [cpTool UTF8String], 0, arguments, nil);
                if (status)
                    return;
            }
            AuthorizationFree(authorizationRef, 0);
        }
        [NSString logInfoFromClass:[self class] withSelector:_cmd withFormat:@"New version installed in %@.", prefsPanePath];
        self.hasUpdated = YES;
    }
}


@end
