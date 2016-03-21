//
//  TimerViewController.m
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppColors.h"
#import "AppDelegate.h"
#import "InfoCache.h"
#import "Registration.h"
#import "RegistrationTableRow.h"
#import "RegistrationTableSection.h"
#import "RegistrationView.h"
#import "RegistrationViewController.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerInfo.h"
#import "TimerInfoCellView.h"
#import "TimerRegistrationCellView.h"
#import "TimerSection.h"
#import "TimerTable.h"
#import "TimerTableRow.h"
#import "TimerTableViewController.h"
#import "TimerTotalCellView.h"
#import "TimerCurrentCellView.h"
#import "TimerView.h"
#import "TimerViewController.h"
#import "ViewControllerCache.h"
#import <QuartzCore/QuartzCore.h> 

#define kInfoSection                        0
#define kRegistrationsSection               1

#define kTimerInfoCellIdentifier            @"TimerInfoCell"
#define kTimerTotalCellIdentifier           @"TimerTotalCell"
#define kTimerCurrentCellIdentifier         @"TimerCurrentCell"
#define kTimerRegistrationCellIdentifier    @"TimerRegistrationCell"

#define kTimerInfoCellNibName               @"TimerInfoCell"
#define kTimerTotalCellNibName              @"TimerTotalCell"
#define kTimerCurrentCellNibName            @"TimerCurrentCell"
#define kTimerRegistrationCellNibName       @"TimerRegistrationCell"
#define kRegistrationViewNibName            @"RegistrationView"

#define kTimerInfoEntityName                @"TimerInfo"
#define kRegistrationEntityName             @"Registration"

@implementation TimerViewController

@synthesize delegate = _delegate;
@synthesize info = _info;
@synthesize sections = _sections;
@synthesize initialTitles = _initialTitles;
@synthesize sectionCache = _sectionCache;
@synthesize textFieldBeingEdited = _textFieldBeingEdited;
@synthesize infoCell = _infoCell;
@synthesize totalCell = _totalCell;
@synthesize currentCell = _currentCell;
@synthesize registrationCell = _registrationCell;
@synthesize timer = _timer;
@synthesize timerView = _timerView;
@synthesize dateFormatter = _dateFormatter;
@synthesize timeFormatter = _timeFormatter;
@synthesize initialRegistrationTableSections =_initialRegistrationTableSections;
@synthesize dateScrollOffset = _dateScrollOffset;

#pragma mark - Actions

- (IBAction)cancel
{
    [self.textFieldBeingEdited resignFirstResponder];    
    [TimeeData rollback];
    [TimeeData instance].registrationTableSections = self.initialRegistrationTableSections;
    [self.delegate timerViewControllerDidFinish:self];
}

- (IBAction)done
{               
    if (self.textFieldBeingEdited != nil)
        [self textFieldDidEndEditing:self.textFieldBeingEdited];
    
    if (![self isInfoUnique])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unable to add timer!" 
                                                            message:@"A timer with the same set of info already exists."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        
        [self.timerView.tableView setFrame:CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45)];
        [alertView show];      
    }
    else 
    {    
        if (self.timer.creationTime == nil)
        {
            self.timer.creationTime = [NSDate date];    
            [[TimeeData instance] addTimer:self.timer];
        }
        else
        {
            if ([TimeeData context].hasChanges && self.timer.timerTableRow.lastUseTime != nil)
            {
                NSUInteger indexOfSelf = 0;
                NSArray *rows = [TimeeData instance].timerTableRows;
                
                for (int i = 0; i < rows.count; i++)
                {
                    TimerTableRow *row = [rows objectAtIndex:i];
                    
                    if (row.lastUseTime == nil || ![self.timer.timerTableRow.lastUseTime isEqualToDate:row.lastUseTime])
                        indexOfSelf++;
                    else
                        break;
                }
                
                NSUInteger indexToInsert = [[TimeeData instance].timerTable.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]] ? 1 : 0;
                
                [[TimeeData instance].timerTableRows removeObjectAtIndex:indexOfSelf];
                [[TimeeData instance].timerTableRows insertObject:self.timer.timerTableRow atIndex:indexToInsert];
                
                self.timer.timerTableRow.lastUseTime = [NSDate date];
            }
        }
        
        for (TimerInfo *info in self.info)
        {
            if (![self.initialTitles containsObject:info.title])
                [[InfoCache instance] insertOrUpdate:info.title];
        }            
        
        [TimeeData commit];
        
        [self.delegate timerViewControllerDidFinish:self];
    }
}

- (IBAction)clear
{
    UIView *cellView = self.textFieldBeingEdited;
    while (![cellView isKindOfClass:[TimerInfoCellView class]]) {
        cellView = [cellView superview];
    }
    
    TimerInfoCellView *cell = (TimerInfoCellView *)cellView;
    
    UILabel *label = cell.suggestionLabel;
    [self clearSuggestionLabel:label inTextField:self.textFieldBeingEdited];
    self.textFieldBeingEdited.text = @"";
    
    cell.clearButton.hidden = YES;
}

- (IBAction)acceptSuggestion:(id)sender
{
    UIView *cellView = (UIView *)sender;
    while (![cellView isKindOfClass:[TimerInfoCellView class]]) {
        cellView = [cellView superview];
    }
    
    TimerInfoCellView *cell = (TimerInfoCellView *)cellView;
    cell.textField.text = [cell.textField.text stringByAppendingString:cell.suggestionLabel.text];
    [self clearSuggestionLabel:cell.suggestionLabel inTextField:cell.textField];
}

- (IBAction)textFieldDone:(id)sender
{
    [self.timerView.tableView setFrame:CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45)];
    [sender resignFirstResponder];
}

