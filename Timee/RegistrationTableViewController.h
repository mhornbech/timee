//
//  RegistrationTableViewController.h
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "TimerViewController.h"
#import "RegistrationTableSection.h"
#import "RegistrationTableRow.h"

@class RegistrationTableView;
@class RegistrationTableViewController;

@protocol RegistrationTableViewControllerDelegate

- (void)registrationTableViewControllerDidFinish:(RegistrationTableViewController *)controller;

@end

@class RegistrationView;

@interface RegistrationTableViewController : UIViewController<TimerViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (assign, nonatomic) IBOutlet id<RegistrationTableViewControllerDelegate> delegate;
@property (strong, nonatomic) NSMutableDictionary *sectionCaches;
@property (strong, nonatomic) NSMutableArray *registrationTableSections;
@property (strong, nonatomic) IBOutlet UITableViewCell *cell;
@property (strong, nonatomic) IBOutlet UITableViewCell *searchCell;
@property (strong, nonatomic) IBOutlet RegistrationTableView *registrationTableView;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDateFormatter *timeFormatter;
@property (strong, nonatomic) NSMutableArray *expandedIndexPaths;
@property (nonatomic) int secondsPerDay;
@property (nonatomic) int secondsFromGMT;
@property (nonatomic) BOOL searchActive;
@property (nonatomic) BOOL searchCancelled;

- (IBAction)done:(id)sender;
- (IBAction)onShowTimerButtonTapped:(id)sender;
- (IBAction)searchBarSearchButtonClicked;
- (IBAction)searchBarCancelButtonClicked;

- (NSArray *)getRegistrationTableRowWithIndexPathForIndexPath:(NSIndexPath *)indexPath;
- (NSDictionary *)getCacheForSection:(RegistrationTableSection *)section;
- (NSMutableArray *)getSearchResults:(NSString *)searchString;
- (void)prepareDataForView;
- (void)addExpandedIndexPaths:(NSArray *)indexPaths following:(NSIndexPath *)indexPath;
- (void)removeExpandedIndexPaths:(NSArray *)indexPaths following:(NSIndexPath *)indexPath;

@end

@interface RegistrationTableSectionContainer : NSObject<RegistrationTableSectionProtocol> 

@end

@interface RegistrationTableRowContainer : NSObject<RegistrationTableRowProtocol> 

@end
