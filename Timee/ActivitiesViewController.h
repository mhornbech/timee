//
//  ActivitiesViewController.h
//  Timee
//
//  Created by Morten Hornbech on 06/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ActivitiesViewController;

@protocol ActivitiesViewControllerDelegate

- (void)activitiesViewControllerDidFinish:(ActivitiesViewController *)controller; 

@end

@class ActivitiesView;
@class RedmineInfo;
@class RedmineViewController;

@interface ActivitiesViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) ActivitiesView *activitiesView;
@property (strong, nonatomic) NSDictionary *activitiesById;
@property (strong, nonatomic) NSArray *sortedIds;
@property (strong, nonatomic) RedmineInfo *redmine;
@property (assign, nonatomic) RedmineViewController *redmineViewController;

- (IBAction)refreshActivities;
- (IBAction)cancel;

@end