- (IBAction)addInfo
{
    UITableView *tableView = ((TimerView *)self.view).tableView;
    NSIndexPath *path = [NSIndexPath indexPathForRow:self.info.count inSection:kInfoSection];        
    TimerInfo *info = [NSEntityDescription insertNewObjectForEntityForName:kTimerInfoEntityName 
                                                    inManagedObjectContext:[TimeeData context]];
    
    info.index = [NSNumber numberWithInt:self.info.count];        
    info.title = @"";
    [self.timer addInfoObject:info];
    [self.info addObject:info];
    
    [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationTop];
    TimerInfoCellView *cellView = (TimerInfoCellView *)[[tableView cellForRowAtIndexPath:path].contentView.subviews objectAtIndex:0];
    [cellView.textField becomeFirstResponder];
}

- (IBAction)addRegistration
{
    RegistrationViewController *viewController = (RegistrationViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Registration"];
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {
        viewController = [[RegistrationViewController alloc] initWithNibName:kRegistrationViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Registration"];
    }
    
    if (cached)
    {
        viewController.selectedRow = 0;
        viewController.registrationView.doneButton.enabled = YES;
    }

    viewController.delegate = self;
    viewController.endTime = [NSDate dateWithTimeIntervalSinceReferenceDate:(int)([[NSDate date] timeIntervalSinceReferenceDate] / 60) * 60];
    viewController.startTime = [NSDate dateWithTimeInterval:-3600 sinceDate:viewController.endTime];
    viewController.note = nil;
    viewController.objectId = nil;
    
    [viewController.registrationView.tableView reloadData];
    [self presentModalViewController:viewController animated:YES]; 
}

- (IBAction)reset
{    
    self.timer.lastResetTime = [NSDate date];
    
    NSArray *registrations = [NSArray arrayWithArray:self.timer.timerTableRow.registrations.allObjects];
    
    for (Registration *reg in registrations)
    {
        if (reg.endTime != nil && [self.timer.lastResetTime compare:reg.endTime] == NSOrderedDescending)
        {
            [self.timer.timerTableRow removeRegistrationsObject:reg];
            
            if ([reg.endTime timeIntervalSinceDate:reg.startTime] < 59.9)
                [[TimeeData instance] deleteRegistration:reg];
        }                        
    }
    
    [self refreshCurrent];
}

- (IBAction)deleteInfoRow:(id)sender
{
    UIView *cellView = (UIView *)sender;
    while (![cellView isKindOfClass:[TimerInfoCellView class]]) {
        cellView = [cellView superview];
    }
    
    TimerInfoCellView *cell = (TimerInfoCellView *)cellView;
    
    if ([self canDeleteInfoRowAtIndex:cell.textField.tag])
        [self deleteInfoRowAtIndex:cell.textField.tag];
    else
        [self onTapRecognized:cell.tapRecognizer];
}

- (IBAction)deleteRegistrationRow:(id)sender
{
    UIView *cellView = (UIView *)sender;
    while (![cellView isKindOfClass:[UITableViewCell class]]) {
        cellView = [cellView superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)cellView;
    NSIndexPath *indexPath = [self.timerView.tableView indexPathForCell:cell];
    [self deleteRegistrationRowAtIndexPath:indexPath];
}

#pragma mark - Instance Methods

- (void)clearSuggestionLabel:(UILabel *)label inTextField:(UITextField *)textField
{
    label.frame = CGRectMake(40, [[UIScreen mainScreen] scale] == 2.0 ? 0.5 : 0, 240, 44);
    label.text = @"";
    
    UIView *cellView = textField;
    while (![cellView isKindOfClass:[TimerInfoCellView class]]) {
        cellView = [cellView superview];
    }
    
    TimerInfoCellView *cell = (TimerInfoCellView *)cellView;
    cell.acceptButton.frame = label.frame;
    cell.acceptButton.hidden = YES;
}

- (BOOL)isInfoUnique
{    
    NSMutableArray *titles = [[NSMutableArray alloc] initWithCapacity:self.info.count];
    
    for (TimerInfo *info in self.info)
        [titles addObject:info.title];
        
    if ([[self.initialTitles componentsJoinedByString:@"___"] isEqualToString:[titles componentsJoinedByString:@"___"]])
        return YES;
    
    NSUInteger hash = 0;
    
    for (TimerInfo *info in self.info)
        hash ^= info.title.hash;
        
    NSArray *sortedTitles = [titles sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((NSString *)obj1) compare:((NSString *)obj2)];
    }];

    for (TimerTableRow *row in [TimeeData instance].timerTableRows)
    {
        if (row != self.timer.timerTableRow)
        {
            NSUInteger otherHash = 0;    
            
            for (TimerInfo *info in row.timer.info)
                otherHash ^= info.title.hash;
            
            if (hash == otherHash)
            {                            
                NSMutableArray *otherTitles = [[NSMutableArray alloc] initWithCapacity:row.timer.info.count];
                
                for (TimerInfo *info in row.timer.info)
                    [otherTitles addObject:info.title];
                
                NSArray *otherSortedTitles = [otherTitles sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    return [((NSString *)obj1) compare:((NSString *)obj2)];
                }];
                                                
                if ([[sortedTitles componentsJoinedByString:@"___"] isEqualToString:[otherSortedTitles componentsJoinedByString:@"___"]])
                    return NO;
            }
        }
    }
    
    return YES;
}

- (TimerSection *)getSectionForIndexPathSection:(NSInteger)section
{
    return [self.sections objectAtIndex:section - kRegistrationsSection - 1];
}

