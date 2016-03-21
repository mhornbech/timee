//
//  TimerTableViewController.h
//  Timee
//
//  Created by Morten Hornbech on 06/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "OptionsViewController.h"
#import "InfoViewController.h"

@class TimeeData;
@class TimerTable;
@class TimerTableRow;
@class TimerTableView;
@class TimerTableView_Landscape;

@interface TimerTableViewController : UIViewController <InfoViewControllerDelegate, OptionsViewControllerDelegate, TimerViewControllerDelegate, TutorialViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) NSTimer *counter;
@property (strong, nonatomic) NSTimer *timerTableAdjuster;
@property (strong, nonatomic) NSIndexPath *indexPathForTimerBeingDeleted;
@property (strong, nonatomic) IBOutlet UITableViewCell *cell;
@property (strong, nonatomic) IBOutlet TimerTableView *timerTableView;
@property (strong, nonatomic) IBOutlet TimerTableView_Landscape *timerTableView_Landscape;
@property (nonatomic) BOOL viewWillAppearCompleted;
@property (nonatomic) BOOL landscapeMode;

- (IBAction)onDisplayTapped:(id)sender;
- (IBAction)onInfoButtonTapped:(id)sender;
- (IBAction)onOptionsButtonTapped:(id)sender;
- (IBAction)onShowRunningTimerButtonTapped:(id)sender;
- (IBAction)onShowTimerButtonTapped:(id)sender;
- (IBAction)onDeleteButtonTapped:(id)sender;
- (IBAction)showAddTimer;
- (IBAction)fadeWheelOut;
- (IBAction)fadeWheelIn;

- (void)onSwipeRecognized:(UISwipeGestureRecognizer *)recognizer;
- (void)onTapRecognized:(UITapGestureRecognizer *)recognizer;
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground; 
- (NSArray *)getLabelTexts:(TimerTableRow *)row;
- (void)initAdjuster;
- (void)initTimer;
- (void)onAdjustTableView;
- (void)onTimerFire;
- (void)onTimerFire:(NSTimeInterval)animationDuration;
- (void)onTimerTableCellTapped:(NSIndexPath *)indexPath;
- (void)setLabelsAlpha:(CGFloat)alpha;
- (void)deleteTimerAtIndexPath:(NSIndexPath *)indexPath;
- (void)initLandscapeView;
- (void)transformArrowButton;

+ (NSArray *)getRunningTime:(TimerTableRow *)row ofType:(NSString *)type;
+ (NSArray *)getRunningTime:(TimerTableRow *)row ofType:(NSString *)type between:(NSDate *)startDate and:(NSDate *)endDate;
+ (NSArray *)getTitleLabelTexts:(NSArray *)info;
+ (TimerTableViewController *)instance;

@end
