//
//  mongodb.h
//  mongodb
//
//  Created by Rémy SAISSY on 20/07/12.
//  Copyright (c) 2012 Octo Technology. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface MongoDBPrefsPane : NSPreferencePane

//The wheel which visually indicates if the server is started of not.
@property (retain, nonatomic) IBOutlet NSImageView  *instanceStatusImageView;

// The description text of the server status.
@property (retain, nonatomic) IBOutlet NSTextField  *instanceStatusDescriptionTextField;

//Displayed in green or red in the UI. Can be either started or stopped.
@property (retain, nonatomic) IBOutlet NSTextField  *instanceStatusTextField;

//Button press to start or stop the MongoDB server and updates the relevant textfields and images.
@property (retain, nonatomic) IBOutlet NSButton     *instanceStartStopButton;

// Checkbox pressed to install or remove the launchctl daemon.
@property (retain, nonatomic) IBOutlet NSButton     *instanceAutomaticStartButton;

//Performs first time checks to configure the UI elements.
- (void)mainViewDidLoad;

//Starts or stops the MongoDB server and updates the relevant textfields and images.
- (IBAction)onStartStopButtonPushed:(id)sender;

//Installs or removes the launchctl daemon.
- (IBAction)onAutomaticStartButtonPushed:(id)sender;

@end