- (void)refreshTotal
{
    NSArray *total = [TimerTableViewController getRunningTime:self.timer.timerTableRow ofType:@"total"];
    int totalHours = ((NSNumber *)[total objectAtIndex:0]).intValue;
    int totalMinutes = ((NSNumber *)[total objectAtIndex:1]).intValue;
    
    TimerTotalCellView *totalCellView = (TimerTotalCellView *)[self.totalCell.contentView.subviews objectAtIndex:0];
    totalCellView.timeLabel.text = totalHours < 1000 ? [NSString stringWithFormat:@"%d:%@%d", totalHours, totalMinutes < 10 ? @"0" : @"", totalMinutes] : [NSString stringWithFormat:@"%d", totalHours];
}

- (void)refreshCurrent
{    
    NSArray *current = [TimerTableViewController getRunningTime:self.timer.timerTableRow ofType:@"current"];
    int currentHours = ((NSNumber *)[current objectAtIndex:0]).intValue;
    int currentMinutes = ((NSNumber *)[current objectAtIndex:1]).intValue;
        
    TimerCurrentCellView *currentCellView = (TimerCurrentCellView *)[self.currentCell.contentView.subviews objectAtIndex:0];
    currentCellView.timeLabel.text = currentHours < 1000 ? [NSString stringWithFormat:@"%d:%@%d", currentHours, currentMinutes < 10 ? @"0" : @"", currentMinutes] : [NSString stringWithFormat:@"%d", currentHours];
}

- (NSMutableDictionary *)getCacheForSection:(TimerSection *)section
{
    NSMutableDictionary *cache = [self.sectionCache objectForKey:section.date];
    
    if (cache == nil)
    {
        cache = [[NSMutableDictionary alloc] init];
        
        NSMutableArray *sortedRegistrations = [NSMutableArray arrayWithArray:[section.registrations.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [((Registration *)obj2).startTime compare:((Registration *)obj1).startTime];
        }]];
        
        [cache setObject:sortedRegistrations forKey:@"sortedRegistrations"];        
        [self.sectionCache setObject:cache forKey:section.date];
    }
    
    return cache;
}

- (void)onSwipeRecognized:(UISwipeGestureRecognizer *)recognizer
{
    recognizer.enabled = NO;    
    
    if ([recognizer.view isKindOfClass:[TimerInfoCellView class]])
    {
        TimerInfoCellView *view = (TimerInfoCellView *)recognizer.view;  
        
        if (![self canDeleteInfoRowAtIndex:view.textField.tag])
        {
            recognizer.enabled = YES;
            return;
        }
        
        view.textField.enabled = NO;        
        view.onDeleteLabel.text = view.textField.text;

        UILabel *placeholder = [[UILabel alloc] init];
        placeholder.text = view.onDeleteLabel.text;
        placeholder.font = view.onDeleteLabel.font;
        [placeholder sizeToFit];

        if (placeholder.frame.size.width > 176)
        {               
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.25];
            
            view.textField.alpha = 0.0;
            view.onDeleteLabel.alpha = 1.0;
            
            [UIView commitAnimations];
        }
        else 
        {
            view.textField.alpha = 0.0;
            view.onDeleteLabel.alpha = 1.0;
        }

        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelay:0.25];
        
        view.deleteButton.alpha = 1.0;
        
        [UIView commitAnimations];
        
        if (view.tapRecognizer == nil)
        {
            view.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapRecognized:)];
            view.tapRecognizer.delegate = self;
            [view addGestureRecognizer:view.tapRecognizer];        
        }
        
        view.tapRecognizer.enabled = YES;
    }
    else 
    {
        TimerRegistrationCellView *view = (TimerRegistrationCellView *)recognizer.view;
        
        UIView *cellView = view;
        while (![cellView isKindOfClass:[UITableViewCell class]]) {
            cellView = [cellView superview];
        }
        
        UITableViewCell *cell = (UITableViewCell *)cellView;
        NSIndexPath *indexPath = [self.timerView.tableView indexPathForCell:cell];
        
        if (![self canDeleteRegistrationRowAtIndexPath:indexPath])
        {
            recognizer.enabled = YES;
            return;
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        
        view.durationLabel.alpha = 0.0;
        view.hasNoteImage.alpha = 0.0;
        
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelay:0.25];
        
        view.deleteButton.alpha = 1.0;
        view.deleteButton.highlighted = NO;
        
        [UIView commitAnimations];
        
        if (view.tapRecognizer == nil)
        {
            view.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapRecognized:)];
            view.tapRecognizer.delegate = self;
            [view addGestureRecognizer:view.tapRecognizer];        
        }
        
        view.tapRecognizer.enabled = YES;
    }
}

- (void)onTapRecognized:(UITapGestureRecognizer *)recognizer
{    
    recognizer.enabled = NO;
    
    if ([recognizer.view isKindOfClass:[TimerInfoCellView class]])
    {
        TimerInfoCellView *view = (TimerInfoCellView *)recognizer.view;    
        
        view.textField.enabled = YES;    
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        
        view.deleteButton.alpha = 0.0;
        
        [UIView commitAnimations];
        
        UILabel *placeholder = [[UILabel alloc] init];
        placeholder.text = view.onDeleteLabel.text;
        placeholder.font = view.onDeleteLabel.font;
        [placeholder sizeToFit];
        
        if (placeholder.frame.size.width > 200)
        {               
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.25];
            [UIView setAnimationDelay:0.25];
            
            view.textField.alpha = 1.0;
            view.onDeleteLabel.alpha = 0.0;
            
            [UIView commitAnimations];
        }
        else 
        {
            view.textField.alpha = 1.0;
            view.onDeleteLabel.alpha = 0.0;
        }
        
        view.swipeRecognizer.enabled = YES;
    }
    else 
    {
        TimerRegistrationCellView *view = (TimerRegistrationCellView *)recognizer.view;    
        
        UIView *cellView = view;
        while (![cellView isKindOfClass:[UITableViewCell class]]) {
            cellView = [cellView superview];
        }
        
        UITableViewCell *cell = (UITableViewCell *)cellView;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        
        view.deleteButton.alpha = 0.0;
        
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelay:0.25];
        
        view.durationLabel.alpha = 1.0;
        view.hasNoteImage.alpha = 1.0;
        
        [UIView commitAnimations];
        
        view.swipeRecognizer.enabled = YES;
    }
}

