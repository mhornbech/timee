//
//  SelectRegistrationViewController.m
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppColors.h"
#import "AppDelegate.h"
#import "Registration.h"
#import "RegistrationTableRow.h"
#import "RegistrationTableSection.h"
#import "SelectRegistrationsView.h"
#import "SelectRegistrationsViewController.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerSection.h"
#import "TimerTableCellView.h"
#import "TimerTableRow.h"
#import "TimerTableViewController.h"
#import "TimerView.h"
#import "ViewControllerCache.h"
#import "dispatch/queue.h"

#define kTimerViewNibName                   @"TimerView"
#define kTimerTableViewCellNibName          @"SelectRegistrationsTableCell"

#define kTableViewCellIdentifier            @"SelectRegistrationsTableCell"
#define kTimerTableViewCellIdentifier       @"SelectRegistrationsTimerTableCell"

@implementation SelectRegistrationsViewController

@synthesize delegate = _delegate;
@synthesize endTime = _endTime;
@synthesize selectRegistrationsView = _selectRegistrationsView;
@synthesize startTime = _startTime;
@synthesize cell = _cell;
@synthesize selectedRows = _selectedRows;
@synthesize daysLabel = _daysLabel;
@synthesize timersLabel = _timersLabel;
@synthesize fromCell = _fromCell;
@synthesize toCell = _toCell;
@synthesize selectedDate = _selectedDate;
@synthesize timerTableRows = _timerTableRows;

dispatch_queue_t queue;

#pragma mark - Actions

- (IBAction)cancel:(id)sender
{
    [self.delegate selectRegistrationsViewControllerDidFinish:self];
}

