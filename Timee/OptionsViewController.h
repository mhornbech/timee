//
//  OptionsViewController.h
//  Timee
//
//  Created by Morten Hornbech on 06/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "TimerViewController.h"
#import "SelectRegistrationsViewController.h"
#import "RegistrationTableViewController.h"
#import "TutorialViewController.h"
#import <MessageUI/MessageUI.h>

@class OptionsView;
@class OptionsViewController;

@protocol OptionsViewControllerDelegate

- (void)optionsViewControllerDidFinish:(OptionsViewController *)controller;

@end

@interface OptionsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, RegistrationTableViewControllerDelegate, TimerViewControllerDelegate, SelectRegistrationsViewControllerDelegate, TutorialViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (assign, nonatomic) IBOutlet id<OptionsViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UITableViewCell *cell;
@property (strong, nonatomic) IBOutlet OptionsView *optionsView;

- (IBAction)done:(id)sender;
- (IBAction)showAddTimer;
- (IBAction)showRegistrations;
- (IBAction)showExportData;
- (IBAction)showDeleteData;
- (IBAction)showTutorial;

@end