- (BOOL)canDeleteInfoRowAtIndex:(NSInteger)index
{
    if (self.info.count == 1 || (self.textFieldBeingEdited != nil && self.textFieldBeingEdited.tag == index)) 
        return NO;
        
    return YES;
}

- (BOOL)canDeleteRegistrationRowAtIndexPath:(NSIndexPath *)indexPath
{
    TimerSection *section = [self getSectionForIndexPathSection:indexPath.section];
    NSArray *sortedRegistrations = [[self getCacheForSection:section] objectForKey:@"sortedRegistrations"];
    Registration *registration = [sortedRegistrations objectAtIndex:indexPath.row];
    
    if (registration.endTime == nil)
        return NO;
    
    return YES;
}

- (void)deleteInfoRowAtIndex:(NSInteger)index
{
    [[TimeeData context] deleteObject:[self.info objectAtIndex:index]];
    [self.info removeObjectAtIndex:index];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:kInfoSection];
    [self.timerView.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
    for (int i = indexPath.row; i < self.info.count; i++)
    {
        NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:kInfoSection];
        UITableViewCell *cell = [self.timerView.tableView cellForRowAtIndexPath:ip];
        
        ((TimerInfo *)[self.info objectAtIndex:i]).index = [NSNumber numberWithInt:i];
        ((UITextField *)[cell.contentView viewWithTag:i + 1]).tag = i;
    }
}
- (void)scrollToDate:(NSDate *)date
{
    NSInteger section = 0;
        
    while (![((TimerSection *)[self.sections objectAtIndex:section]).date isEqualToDate:date])
        section++;
           
    if (section < self.sections.count)
           [self.timerView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section + 2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)deleteRegistrationRowAtIndexPath:(NSIndexPath *)indexPath
{
    TimerSection *section = [self getSectionForIndexPathSection:indexPath.section];
    NSDictionary *cache = [self getCacheForSection:section];
    NSMutableArray *sortedRegistrations = [cache objectForKey:@"sortedRegistrations"];            
    BOOL deleteSection = sortedRegistrations.count == 1;
    Registration *registration = [sortedRegistrations objectAtIndex:indexPath.row];
    
    [self.timer.timerTableRow removeRegistrationsObject:registration];
    
    if (deleteSection)
    {                
        [self.sections removeObjectAtIndex:indexPath.section - kRegistrationsSection - 1];    
        [self.sectionCache removeObjectForKey:section.date];
        [[TimeeData instance] deleteRegistration:registration];
        [self.timerView.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
    }
    else
    {                                             
        NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
        [[TimeeData instance] deleteRegistration:registration];
        [self.timerView.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
        [sortedRegistrations removeObjectAtIndex:indexPath.row];
        UILabel *totalLabel = [cache objectForKey:@"totalLabel"];
        totalLabel.text = [TimerViewController getTotalTextInHeaderForSection:sortedRegistrations];
    }
    
    [self refreshTotal];
    [self refreshCurrent];
}

#pragma mark - Static Methods

+ (NSString *)getTotalTextInHeaderForSection:(NSArray *)sortedRegistrations
{
    double total = [TimerViewController getTotalForRegistrations:sortedRegistrations];
    int hours = total / 3600;
    int minutes = (total - hours * 3600) / 60;
    
    return [NSString stringWithFormat:@"%d:%@%d", hours, minutes < 10 ? @"0" : @"", minutes]; 
}

+ (double)getTotalForRegistrations:(NSArray *)registrations
{
    double total = 0;        
    NSDate *currentTime = [NSDate date];
    
    for (Registration *reg in registrations)
    {
        total += [(reg.endTime == nil ? currentTime : reg.endTime) timeIntervalSinceDate:reg.startTime];
        
        if (reg.endTime == nil)
        {
            for (Registration *reg2 in registrations)
            {
                if([reg2.endTime compare:reg.startTime] == NSOrderedDescending 
                   && [reg2.startTime compare:currentTime] == NSOrderedAscending)
                {
                    NSDate *startTime = [reg2.startTime compare:reg.startTime] == NSOrderedAscending ? reg.startTime : reg2.startTime;                    
                    NSDate *endTime = [reg2.endTime compare:currentTime] == NSOrderedDescending ? currentTime : reg2.endTime;
                    
                    total -= [endTime timeIntervalSinceDate:startTime];
                }
            }
        }
    }

    return total;
}

+ (void)saveRegistrationFromViewController:(RegistrationViewController *)controller forTimer:(Timer *)timer
{
    Registration *registration = nil;
    
    if (controller.objectId == nil)
    {
        registration = [NSEntityDescription insertNewObjectForEntityForName:kRegistrationEntityName inManagedObjectContext:[TimeeData context]];  
    }
    else
        registration = (Registration *)[[TimeeData context] objectWithID:controller.objectId];
    
    if (registration.timerSection == nil)
    {
        registration.startTime = controller.startTime;
        registration.endTime = controller.endTime;
        
        [[TimeeData instance] addRegistration:registration toTimer:timer];
        [TimerViewController adaptRegistrationstoRegistration:registration];
    }        
    else
    {
        [[TimeeData instance] updateRegistration:registration startTime:controller.startTime endTime:controller.endTime];
        [TimerViewController adaptRegistrationstoRegistration:registration];
    }
        
    registration.note = controller.note;
    [TimerViewController splitMultiDayRegistration:registration];
}

+ (void)handleSubOneMinuteRegistration:(Registration *)registration
{
    Registration *dummyRegistration = [NSEntityDescription insertNewObjectForEntityForName:kRegistrationEntityName inManagedObjectContext:[TimeeData context]];
    dummyRegistration.startTime = registration.startTime;
    dummyRegistration.endTime = registration.endTime;
    [registration.timerTableRow addRegistrationsObject:dummyRegistration];
    
    [[TimeeData instance] deleteRegistration:registration];
}

+ (void)absorbSubOneMinuteRegistrations:(Registration *)registration
{
    double startTimeOffset = 0;
    
    for (Registration *reg in registration.timerTableRow.registrations.allObjects)
    {
        if (reg != registration && reg.endTime != nil)
        {
            double duration = [reg.endTime timeIntervalSinceDate:reg.startTime];
            
            if (duration < 59.9)
            {
                startTimeOffset -= duration;
                [registration.timerTableRow removeRegistrationsObject:reg];
                [[TimeeData instance] deleteRegistration:reg];
            }
        }
    }
    
    if (startTimeOffset < 0)
        registration.startTime = [registration.startTime dateByAddingTimeInterval:startTimeOffset];
}

+ (void)adaptRegistrationstoRegistration:(Registration *)registration
{
    [TimerViewController absorbSubOneMinuteRegistrations:registration];
    
    if (registration.endTime != nil && [registration.endTime timeIntervalSinceDate:registration.startTime] < 59.9)
    {
        [TimerViewController handleSubOneMinuteRegistration:registration];
        return;
    }
    
    NSDate *date = [NSDate date];
    NSArray *sections = [NSArray arrayWithArray:[TimeeData instance].registrationTableSections];
    
    for (int i = 0; i < sections.count; i++)
    {
        RegistrationTableSection *section = [sections objectAtIndex:i];
        
        if ([registration.startTime timeIntervalSinceDate:section.date] > 24 * 3600)
            break;
        
        if ([(registration.endTime == nil ? date : registration.endTime) compare:section.date] == NSOrderedAscending)
            continue;
        
        NSArray *rows = section.rows.allObjects;
        
        for (int i = 0; i < rows.count; i++)
        {
            RegistrationTableRow *row = [rows objectAtIndex:i]; 
            NSArray *registrations = row.registrations.allObjects;
            
            for (int j = 0; j < registrations.count; j++)
            {
                Registration *reg = [registrations objectAtIndex:j];
                
                if (reg != registration && [(reg.endTime == nil ? date : reg.endTime) compare:registration.startTime] == NSOrderedDescending 
                    && [reg.startTime compare:(registration.endTime == nil ? date : registration.endTime)] == NSOrderedAscending)
                {
                    if ([(reg.endTime == nil ? date : reg.endTime) compare:(registration.endTime == nil ? date : registration.endTime)] == NSOrderedAscending)
                    {
                        if ([reg.startTime compare:registration.startTime] == NSOrderedAscending)
                        {
                            if (reg.endTime == nil)
                            {
                                Registration *newRegistration = [NSEntityDescription insertNewObjectForEntityForName:kRegistrationEntityName inManagedObjectContext:[TimeeData context]];
                                newRegistration.startTime = date;
                                newRegistration.endTime = nil;
                                newRegistration.note = reg.note;
                                
                                [[TimeeData instance] addRegistration:newRegistration toTimer:reg.timerSection.timer];                        
                            }
                            
                            reg.endTime = registration.startTime;
                        }
                        else
                        {
                            if (reg.endTime == nil)
                                reg.startTime = date;
                            else
                                [[TimeeData instance] deleteRegistration:reg];
                        }
                    }
                    else
                    {
                        if ([reg.startTime compare:registration.startTime] == NSOrderedAscending 
                            && !([registration.startTime timeIntervalSinceDate:reg.startTime] < 59.9))
                        {                    
                            Registration *newRegistration = [NSEntityDescription insertNewObjectForEntityForName:kRegistrationEntityName inManagedObjectContext:[TimeeData context]];
                            newRegistration.startTime = reg.startTime;
                            newRegistration.endTime = registration.startTime;
                            newRegistration.note = reg.note;
                            
                            [[TimeeData instance] addRegistration:newRegistration toTimer:reg.timerSection.timer];                        
                        }
                        
                        reg.startTime = (registration.endTime == nil ? date : registration.endTime);
                    }
                }
                
                if (reg.endTime != nil && [reg.endTime timeIntervalSinceDate:reg.startTime] < 59.9)
                    [TimerViewController handleSubOneMinuteRegistration:reg];
            }
        }
    }
}

+ (void)splitMultiDayRegistration:(Registration *)registration
{
    int secondsFromGMT = [NSTimeZone localTimeZone].secondsFromGMT;
    int secondsPerDay = 24 * 3600;
    
    NSDate *date = [NSDate date];
    int startDays = ((int)[registration.startTime  timeIntervalSinceReferenceDate] + secondsFromGMT) / secondsPerDay;
    int endDays = ((int)[(registration.endTime == nil ? date : registration.endTime) timeIntervalSinceReferenceDate] + secondsFromGMT) / secondsPerDay;
        
    NSDate *endTime = registration.endTime;
    
    Registration *registration1 = registration;
    Registration *registration2 = nil;
    
    for (int i = 0; i < endDays - startDays; i++)
    {
        registration2 = [NSEntityDescription insertNewObjectForEntityForName:kRegistrationEntityName inManagedObjectContext:[TimeeData context]];

        NSDate *splitTime = [NSDate dateWithTimeIntervalSinceReferenceDate:(startDays + i + 1) * secondsPerDay - secondsFromGMT]; 
        registration1.endTime = splitTime;
        
        if (i > 0)
            [[TimeeData instance] addRegistration:registration1 toTimer:registration.timerSection.timer];
        
        registration2.startTime = splitTime;   
        registration2.note = registration1.note;
        registration1 = registration2;
    }
    
    if (endDays != startDays)
    {
        registration2.endTime = endTime;
        
        if ([(registration2.endTime != nil ? registration2.endTime : date) timeIntervalSinceDate:registration2.startTime] > 59.9)
            [[TimeeData instance] addRegistration:registration2 toTimer:registration.timerSection.timer];
        else
            [[TimeeData context] deleteObject:registration2]; 
    }
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{    
    if (touch.view.tag == -1)
        return NO;
    
    return YES;
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
}

#pragma mark - Registration View Delegate

- (void)registrationViewControllerDidFinish:(RegistrationViewController *)controller saveContext:(BOOL)saveContext
{
    if (saveContext)
    {
        [TimerViewController saveRegistrationFromViewController:controller forTimer:self.timer];
        [self prepareDataForView];
        [self.timerView.tableView reloadData];
    }
    else 
        [self.timerView.tableView deselectRowAtIndexPath:self.timerView.tableView.indexPathForSelectedRow animated:NO];
        
    [self dismissModalViewControllerAnimated:YES];    
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *identifier = nil;
    
    if (indexPath.section == kInfoSection)
        identifier = kTimerInfoCellIdentifier;
    else if (indexPath.section > kRegistrationsSection)
        identifier = kTimerRegistrationCellIdentifier;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
    {
        if ([identifier isEqual: kTimerInfoCellIdentifier])
        {
            [[NSBundle mainBundle] loadNibNamed:kTimerInfoCellNibName owner:self options:nil];
            cell = self.infoCell;
            
            TimerInfoCellView *cellView = (TimerInfoCellView *)[cell.contentView.subviews objectAtIndex:0];
            
            cellView.textField.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
            cellView.textField.textColor = [AppColors black];
            cellView.textField.layer.shadowOpacity = 1.0;   
            cellView.textField.layer.shadowRadius = 0.0;
            cellView.textField.layer.shadowColor = [UIColor whiteColor].CGColor;
            cellView.textField.layer.shadowOffset = CGSizeMake(0.0, 1.0);
            
            cellView.onDeleteLabel.font = cellView.textField.font;
            cellView.suggestionLabel.font = cellView.textField.font;
            
            cellView.swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeRecognized:)];
            cellView.swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft;        
            [cellView addGestureRecognizer:cellView.swipeRecognizer];
            
            if ([[UIScreen mainScreen] scale] == 2.0)
            {
                CGRect frame = cellView.onDeleteLabel.frame;
                cellView.onDeleteLabel.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
                
                frame = cellView.suggestionLabel.frame;
                cellView.suggestionLabel.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
            }
        }
        else if ([identifier isEqual: kTimerRegistrationCellIdentifier])
        {
            [[NSBundle mainBundle] loadNibNamed:kTimerRegistrationCellNibName owner:self options:nil];
            cell = self.registrationCell;
            
            TimerRegistrationCellView *cellView = (TimerRegistrationCellView *)[cell.contentView.subviews objectAtIndex:0];
            
            cellView.timespanLabel.font = cellView.durationLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
            cellView.timespanLabel.textColor = cellView.durationLabel.textColor = [AppColors black];
            
            cellView.swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeRecognized:)];
            cellView.swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft;        
            [cellView addGestureRecognizer:cellView.swipeRecognizer];
        }
    }
    
    if (indexPath.section == kInfoSection) 
    {
        TimerInfo *info = [self.info objectAtIndex:indexPath.row];
        
        TimerInfoCellView *cellView = (TimerInfoCellView *)[cell.contentView.subviews objectAtIndex:0];
        cellView.textField.text = info.title;
        cellView.textField.tag = indexPath.row;
        cellView.textField.enabled = YES;
        cellView.deleteButton.alpha = 0.0;
        cellView.textField.alpha = 1.0;
        cellView.onDeleteLabel.alpha = 0.0;
        cellView.swipeRecognizer.enabled = YES;
        cellView.tapRecognizer.enabled = NO;
        
        if (self.timer.creationTime == nil && self.textFieldBeingEdited == nil)
            [cellView.textField becomeFirstResponder];
    } 
    else if (indexPath.section == kRegistrationsSection)
    {
        if (indexPath.row == 0)
            return self.totalCell;
        else 
            return self.currentCell;
    }
    else
    {
        TimerSection *section = [self getSectionForIndexPathSection:indexPath.section];
        NSArray *sortedRegistrations = [[self getCacheForSection:section] objectForKey:@"sortedRegistrations"];
        Registration *registration = [sortedRegistrations objectAtIndex:indexPath.row]; 
        
        NSString *startTime = [self.timeFormatter stringFromDate:registration.startTime];
        NSString *endTime = registration.endTime != nil ? [self.timeFormatter stringFromDate:registration.endTime] : @"";
        
        TimerRegistrationCellView *cellView = (TimerRegistrationCellView *)[cell.contentView.subviews objectAtIndex:0];
        cellView.timespanLabel.text = [NSString stringWithFormat:@"%@ – %@", startTime, endTime];            
        
        int total = [(registration.endTime != nil ? registration.endTime : [NSDate date]) timeIntervalSinceDate:registration.startTime];
        int hours = total / 3600;
        int minutes = (total - hours * 3600) / 60;
        
        cellView.durationLabel.text = [NSString stringWithFormat:@"%d:%@%d", hours, minutes < 10 ? @"0" : @"", minutes]; 
        cellView.hasNoteImage.hidden = registration.note == nil;
        cellView.hasNoteImage.alpha = 1.0;
        cellView.deleteButton.alpha = 0.0;
        cellView.durationLabel.alpha = 1.0;
        cellView.swipeRecognizer.enabled = YES;
        cellView.tapRecognizer.enabled = NO;
        
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kInfoSection)
        return self.info.count;
    
    if (section == kRegistrationsSection)
        return 2;
    
    return [self getSectionForIndexPathSection:section].registrations.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 34.0)];
    view.backgroundColor = [AppColors darkGold];
    
    UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 0, 200.0, 34.0)];
    leftLabel.backgroundColor = [UIColor clearColor];
    leftLabel.textColor = [AppColors grey];
    leftLabel.font = [UIFont fontWithName:@"SourceSansPro-It" size:15];

    [view addSubview:leftLabel];
    
    if (section == kInfoSection || section == kRegistrationsSection)
    {        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"plus_selected"] forState:UIControlStateHighlighted];
        button.adjustsImageWhenHighlighted = NO;

        if (section == kInfoSection)
        {
            leftLabel.text = @"INFO";
            button.frame = CGRectMake(272.0, 0.0, 42.0, 34.0);
            [button addTarget:self action:@selector(addInfo) forControlEvents:UIControlEventTouchUpInside];            
        }
        
        if (section == kRegistrationsSection)
        {
            leftLabel.text = @"REGISTRATIONS";
            button.frame = CGRectMake(272.0, 0.0, 42.0, 34.0);
            [button addTarget:self action:@selector(addRegistration) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [view addSubview:button];        
        return view;
    }
    else
    {
        UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(191.0, 0.0, 80.0, 34.0)];
        rightLabel.backgroundColor = leftLabel.backgroundColor;
        rightLabel.textColor = leftLabel.textColor;
        rightLabel.shadowColor = leftLabel.shadowColor;
        rightLabel.shadowOffset = leftLabel.shadowOffset;
        rightLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:16];
        
        TimerSection *timerSection = [self getSectionForIndexPathSection:section];
        leftLabel.text = [[self.dateFormatter stringFromDate:timerSection.date] uppercaseString];
        
        NSMutableDictionary *cache = [self getCacheForSection:[self getSectionForIndexPathSection:section]];
        NSArray *sortedRegistrations = [cache objectForKey:@"sortedRegistrations"];
        rightLabel.text = [TimerViewController getTotalTextInHeaderForSection:sortedRegistrations];
        rightLabel.textAlignment = UITextAlignmentRight;
    
        [view addSubview:rightLabel];        
        [cache setObject:rightLabel forKey:@"totalLabel"];
        
        return view;
    }
    
    return nil;
}