- (IBAction)dateChanged:(id)sender
{
    NSDate *date = self.selectRegistrationsView.datePicker.date;
    
    NSString *text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
    
    UILabel *fromLabel = (UILabel *)[self.fromCell viewWithTag:2];
    UILabel *toLabel = (UILabel *)[self.toCell viewWithTag:2];
    
    if (self.selectedDate == 0)
    {
        self.startTime = date;
        fromLabel.text = text;
    }
    else 
    {
        self.endTime = date;
        toLabel.text = text;
    }
    
    fromLabel.alpha = self.isValid ? 1.0 : 0.5;
    toLabel.alpha = self.isValid ? 1.0 : 0.5;
    
    self.selectRegistrationsView.doneButton.enabled = self.isValid;
    self.daysLabel.text = [self headerLabelTextForSection:0];
    
    self.timerTableRows = [SelectRegistrationsViewController getTimerTableRowsWithRegistrationsBetween:self.startTime and:self.endTime];
    [self.selectRegistrationsView.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)done:(id)sender
{
    NSMutableArray *emptyTimers = [[NSMutableArray alloc] init];
    [self performActionOnTimerSections:[self getSelectedTimerSections:emptyTimers] andEmptyTimers:emptyTimers];
}

- (IBAction)onShowTimerButtonTapped:(id)sender
{
    UIView *view = (UIView *)sender;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.selectRegistrationsView.tableView indexPathForCell:cell];    
    TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.row];
    
    TimerViewController *viewController = (TimerViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Timer"];
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {
        viewController = [[TimerViewController alloc] initWithNibName:kTimerViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Timer"];
    }
    
    viewController.timer = row.timer;
    viewController.delegate = self;
    
    if (cached)
    {
        [viewController prepareDataForView];
        [viewController.timerView.tableView reloadData];
        [viewController.timerView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [viewController.timerView.tableView setFrame:CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45)];
        viewController.dateScrollOffset = nil;
    }
    
    [self presentModalViewController:viewController animated:YES]; 
}

#pragma mark - Static Methods

+ (NSArray *)getTimerTableRowsWithRegistrationsBetween:(NSDate *)startDate and:(NSDate *)endDate
{
    NSMutableArray *timerTableRows = [[NSMutableArray alloc] init];
    NSMutableSet *creationTimes = [[NSMutableSet alloc] init];
    
    for (RegistrationTableSection *section in [TimeeData instance].registrationTableSections)
    {
        if ([section.date compare:endDate] == NSOrderedDescending)
            continue;
        
        if ([section.date compare:startDate] == NSOrderedAscending)
            break;
            
        for (RegistrationTableRow *row in section.rows)
        {
            if (![creationTimes containsObject:row.timer.creationTime])
            {
                [timerTableRows addObject:row.timer.timerTableRow];
                [creationTimes addObject:row.timer.creationTime];
            }
        }
    }
    
    return timerTableRows;
}

+ (NSArray *)getSelectedTimerSections:(NSArray *)rows startTime:(NSDate *)startTime endTime:(NSDate *)endTime
{
    NSMutableArray *selectedTimerSections = [[NSMutableArray alloc] init];
    
    for (TimerTableRow *row in rows)
    {
        for (TimerSection *section in row.timer.sections)
        {
            if ([section.date compare:startTime] != NSOrderedAscending && [section.date compare:endTime] != NSOrderedDescending)
                [selectedTimerSections addObject:section];
        }
    }
    
    return selectedTimerSections;
}

#pragma mark - Instance Methods

- (BOOL)isValid
{
    return [self.endTime timeIntervalSinceDate:self.startTime] > -0.1;
}

- (NSArray *)getSelectedTimerSections:(NSMutableArray *)outEmptyTimers
{
    NSMutableArray *selectedTimerSections = [[NSMutableArray alloc] init];
    NSMutableArray *selectedRows = nil;
    
    if (self.selectedRows.count == 0)
        selectedRows = [NSMutableArray arrayWithArray:self.timerTableRows];
    else 
    {
        selectedRows = [[NSMutableArray alloc] init];
        
        for (NSManagedObjectID *objectId in self.selectedRows)
            [selectedRows addObject:[[TimeeData context] objectWithID:objectId]];
    }
        
    for (TimerTableRow *row in selectedRows)
    {
        if (row.timer.sections.count != 0)
        {
            for (TimerSection *section in row.timer.sections)
            {
                if ([section.date compare:self.startTime] != NSOrderedAscending && [section.date compare:self.endTime] != NSOrderedDescending)
                    [selectedTimerSections addObject:section];
            }
        }
        else 
            [outEmptyTimers addObject:row.timer];
    }
    
    return selectedTimerSections;
}

- (void)performActionOnTimerSections:(NSArray *)sections andEmptyTimers:(NSArray *)timers
{    
}

- (UITableViewCell *)dateCellWithTitle:(NSString *)title
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_small"]];
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_small"]];
    
    UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 60, 44)];
    leftLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:17];
    leftLabel.textColor = [AppColors black];
    leftLabel.shadowColor = [UIColor whiteColor];
    leftLabel.shadowOffset = CGSizeMake(0, 1);
    leftLabel.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:leftLabel];
    
    UIImageView *selectionMarker = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selection_marker"]];
    selectionMarker.frame = CGRectMake(7, 4, 32, 25);
    selectionMarker.contentMode = UIViewContentModeBottom;
    selectionMarker.tag = 1;
    selectionMarker.hidden = YES;
    [cell.contentView addSubview:selectionMarker];
    
    leftLabel.text = title;
    
    UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(111, 0, 160, 44)];
    rightLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    rightLabel.textColor = leftLabel.textColor;
    rightLabel.shadowColor = leftLabel.shadowColor;
    rightLabel.shadowOffset = leftLabel.shadowOffset;
    rightLabel.backgroundColor = leftLabel.backgroundColor;
    rightLabel.textAlignment = UITextAlignmentRight;
    rightLabel.tag = 2;
    
    [cell.contentView addSubview:rightLabel];    
    
    return cell;
}

