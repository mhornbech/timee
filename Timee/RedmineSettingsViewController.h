//
//  RedmineSettingsViewController.h
//  Timee
//
//  Created by Morten Hornbech on 22/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedmineViewController.h"

@class RedmineSettingsViewController;

@protocol RedmineSettingsViewControllerDelegate

- (void)redmineSettingsViewControllerDidFinish:(RedmineSettingsViewController *)controller; 

@end

@class RedmineSettingsView, RedmineViewController;

@interface RedmineSettingsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) RedmineSettingsView *redmineSettingsView;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) UITextField *textFieldBeingEdited;
@property (nonatomic, strong) RedmineViewController *redmineViewController;
@property (nonatomic, assign) id<RedmineSettingsViewControllerDelegate> delegate;

- (IBAction)cancel;
- (IBAction)done;
- (NSString *)userDefaultsKeyForIndexPath:(NSIndexPath *)indexPath;

@end
