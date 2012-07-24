//
//  mongodb.m
//  mongodb
//
//  Created by Rémy SAISSY on 20/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import "MongoDBPrefsPane.h"
#import "AutoUpdater.h"
#import "Helpers.h"

@interface MongoDBPrefsPane()

//The last state of the server which is displayed on the UI.
@property (assign, nonatomic) BOOL  _isStarted;

//Configure the UI with the process started.
- (void)_setProcessAsStarted;

//Configure the UI with the process stopped.
- (void)_setProcessAsStopped;

@end

@implementation MongoDBPrefsPane

@synthesize instanceStatusStoppedImageView;
@synthesize instanceStatusStartedImageView;
@synthesize instanceStatusDescriptionTextField;
@synthesize instanceStatusTextField;
@synthesize instanceStartStopButton;
@synthesize instanceAutomaticStartButton;

//Private properties.
@synthesize _isStarted;

- (void)didSelect
{    
    if ([Helpers isProcessRunning] == YES)
        [self _setProcessAsStarted];
    else
        [self _setProcessAsStopped];
    
    [self.instanceAutomaticStartButton setState:[Helpers isAutomaticStartupInstalled]];
    [AutoUpdater checkForUpdate];
}

- (IBAction)onStartStopButtonPushed:(id)sender
{
    if (self._isStarted == YES) {
        if ([Helpers stopProcess] == YES)
            [self _setProcessAsStopped];        
    } else {
        if ([Helpers startProcess] == YES)
            [self _setProcessAsStarted];
    }
}

- (IBAction)onAutomaticStartButtonPushed:(id)sender
{
    if (self.instanceAutomaticStartButton.state) {
        if ([Helpers installAutomaticStartup] == YES)
            [self.instanceAutomaticStartButton setState:[Helpers isAutomaticStartupInstalled]];
    } else {
        if ([Helpers uninstallAutomaticStartup] == YES)
            [self.instanceAutomaticStartButton setState:[Helpers isAutomaticStartupInstalled]];
    }
    if ([Helpers isProcessRunning] == YES)
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