- (NSString *)headerLabelTextForSection:(NSInteger)section
{
    if (section == 0)
    {        
        NSArray *sections = [TimeeData instance].registrationTableSections;
        NSString *daysString = nil;
        
        if (sections.count == 0 || 
            ([self.startTime isEqualToDate:((RegistrationTableSection *)[sections objectAtIndex:sections.count - 1]).date]
            && [self.endTime isEqualToDate:((RegistrationTableSection *)[sections objectAtIndex:0]).date]))
        {
            daysString = @"ALL";
        }
        else 
        {
            NSInteger days = [self.endTime timeIntervalSinceDate:self.startTime] / (24 * 3600) + 1;
            daysString = [NSString stringWithFormat:@"%d", days >= 1 ? days : 0];
        }
        
        return [NSString stringWithFormat:@"DAYS (%@)", daysString];
    }
    else 
    {
        BOOL allSelected = self.selectedRows.count == self.timerTableRows.count || self.selectedRows.count == 0;
        BOOL allShown = self.timerTableRows.count == [TimeeData instance].timerTableRows.count;
        
        NSString *timersString = allSelected && allShown ? @"ALL"
            : [NSString stringWithFormat:@"%d", allSelected ? self.timerTableRows.count : self.selectedRows.count];
        
        return [NSString stringWithFormat:@"TIMERS (%@)", timersString];
    }
}

#pragma mark - Timer View Delegate

- (void)timerViewControllerDidFinish:(TimerViewController *)controller
{
    [self refresh];
    [self.selectRegistrationsView.tableView reloadData];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        UITableViewCell *cell = indexPath.row == 0 ? self.fromCell : self.toCell;;
        NSDate *date = indexPath.row == 0 ? self.startTime : self.endTime;
        
        ((UILabel *)[cell viewWithTag:2]).text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
        
        UIImageView *selectionMarker = (UIImageView *)[cell viewWithTag:1];
        
        if (indexPath.row == 0)
            selectionMarker.hidden = self.selectedDate != 0;
        else 
            selectionMarker.hidden = self.selectedDate != 1;
                
        return cell;
    }
    else 
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTimerTableViewCellIdentifier];
        
        TimerTableCellView *cellView = nil;
        
        if (cell == nil)
        {
            [[NSBundle mainBundle] loadNibNamed:kTimerTableViewCellNibName owner:self options:nil];
            cell = self.cell;
            
            cellView = [cell.contentView.subviews objectAtIndex:0];
            cellView.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:16.0];
            cellView.subtitleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:15.0];
            cellView.timeLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18.0];
            
            cellView.titleLabel.textColor = cellView.subtitleLabel.textColor = cellView.timeLabel.textColor = [AppColors black];
        }
        else
            cellView = [cell.contentView.subviews objectAtIndex:0];
        
        TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.row];
        
        cellView.titleLabel.text = cellView.subtitleLabel.text = cellView.timeLabel.text = @"";
        cellView.detailsButton.hidden = YES;
        cell.userInteractionEnabled = NO;
        [cellView.activityIndicator startAnimating];
        
        cellView.tag = indexPath.row;
        
        dispatch_async(queue, ^{
            NSArray *labelTexts = [TimerTableViewController getTitleLabelTexts:row.timer.info.allObjects];            
            NSArray *runningTime = [TimerTableViewController getRunningTime:row ofType:@"total" between:self.startTime and:self.endTime];
            
            if (cellView.tag == indexPath.row)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    int hours = ((NSNumber *)[runningTime objectAtIndex:0]).intValue;
                    int minutes = ((NSNumber *)[runningTime objectAtIndex:1]).intValue;
                    
                    [cellView.activityIndicator stopAnimating];
                    cellView.titleLabel.text = [labelTexts objectAtIndex:0];
                    cellView.subtitleLabel.text = [labelTexts objectAtIndex:1];
                    cellView.timeLabel.text = [NSString stringWithFormat:@"%d:%@%d", hours, minutes < 10 ? @"0" : @"", minutes];
                    cellView.detailsButton.hidden = NO;
                    cell.userInteractionEnabled = YES;
                });
            }
        });
        
        if ([self.selectedRows containsObject:row.objectID])
            cellView.selectionMarker.hidden = NO;
        else 
            cellView.selectionMarker.hidden = YES;
        
        return cell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 2;
    
    return self.timerTableRows.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 34.0)];
    view.backgroundColor = [AppColors darkGold];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 0.0, 200.0, 34.0)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [AppColors grey];
    label.font = [UIFont fontWithName:@"SourceSansPro-It" size:15];
    label.text = [self headerLabelTextForSection:section];
    
    if (section == 0)
        self.daysLabel = label;
    else 
        self.timersLabel = label;
    
    [view addSubview:label];
    
    return view;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        return 44;
    
    return 63;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:self.selectedDate inSection:0];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIImageView *selectionMarker = (UIImageView *)[cell.contentView viewWithTag:1];
        
        if (self.selectedDate != indexPath.row)
        {
            UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
            UIImageView *oldSelectionMarker = (UIImageView *)[oldCell.contentView viewWithTag:1];
            oldSelectionMarker.hidden = YES;
            
            if (self.selectedDate == -1)
            {
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.3];
                
                self.selectRegistrationsView.datePicker.frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 216, 320, 216);
                
                [UIView commitAnimations];
                
                self.selectRegistrationsView.tableView.scrollEnabled = NO;
            }
            
            self.selectedDate = indexPath.row;
                        
            selectionMarker = (UIImageView *)[cell.contentView viewWithTag:1];
            selectionMarker.hidden = NO;
            
            [self.selectRegistrationsView.datePicker setDate:indexPath.row == 0 ? self.startTime : self.endTime];
            
            if (self.selectedDate == -1)
            {
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.3];
                
                self.selectRegistrationsView.datePicker.frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 216, 320, 216);
                
                [UIView commitAnimations];
            }
        }
        else 
        {
            selectionMarker = (UIImageView *)[cell.contentView viewWithTag:1];
            selectionMarker.hidden = YES;
            
            self.selectedDate = -1;
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.3];
            
            self.selectRegistrationsView.datePicker.frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, 320, 216);
            
            [UIView commitAnimations];
            
            self.selectRegistrationsView.tableView.scrollEnabled = YES;
        }
    }
    else
    {
        if (self.selectedDate != -1)
        {
            [self tableView:self.selectRegistrationsView.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedDate inSection:0]];
        }
        else
        {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            TimerTableCellView *cellView = ((TimerTableCellView *)[cell.contentView.subviews objectAtIndex:0]);
            NSManagedObjectID *timerId = ((TimerTableRow *)[self.timerTableRows objectAtIndex:indexPath.row]).objectID;
            
            if ([self.selectedRows containsObject:timerId])
            {
                [self.selectedRows removeObject:timerId];
                cellView.selectionMarker.hidden = YES;
            }
            else 
            {
                [self.selectedRows addObject:timerId];
                cellView.selectionMarker.hidden = NO;
            }
            
            self.timersLabel.text = [self headerLabelTextForSection:1];        
        }
    }     
}

