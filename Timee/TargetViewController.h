//
//  TargetViewController.h
//  Timee
//
//  Created by Morten Hornbech on 06/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JiraViewController.h"
#import "JiraSettingsViewController.h"
#import "SelectRegistrationsViewController.h"
#import "RedmineViewController.h"
#import "RedmineSettingsViewController.h"

#import <StoreKit/StoreKit.h>

@class TargetViewController;

@protocol TargetViewControllerDelegate

- (void)targetViewControllerDidFinish:(TargetViewController *)controller; 

@end

@class TargetView;

@interface TargetViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, RedmineViewControllerDelegate, JiraViewControllerDelegate, RedmineSettingsViewControllerDelegate, JiraSettingsViewControllerDelegate>

@property (strong, nonatomic) TargetView *targetView;
@property (strong, nonatomic) NSString *csvFilePath;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSSet *selectedRows;
@property (strong, nonatomic) NSArray *timerTableRows;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSDate *endTime;
@property (strong, nonatomic) NSArray *sections;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (assign, nonatomic) id<TargetViewControllerDelegate> cancelDelegate;
@property (assign, nonatomic) id<SelectRegistrationsViewControllerDelegate> doneDelegate;

- (IBAction)cancel;

- (void)exportToCsv;
- (void)showRedmine;
- (void)showJira;
- (NSString *)getHeaders;
- (NSString *)getComponentsForRegistration:(Registration *)registration;
- (void)exportFileToMailApplication;
- (NSArray *)getSelectedRows;

@end