#pragma mark - Table View Delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UIView *cellView = [cell.contentView.subviews objectAtIndex:0];
    
    if ([cellView isKindOfClass:[TimerRegistrationCellView class]])
    {
        if (((TimerRegistrationCellView *)cellView).tapRecognizer.enabled)
            return nil;
    }
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   
    if (indexPath.section == kRegistrationsSection)
    {
        TimerTotalCellView *totalCellView = (TimerTotalCellView *)[self.totalCell.contentView.subviews objectAtIndex:0];
        TimerCurrentCellView *currentCellView = (TimerCurrentCellView *)[self.currentCell.contentView.subviews objectAtIndex:0];

        if (indexPath.row == 0 && [self.timer.timerTableSummaryType isEqualToString:@"current"])
        {
            self.timer.timerTableSummaryType = @"total";
            totalCellView.selectionMarker.hidden = NO;
            currentCellView.selectionMarker.hidden = YES;
        }
        else if (indexPath.row == 1 && [self.timer.timerTableSummaryType isEqualToString:@"total"])
        {
            self.timer.timerTableSummaryType = @"current";
            totalCellView.selectionMarker.hidden = YES;
            currentCellView.selectionMarker.hidden = NO;
        }
    }
    else if (indexPath.section > kRegistrationsSection)
    {
        RegistrationViewController *viewController = (RegistrationViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Registration"];
        BOOL cached = viewController != nil;
        
        if (viewController == nil)
        {
            viewController = [[RegistrationViewController alloc] initWithNibName:kRegistrationViewNibName bundle:[NSBundle mainBundle]];
            viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [[ViewControllerCache instance] addViewController:viewController forName:@"Registration"];
        }
        
        TimerSection *section = [self getSectionForIndexPathSection:indexPath.section];
        NSArray *sortedRegistrations = [[self getCacheForSection:section] objectForKey:@"sortedRegistrations"];
        Registration *registration = [sortedRegistrations objectAtIndex:indexPath.row];
        
        if (cached)
        {
            viewController.selectedRow = 0;
            viewController.registrationView.doneButton.enabled = YES;
        }
        
        viewController.delegate = self;
        viewController.startTime = registration.startTime;
        viewController.endTime = registration.endTime;
        viewController.note = registration.note;
        viewController.objectId = registration.objectID;
        
        [viewController.registrationView.tableView reloadData];
        [self presentModalViewController:viewController animated:YES]; 
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1 + (self.timer.creationTime != nil ? self.timer.sections.count + 1 : 0);
}

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString *suggestion = [[InfoCache instance] getTitleForPrefix:newText];
    
    UIView *view = textField;
    while (![view isKindOfClass:[TimerInfoCellView class]]) {
        view = [view superview];
    }
    
    TimerInfoCellView *cellView = (TimerInfoCellView *)view;
    UILabel *label = cellView.suggestionLabel;
    
    if (suggestion != nil && ![suggestion isEqualToString:newText])
    {
        UILabel *placeholder = [[UILabel alloc] init];
        placeholder.text = newText;
        placeholder.font = cellView.textField.font;
        [placeholder sizeToFit];
        
        NSInteger offset = placeholder.frame.size.width;
        CGRect frame = CGRectMake(textField.frame.origin.x + offset, textField.frame.origin.y, textField.frame.size.width - offset, textField.frame.size.height - 2);
        NSString *completion = [suggestion substringFromIndex:newText.length];
        
        label.frame = frame;
        label.text = completion;
        
        cellView.acceptButton.frame = frame;
        cellView.acceptButton.hidden = NO;
    }
    else
    {
        [self clearSuggestionLabel:label inTextField:textField];
    }
    
    cellView.clearButton.hidden = newText.length == 0;
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIView *view = textField;
    while (![view isKindOfClass:[TimerInfoCellView class]]) {
        view = [view superview];
    }
    
    TimerInfoCellView *cellView = (TimerInfoCellView *)view;
    cellView.clearButton.hidden = textField.text.length == 0;
    self.textFieldBeingEdited = textField;
    [self performSelector:@selector(setFrameWithDelay) withObject:nil afterDelay:1];
}

