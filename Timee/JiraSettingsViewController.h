//
//  JiraSettingsViewController.h
//  Timee
//
//  Created by Morten Hornbech on 22/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JiraViewController.h"

@class JiraSettingsViewController;

@protocol JiraSettingsViewControllerDelegate

- (void)jiraSettingsViewControllerDidFinish:(JiraSettingsViewController *)controller; 

@end

@class JiraSettingsView, JiraViewController;

@interface JiraSettingsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) JiraSettingsView *jiraSettingsView;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) UITextField *textFieldBeingEdited;
@property (nonatomic, strong) JiraViewController *jiraViewController;
@property (nonatomic, assign) id<JiraSettingsViewControllerDelegate> delegate;

- (IBAction)cancel;
- (IBAction)done;
- (NSString *)userDefaultsKeyForIndexPath:(NSIndexPath *)indexPath;

@end
