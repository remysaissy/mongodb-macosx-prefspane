//
//  mongodb.h
//  mongodb
//
//  Created by Rémy SAISSY on 20/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import "ServiceControl.h"
#import "AutoUpdater.h"

@interface MongoDBPrefsPane : NSPreferencePane <ServiceControlDelegate, AutoUpdaterDelegate>

//The wheel which visually indicates if the server is started of not.
@property (strong, nonatomic) IBOutlet NSImageView  *instanceStatusStoppedImageView;
@property (strong, nonatomic) IBOutlet NSImageView  *instanceStatusStartedImageView;

//Label asking the user restart its preferences.
@property (strong, nonatomic) IBOutlet NSTextField  *panelUpdatedTextField;

// The description text of the server status.
@property (strong, nonatomic) IBOutlet NSTextField  *instanceStatusDescriptionTextField;

//Displayed in green or red in the UI. Can be either started or stopped.
@property (strong, nonatomic) IBOutlet NSTextField  *instanceStatusTextField;

//Button press to start or stop the MongoDB server and updates the relevant textfields and images.
@property (strong, nonatomic) IBOutlet NSButton     *instanceStartStopButton;

// Checkbox pressed to install or remove the launchctl daemon.
@property (strong, nonatomic) IBOutlet NSButton     *instanceAutomaticStartButton;

//Performs first time checks to configure the UI elements.
- (void) didSelect;

//Starts or stops the MongoDB server and updates the relevant textfields and images.
- (IBAction)onStartStopButtonPushed:(id)sender;

//Installs or removes the launchctl daemon.
- (IBAction)onAutomaticStartButtonPushed:(id)sender;

@end