- (void)setFrameWithDelay
{
    [self.timerView.tableView setFrame:CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45 - 216)];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UIView *view = textField;
    while (![view isKindOfClass:[TimerInfoCellView class]]) {
        view = [view superview];
    }
    
    TimerInfoCellView *cellView = (TimerInfoCellView *)view;
    cellView.clearButton.hidden = YES;
    
    TimerInfo *info = [self.info objectAtIndex:textField.tag];
    info.title = textField.text;    
    [self.textFieldBeingEdited resignFirstResponder];    
    self.textFieldBeingEdited = nil;
    
    UILabel *label = cellView.suggestionLabel;
    [self clearSuggestionLabel:label inTextField:textField];
}

#pragma mark - View lifecycle

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    self.timerView = (TimerView *)self.view; 
    self.timerView.title.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.timerView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.timerView.tableView.frame;
        self.timerView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
    }

    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    
    self.timeFormatter = [[NSDateFormatter alloc] init];
    self.timeFormatter.timeStyle = NSDateFormatterShortStyle;
    self.timeFormatter.dateStyle = NSDateFormatterNoStyle;
    
    [self prepareDataForView];    
    
    [[NSBundle mainBundle] loadNibNamed:kTimerTotalCellNibName owner:self options:nil];
    TimerTotalCellView *totalCellView = (TimerTotalCellView *)[self.totalCell.contentView.subviews objectAtIndex:0];
    totalCellView.timeLabel.font = totalCellView.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    totalCellView.timeLabel.textColor = totalCellView.titleLabel.textColor = [AppColors black];
    
    [[NSBundle mainBundle] loadNibNamed:kTimerCurrentCellNibName owner:self options:nil];
    TimerCurrentCellView *currentCellView = (TimerCurrentCellView *)[self.currentCell.contentView.subviews objectAtIndex:0];
    currentCellView.timeLabel.font = currentCellView.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    currentCellView.timeLabel.textColor = currentCellView.titleLabel.textColor = [AppColors black];
    
    if ([[UIScreen mainScreen] scale] == 2.0)
    {
        CGRect frame = totalCellView.selectionMarker.frame;
        totalCellView.selectionMarker.frame = CGRectMake(frame.origin.x, frame.origin.y - 0.5, frame.size.width, frame.size.height);
        currentCellView.selectionMarker.frame = CGRectMake(frame.origin.x, frame.origin.y - 0.5, frame.size.width, frame.size.height);
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    TimerTotalCellView *totalCellView = (TimerTotalCellView *)[self.totalCell.contentView.subviews objectAtIndex:0];
    TimerCurrentCellView *currentCellView = (TimerCurrentCellView *)[self.currentCell.contentView.subviews objectAtIndex:0];
    
    if ([self.timer.timerTableSummaryType isEqualToString: @"current"])
    {
        currentCellView.selectionMarker.hidden = NO;
        totalCellView.selectionMarker.hidden = YES;
    }
    else
    {
        currentCellView.selectionMarker.hidden = YES;
        totalCellView.selectionMarker.hidden = NO;
    }

    [self refreshTotal];
    [self refreshCurrent];
    
    if (self.dateScrollOffset != nil)
        [self scrollToDate:self.dateScrollOffset];
    
    self.timerView.title.text = self.timer.creationTime == nil ? @"Add Timer" : @"Timer";
    
    if (self.timer.creationTime == nil && self.textFieldBeingEdited == nil)
    {
        UITableViewCell *cell = [self.timerView.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [((TimerInfoCellView *)[cell.contentView.subviews objectAtIndex:0]).textField becomeFirstResponder];
    }
}

- (void)prepareDataForView
{
    self.info = [NSMutableArray arrayWithArray:[self.timer.info allObjects]]; 
    
    [self.info sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((TimerInfo *)obj1).index compare:((TimerInfo *)obj2).index];
    }];
    
    self.sections = [NSMutableArray arrayWithArray:self.timer.sections.allObjects];    
    self.sectionCache = [NSMutableDictionary dictionaryWithCapacity:self.sections.count];
    
    [self.sections sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((TimerSection *)obj2).date compare:((TimerSection *)obj1).date];
    }];       
    
    self.initialTitles = [[NSMutableArray alloc] initWithCapacity:self.info.count];    
    
    for (TimerInfo *info in self.info)
        [self.initialTitles addObject:info.title];
    
    self.initialRegistrationTableSections = [NSMutableArray arrayWithArray:[TimeeData instance].registrationTableSections];
}

@end

