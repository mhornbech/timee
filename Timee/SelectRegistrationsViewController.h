//
//  SelectRegistrationViewController.h
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

@class SelectRegistrationsViewController;

@protocol SelectRegistrationsViewControllerDelegate

- (void)selectRegistrationsViewControllerDidFinish:(SelectRegistrationsViewController *)controller; 

@end

#import "TimerViewController.h"

@class Registration;
@class SelectRegistrationsView;

@interface SelectRegistrationsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, TimerViewControllerDelegate>

@property (assign, nonatomic) id<SelectRegistrationsViewControllerDelegate> delegate;
@property (strong, nonatomic) NSDate *endTime;
@property (strong, nonatomic) SelectRegistrationsView *selectRegistrationsView;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) IBOutlet UITableViewCell *cell;
@property (strong, nonatomic) NSMutableSet *selectedRows;
@property (strong, nonatomic) UILabel *daysLabel;
@property (strong, nonatomic) UILabel *timersLabel;
@property (strong, nonatomic) UITableViewCell *fromCell;
@property (strong, nonatomic) UITableViewCell *toCell;
@property (strong, nonatomic) NSArray *timerTableRows;
@property (nonatomic) NSInteger selectedDate;

- (IBAction)cancel:(id)sender;
- (IBAction)dateChanged:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)onShowTimerButtonTapped:(id)sender;

- (BOOL)isValid;
- (NSArray *)getSelectedTimerSections:(NSMutableArray *)outEmptyTimers;
- (void)performActionOnTimerSections:(NSArray *)sections andEmptyTimers:(NSArray *)timers;
- (NSString *)headerLabelTextForSection:(NSInteger)section;
- (UITableViewCell *)dateCellWithTitle:(NSString *)title;
- (void)refresh;

+ (NSArray *)getTimerTableRowsWithRegistrationsBetween:(NSDate *)startDate and:(NSDate *)endDate;
+ (NSArray *)getSelectedTimerSections:(NSArray *)rows startTime:(NSDate *)startTime endTime:(NSDate *)endTime;

@end