#pragma mark - View lifecycle

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    queue = dispatch_queue_create(nil, NULL);
    
    self.selectRegistrationsView = (SelectRegistrationsView *)self.view;   
    self.selectRegistrationsView.title.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.selectRegistrationsView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.selectRegistrationsView.tableView.frame;
        self.selectRegistrationsView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
        
        frame = self.selectRegistrationsView.datePicker.frame;
        self.selectRegistrationsView.datePicker.frame = CGRectMake(frame.origin.x, frame.origin.y + 88, frame.size.width, frame.size.height);
    }
    
    self.selectRegistrationsView.datePicker.locale = [NSLocale currentLocale];
    self.selectRegistrationsView.datePicker.backgroundColor = [AppColors gold];
    
    self.fromCell = [self dateCellWithTitle:@"From"];
    self.toCell = [self dateCellWithTitle:@"To"];
    
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.selectRegistrationsView.datePicker setDate:self.startTime animated:NO];
    self.selectRegistrationsView.datePicker.frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, 320, 216);
}

- (void)refresh
{
    self.selectedDate = -1;
    
    NSArray *sections = [TimeeData instance].registrationTableSections;
    
    if (sections.count != 0)
    {
        self.selectRegistrationsView.datePicker.maximumDate = ((RegistrationTableSection *)[sections objectAtIndex:0]).date;
        self.selectRegistrationsView.datePicker.minimumDate = ((RegistrationTableSection *)[sections objectAtIndex:sections.count - 1]).date;
    }
    else
        self.selectRegistrationsView.datePicker.maximumDate = self.selectRegistrationsView.datePicker.minimumDate = [NSDate date];
    
    self.timerTableRows = [SelectRegistrationsViewController getTimerTableRowsWithRegistrationsBetween:self.startTime and:self.endTime];
}

@end
