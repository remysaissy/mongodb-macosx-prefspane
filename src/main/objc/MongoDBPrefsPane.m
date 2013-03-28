//
//  mongodb.m
//  mongodb
//
//  Created by Rémy SAISSY on 20/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "MongoDBPrefsPane.h"
#import "AutoUpdater.h"
#import "ServiceControl.h"

//Redefine it since mainBundle refers to the system preferences app and not to our prefspane.
#undef NSLocalizedString
#define NSLocalizedString(key, comment) \
[[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:nil]

@interface MongoDBPrefsPane()

//The last state of the server which is displayed on the UI.
@property (assign, nonatomic) BOOL  _isStarted;

//The autoupdater instance.
@property (strong, nonatomic) AutoUpdater   *_autoUpdater;

//Instance of the service control for the prefs pane.
@property (strong, nonatomic) ServiceControl    *_serviceControl;

//Configure the UI with the process started.
- (void)_setProcessAsStarted;

//Configure the UI with the process stopped.
- (void)_setProcessAsStopped;

@end

@implementation MongoDBPrefsPane

@synthesize instanceStatusStoppedImageView;
@synthesize instanceStatusStartedImageView;
@synthesize instanceStatusDescriptionTextField;
@synthesize panelUpdatedTextField;
@synthesize instanceStatusTextField;
@synthesize instanceStartStopButton;
@synthesize instanceAutomaticStartButton;

//Private properties.
@synthesize _isStarted;
@synthesize _autoUpdater;
@synthesize _serviceControl;

#pragma mark - Service control delegate methods.

- (NSString *)processNameForServiceControl:(ServiceControl *)serviceControl
{
    return @"mongod";
}

- (NSArray *)getAlternativeLaunchDaemonNameArrayForServiceControl:(ServiceControl *)serviceControl
{
    return [NSArray arrayWithObjects:@"homebrew.mxcl.mongodb",
//            This is the old name of the prefspane configuration plist.
                            @"com.remysaissy.mongodbprefspane",
                            nil];
}

#pragma mark - AutoUpdater delegate methods.

- (NSURL *)checkLatestVersionURLForAutoUpdater:(AutoUpdater *)autoUpdater
{
    return [NSURL URLWithString:@"https://github.com/remysaissy/mongodb-macosx-prefspane/raw/master/download/LATEST_VERSION"];
}

- (NSURL *)downloadLatestVersionURLForAutoUpdater:(AutoUpdater *)autoUpdater
{
    return [NSURL URLWithString:@"https://github.com/remysaissy/mongodb-macosx-prefspane/raw/master/download/MongoDB.prefPane.zip"];
}

#pragma mark - Lifecycle.

- (void)mainViewDidLoad
{
    self._serviceControl = [[ServiceControl alloc] init];
    self._serviceControl.delegate = self;
    self._autoUpdater = [[AutoUpdater alloc] init];
//    Show the update notification when an update has been downloaded and installed.
    [self._autoUpdater addObserver:self forKeyPath:@"hasUpdated" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)didSelect
{
    if ([self._serviceControl isProcessRunning] == YES)
        [self _setProcessAsStarted];
    else
        [self _setProcessAsStopped];
    
    [self.instanceAutomaticStartButton setState:[self._serviceControl isAutomaticStartupInstalled]];
    [self._autoUpdater checkForUpdate];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{    
    if (object == self._autoUpdater 
        && [@"hasUpdated" isEqualToString:keyPath]        
        && self._autoUpdater.hasUpdated == YES) {
        [self.panelUpdatedTextField setHidden:NO];
    }
}

#pragma mark - UI Actions.

- (IBAction)onStartStopButtonPushed:(id)sender
{
    if (self._isStarted == YES) {
        if ([self._serviceControl stopProcess] == YES)
            [self _setProcessAsStopped];        
    } else {
        if ([self._serviceControl startProcess] == YES)
            [self _setProcessAsStarted];
    }
}

- (IBAction)onAutomaticStartButtonPushed:(id)sender
{
    if (self.instanceAutomaticStartButton.state) {
        if ([self._serviceControl installAutomaticStartup] == YES)
            [self.instanceAutomaticStartButton setState:[self._serviceControl isAutomaticStartupInstalled]];
    } else {
        if ([self._serviceControl uninstallAutomaticStartup] == YES)
            [self.instanceAutomaticStartButton setState:[self._serviceControl isAutomaticStartupInstalled]];
    }
    if ([self._serviceControl isProcessRunning] == YES)
        [self _setProcessAsStarted];
    else 
        [self _setProcessAsStopped];
}

#pragma mark - Private methods.

- (void)_setProcessAsStarted
{    
    [self.instanceStatusTextField setStringValue:NSLocalizedString(@"started", nil)];
    [self.instanceStatusTextField setTextColor:[NSColor greenColor]];
    [self.instanceStartStopButton setTitle:NSLocalizedString(@"Stop MongoDB Server", nil)];
    [self.instanceStatusDescriptionTextField setStringValue:NSLocalizedString(@"The MongoDB Database Server is currently started. To stop it, use the \"Stop MongoDB Server\" button.", nil)];    
    [self.instanceStatusStartedImageView setHidden:NO];
    [self.instanceStatusStoppedImageView setHidden:YES];
    self._isStarted = YES;
}

- (void)_setProcessAsStopped
{
    [self.instanceStatusTextField setStringValue:NSLocalizedString(@"stopped", nil)];
    [self.instanceStatusTextField setTextColor:[NSColor redColor]];
    [self.instanceStartStopButton setTitle:NSLocalizedString(@"Start MongoDB Server", nil)];
    [self.instanceStatusDescriptionTextField setStringValue:NSLocalizedString(@"The MongoDB Database Server is currently stopped. To start it, use the \"Start MongoDB Server\" button.", nil)];
    [self.instanceStatusStartedImageView setHidden:YES];
    [self.instanceStatusStoppedImageView setHidden:NO];
    self._isStarted = NO;    
}

@end
