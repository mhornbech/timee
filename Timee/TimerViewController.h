//
//  TimerViewController.h
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "RegistrationViewController.h"

@class TimeeData;
@class TimerView;
@class TimerViewController;

@protocol TimerViewControllerDelegate

- (void)timerViewControllerDidFinish:(TimerViewController *)controller;

@end

@class Timer;
@class Registration;

@interface TimerViewController : UIViewController<RegistrationViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

@property (assign, nonatomic) IBOutlet id<TimerViewControllerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *info;
@property (strong, nonatomic) NSMutableArray *sections;
@property (strong, nonatomic) NSMutableArray *initialTitles;
@property (strong, nonatomic) NSMutableDictionary *sectionCache;
@property (strong, nonatomic) UITextField *textFieldBeingEdited;
@property (strong, nonatomic) IBOutlet UITableViewCell *infoCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *totalCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *currentCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *registrationCell;
@property (strong, nonatomic) Timer *timer;
@property (strong, nonatomic) TimerView *timerView;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDateFormatter *timeFormatter;
@property (strong, nonatomic) NSMutableArray *initialRegistrationTableSections;
@property (strong, nonatomic) NSDate *dateScrollOffset;

- (IBAction)cancel;
- (IBAction)done;
- (IBAction)acceptSuggestion:(id)sender;
- (IBAction)textFieldDone:(id)sender;
- (IBAction)deleteInfoRow:(id)sender;
- (IBAction)addInfo;
- (IBAction)addRegistration;
- (IBAction)reset;
- (IBAction)clear;

- (void)prepareDataForView;
- (void)refreshTotal;
- (void)refreshCurrent;
- (BOOL)isInfoUnique;
- (BOOL)canDeleteInfoRowAtIndex:(NSInteger)index;
- (BOOL)canDeleteRegistrationRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteInfoRowAtIndex:(NSInteger)index;
- (void)deleteRegistrationRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)clearSuggestionLabel:(UILabel *)label inTextField:(UITextField *)textField;
- (void)scrollToDate:(NSDate *)date;

+ (double)getTotalForRegistrations:(NSArray *)registrations;
+ (NSString *)getTotalTextInHeaderForSection:(NSArray *)sortedRegistrations;
+ (void)absorbSubOneMinuteRegistrations:(Registration *)registration;
+ (void)handleSubOneMinuteRegistration:(Registration *)registration;
+ (void)adaptRegistrationstoRegistration:(Registration *)registration;
+ (void)splitMultiDayRegistration:(Registration *)registration;
+ (void)saveRegistrationFromViewController:(RegistrationViewController *)controller forTimer:(Timer *)timer;

@end
