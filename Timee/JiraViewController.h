//
//  JiraViewController.h
//  Timee
//
//  Created by Morten Hornbech on 06/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivitiesViewController.h"
#import "JiraSettingsViewController.h"
#import "SelectRegistrationsViewController.h"

@class JiraViewController;

@protocol JiraViewControllerDelegate

- (void)jiraViewControllerDidFinish:(JiraViewController *)controller; 

@end

@class JiraView;

@interface JiraViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, TimerViewControllerDelegate, UITextFieldDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) JiraView *jiraView;
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
@property (assign, nonatomic) id<JiraViewControllerDelegate> cancelDelegate;
@property (assign, nonatomic) id<SelectRegistrationsViewControllerDelegate> doneDelegate;

- (IBAction)cancel;
- (IBAction)done;

- (void)refreshSettings;
- (void)enableUserInteraction;
- (void)disableUserInteraction;
- (void)setAuthenticationHeader:(NSMutableURLRequest *)request;

@end
