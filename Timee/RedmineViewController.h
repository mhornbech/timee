//
//  RedmineViewController.h
//  Timee
//
//  Created by Morten Hornbech on 06/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivitiesViewController.h"
#import "RedmineSettingsViewController.h"
#import "SelectRegistrationsViewController.h"

@class RedmineViewController;

@protocol RedmineViewControllerDelegate

- (void)redmineViewControllerDidFinish:(RedmineViewController *)controller; 

@end

@class RedmineView;

@interface RedmineViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, TimerViewControllerDelegate, ActivitiesViewControllerDelegate, UITextFieldDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) RedmineView *redmineView;
@property (strong, nonatomic) NSArray *timerTableRows;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSDate *endTime;
@property (strong, nonatomic) NSArray *sections;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UITableViewCell *cell;
@property (strong, nonatomic) NSURL *serverUrl;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSMutableURLRequest *request;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) NSMutableDictionary *alertsByIssueId;
@property (strong, nonatomic) NSURLConnection *currentConnection;
@property (strong, nonatomic) NSDictionary *xmlCharacterMap;
@property (assign, nonatomic) id<RedmineViewControllerDelegate> cancelDelegate;
@property (assign, nonatomic) id<SelectRegistrationsViewControllerDelegate> doneDelegate;

- (IBAction)cancel;
- (IBAction)done;

- (void)refreshSettings;
- (void)enableUserInteraction;
- (void)disableUserInteraction;

@end
