//
//  RedmineViewController.m
//  Timee
//
//  Created by Morten Hornbech on 06/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "ActivitiesViewController.h"
#import "AppColors.h"
#import "Integration.h"
#import "Registration.h"
#import "RedmineInfo.h"
#import "RedmineView.h"
#import "RedmineViewController.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerInfo.h"
#import "TimerSection.h"
#import "TimerTableCellView.h"
#import "TimerTableRow.h"
#import "TimerTableViewController.h"
#import "TimerView.h"
#import "TimerViewController.h"
#import "ViewControllerCache.h"

#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>
#include <libkern/OSAtomic.h>

#define kTimerViewNibName                   @"TimerView"
#define kTimerTableViewCellNibName          @"RedmineTableCell"
#define kTimerTableViewCellIdentifier       @"RedmineTimerTableCell"

@interface RedmineViewController ()

@end

@implementation RedmineViewController

@synthesize redmineView = _redmineView;
@synthesize timerTableRows = _timerTableRows;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;
@synthesize sections = _sections;
@synthesize activityIndicator = _activityIndicator;
@synthesize cell = _cell;
@synthesize serverUrl = _serverUrl;
@synthesize username = _username;
@synthesize password = _password;
@synthesize request = _request;
@synthesize dateFormatter = _dateFormatter;
@synthesize numberFormatter = _numberFormatter;
@synthesize alertsByIssueId = _alertsByIssueId;
@synthesize currentConnection = _currentConnection;
@synthesize xmlCharacterMap = _xmlCharacterMap;
@synthesize cancelDelegate = _cancelDelegate;
@synthesize doneDelegate = _doneDelegate;

dispatch_queue_t queue;
BOOL errorHandled;
BOOL responseReceived;
BOOL isUploading;
int32_t verifiedIssues;
int32_t pendingRequests;
NSInteger totalRegistrations;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    queue = dispatch_queue_create(nil, NULL);
    
    self.redmineView = (RedmineView *)self.view;
    self.redmineView.tableView.backgroundColor = [AppColors gold];   
    self.redmineView.title.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.redmineView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.redmineView.tableView.frame;
        self.redmineView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
    }

    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    self.numberFormatter.locale = usLocale;
    self.numberFormatter.positiveFormat = @"#0.##";
    
    self.xmlCharacterMap = [NSDictionary dictionaryWithObjectsAndKeys:@"\"", @"quot", @"&", @"amp", @"'", @"apos", @"<", @"lt", @">", @"gt", nil];
    
    self.redmineView.progressLabel.textColor = [AppColors gold];
    self.redmineView.progressLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18];    
}

- (void)viewWillAppear:(BOOL)animated
{
    isUploading = NO;
    errorHandled = NO;
    responseReceived = NO;
    verifiedIssues = 0;
    pendingRequests = 0;

    totalRegistrations = 0;
    for (TimerSection *section in self.sections)
        totalRegistrations += section.registrations.count;
    
    [self enableUserInteraction];
    self.redmineView.progressLabel.text = @"";
    self.redmineView.doneButton.alpha = 1;
    self.redmineView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Actions

- (IBAction)cancel
{
    [self.currentConnection cancel];
    [self.cancelDelegate redmineViewControllerDidFinish:self];
}

- (IBAction)done
{
    self.redmineView.progressLabel.text = @"0%";
    self.redmineView.doneButton.alpha = 0;
    [self disableUserInteraction];
    
    [self uploadTimeEntries];
}

- (IBAction)textFieldDone
{
    UITableViewCell *cell = [self.redmineView.tableView cellForRowAtIndexPath:self.redmineView.tableView.indexPathForSelectedRow];
    [((UITextField *)[cell viewWithTag:1]) resignFirstResponder];
    self.redmineView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
}

- (IBAction)onShowTimerButtonTapped:(id)sender
{
    UIView *view = (UIView *)sender;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.redmineView.tableView indexPathForCell:cell];    
    TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
    
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

#pragma mark - Instance Methods

- (void)disableUserInteraction
{
    self.redmineView.tableView.userInteractionEnabled = NO;
    self.redmineView.doneButton.enabled = NO;
    self.redmineView.cancelButton.enabled = NO;
}

- (void)enableUserInteraction
{
    self.redmineView.tableView.userInteractionEnabled = YES;
    self.redmineView.doneButton.enabled = YES;
    self.redmineView.cancelButton.enabled = YES;
}

- (void)refreshSettings
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.serverUrl = [NSURL URLWithString:[userDefaults stringForKey:@"redmineUrl"]];
    self.username = [userDefaults stringForKey:@"redmineUsername"];
    self.password = [userDefaults stringForKey:@"redminePassword"];
    self.request = [NSMutableURLRequest requestWithURL:self.serverUrl];
}

- (void)getIssueSubjectAsync:(NSString *)issueId
{
    [self.request setURL:[self.serverUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"issues/%@.xml", issueId]]];
    self.currentConnection = [NSURLConnection connectionWithRequest:self.request delegate:self];
}

- (void)uploadTimeEntries
{    
    for (TimerTableRow *row in self.timerTableRows)
    {
        NSString *title = nil;
        NSString *message = nil;
        
        if (row.timer.redmine.activityId == nil)
        {            
            if (row.timer.redmine.issueId == nil)
            {
                title = @"Missing issue #!";
                message = @"One or more timers do not have an associated issue #.";
            }
            else 
            {
                title = @"Missing activity!";
                message = [NSString stringWithFormat:@"The timer associated with issue #%@ does have an associated activity.", row.timer.redmine.issueId];
            }
        }
        
        if (title != nil)
        {
            [self enableUserInteraction];
            self.redmineView.progressLabel.text = @"";
            self.redmineView.doneButton.alpha = 1;
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];            
            return;
        }
    }
    
    isUploading = YES;
    errorHandled = NO;
    responseReceived = NO;
    verifiedIssues = 0;
    pendingRequests = 0;
    
    for (TimerTableRow *row in self.timerTableRows)
        [self getIssueSubjectAsync:row.timer.redmine.issueId];    
}

- (void)uploadTimeEntriesForSection:(TimerSection *)section
{
    NSString *issueId = section.timer.redmine.issueId;
    NSString *activityId = section.timer.redmine.activityId;
    
    double timeWithoutNotes = 0;
    
    for (Registration *registration in section.registrations)
    {
        if (registration.endTime != nil)
        {
            double amount = [registration.endTime timeIntervalSinceDate:registration.startTime] / 3600;
            
            if (registration.note != nil)
            {
                NSString *note = [[registration.note stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                [self uploadTimeEntryWithIssueId:issueId activityId:activityId date:section.date amount:[NSNumber numberWithDouble:amount] comments:note];
            }
            else 
            {
                timeWithoutNotes += amount;
            }
        }
    }
    
    if (timeWithoutNotes > 0)
    {
        [self uploadTimeEntryWithIssueId:issueId activityId:activityId date:section.date amount:[NSNumber numberWithDouble:timeWithoutNotes] comments:@""];
    }
}

- (void)uploadTimeEntryWithIssueId:(NSString *)issueId activityId:(NSString *)activityId date:(NSDate *)date amount:(NSNumber *)amount comments:(NSString *)comments
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self.serverUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"/issues/%@/time_entries.json", issueId]]];
    
    NSString *post = [NSString stringWithFormat:@"{\"time_entry\":{\"issue_id\":%@,\"spent_on\":\"%@\",\"hours\":%@,\"activity_id\":%@,\"comments\":\"%@\"}}", issueId, [self.dateFormatter stringFromDate:date], [self.numberFormatter stringFromNumber:amount], activityId, comments];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (isUploading)
        OSAtomicIncrement32(&pendingRequests);
    
    self.currentConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.timerTableRows.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TimerTableRow *row = [self.timerTableRows objectAtIndex:section];
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 34.0)];
    view.backgroundColor = [AppColors darkGold];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 0.0, 240.0, 34.0)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [AppColors grey];
    label.font = [UIFont fontWithName:@"SourceSansPro-It" size:15];
    [view addSubview:label];
    
    view.tag = section;
    
    dispatch_async(queue, ^{
        NSString *issueId = row.timer.redmine.issueId;
        NSString *issueSubject = row.timer.redmine.issueSubject;
        NSString *activityId = row.timer.redmine.activityId;
        
        if (view.tag == section)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (issueId == nil)
                    label.text = @"FILL IN ISSUE #";
                else if (activityId == nil)
                    label.text = @"SELECT ACTIVITY";
                else
                    label.text = [issueSubject uppercaseString];
            });
        }
    });
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
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
        
        cellView.titleLabel.text = cellView.subtitleLabel.text = cellView.timeLabel.text = @"";
        cellView.detailsButton.hidden = YES;
        cell.userInteractionEnabled = NO;
        [cellView.activityIndicator startAnimating];
        
        TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
        cellView.tag = indexPath.section;
        
        dispatch_async(queue, ^{
            NSArray *labelTexts = [TimerTableViewController getTitleLabelTexts:row.timer.info.allObjects];
            NSArray *runningTime = [TimerTableViewController getRunningTime:row ofType:@"total" between:self.startTime and:self.endTime];
            
            if (cellView.tag == indexPath.section)
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
        
        return cell;
    }
    else
    {
        NSString *identifier = indexPath.row == 1 ? @"IssueCell" : @"ActivityCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            cell.frame = CGRectMake(0, 0, 320, 44);
            cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_small"]];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 280, 44)];
            label.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:17];
            label.textColor = [AppColors black];
            label.shadowColor = [UIColor whiteColor];
            label.shadowOffset = CGSizeMake(0, 1);
            label.backgroundColor = [UIColor clearColor];
            label.text = indexPath.row == 1 ? @"Issue #" : @"Activity";
            label.tag = -1;
            [cell addSubview:label];
            
            if (indexPath.row == 1)
            {
                UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(111, 0, 160, 44)];
                textField.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
                textField.layer.shadowOpacity = 1.0;
                textField.layer.shadowRadius = 0.0;
                textField.layer.shadowColor = [UIColor whiteColor].CGColor;
                textField.layer.shadowOffset = CGSizeMake(0.0, 1.0);
                textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                textField.returnKeyType = UIReturnKeyDone;
                textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                textField.textAlignment = UITextAlignmentRight;
                textField.textColor = [AppColors black];
                textField.delegate = self;
                [textField addTarget:self action:@selector(textFieldDone) forControlEvents:UIControlEventEditingDidEndOnExit];
                textField.tag = 1;
                [cell addSubview:textField];
                
                UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                activityIndicator.frame = CGRectMake(251, 12, 20, 20);
                activityIndicator.hidesWhenStopped = YES;
                activityIndicator.tag = 2;
                [cell addSubview:activityIndicator];
                
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            else
            {
                UILabel *activity = [[UILabel alloc] initWithFrame:CGRectMake(111, 0, 160, 44)];
                activity.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
                activity.textColor = [AppColors black];
                activity.shadowColor = [UIColor whiteColor];
                activity.shadowOffset = CGSizeMake(0, 1);
                activity.backgroundColor = [UIColor clearColor];
                activity.textAlignment = UITextAlignmentRight;
                activity.tag = 1;
                [cell addSubview:activity];
                
                cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_small_selected"]];
            }
        }
        
        TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
        cell.backgroundView.tag = indexPath.section + 3;
        
        dispatch_async(queue, ^{
            NSString *issueId = row.timer.redmine.issueId;
            NSString *activityName = row.timer.redmine.activityId != nil ? row.timer.redmine.activityName : @"";
            
            if (cell.backgroundView.tag == indexPath.section + 3)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (indexPath.row == 1)
                    {
                        UITextField *textField = (UITextField *)[cell viewWithTag:1];
                        UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:2];
                        
                        textField.text = issueId != nil ? issueId : @"";
                        textField.alpha = 1;
                        [activityIndicator stopAnimating];
                    }
                    else
                    {
                        UILabel *label1 = (UILabel *)[cell viewWithTag:1];
                        UILabel *label2 = (UILabel *)[cell viewWithTag:-1];
                        cell.userInteractionEnabled = issueId != nil;
                        
                        if (issueId != nil)
                        {
                            label1.text = activityName;
                            label1.alpha = label2.alpha = 1;
                        }
                        else
                        {
                            label1.text = @"";
                            label1.alpha = label2.alpha = 0.5;
                        }
                    }
                });
            }
        });
        
        return cell;
    }
    
    return nil;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        return 63;
    
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UITextField *textField = (UITextField *)[cell viewWithTag:1];
        [textField becomeFirstResponder];
    }
    else if (indexPath.row == 2)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:indexPath.section]];
        UITextField *textField = (UITextField *)[cell viewWithTag:1];
        
        if (textField.isFirstResponder)
            [textField resignFirstResponder];
        
        ActivitiesViewController *viewController = (ActivitiesViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Activities"];
        
        if (viewController == nil)
        {
            viewController = [[ActivitiesViewController alloc] initWithNibName:@"ActivitiesView" bundle:[NSBundle mainBundle]];
            viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [[ViewControllerCache instance] addViewController:viewController forName:@"Activities"];
        }
        
        TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
        
        viewController.redmineViewController = self;
        viewController.redmine = row.timer.redmine;
        
        [self presentModalViewController:viewController animated:YES]; 
    }
}

#pragma mark - Activities View Delegate

- (void)activitiesViewControllerDidFinish:(ActivitiesViewController *)controller
{
    [self.redmineView.tableView deselectRowAtIndexPath:self.redmineView.tableView.indexPathForSelectedRow animated:NO];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Timer View Delegate

- (void)timerViewControllerDidFinish:(TimerViewController *)controller
{
    self.sections = [SelectRegistrationsViewController getSelectedTimerSections:self.timerTableRows startTime:self.startTime endTime:self.endTime];
    self.timerTableRows = [SelectRegistrationsViewController getTimerTableRowsWithRegistrationsBetween:self.startTime and:self.endTime];
    [self.redmineView.tableView reloadData];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIView *view = textField;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    [self.redmineView.tableView selectRowAtIndexPath:[self.redmineView.tableView indexPathForCell:cell] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self performSelector:@selector(setFrameAndScrollWithDelay) withObject:nil afterDelay:0.5];    
    
    self.redmineView.doneButton.enabled = NO;
    self.redmineView.cancelButton.enabled = NO;
}

- (void)setFrameAndScrollWithDelay
{
    NSIndexPath *indexPath = self.redmineView.tableView.indexPathForSelectedRow;
    NSIndexPath *scrollTo = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
    self.redmineView.tableView.frame = CGRectMake(0.0, 45.0, 320.0, [[UIScreen mainScreen] bounds].size.height - 45 - 216);
    [self.redmineView.tableView scrollToRowAtIndexPath:scrollTo atScrollPosition:UITableViewScrollPositionTop animated:YES];
    self.redmineView.tableView.scrollEnabled = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UIView *view = textField;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.redmineView.tableView indexPathForCell:cell];
    TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
    
    if (textField.text.length != 0)
    {    
        if (![textField.text isEqualToString:row.timer.redmine.issueId])
        {
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:2];
            
            textField.alpha = 0;
            [activityIndicator startAnimating];            
            
            isUploading = NO;
            errorHandled = NO;
            responseReceived = NO;
            [self getIssueSubjectAsync:textField.text];
        }
        else 
        {
            self.redmineView.tableView.scrollEnabled = YES;
            self.redmineView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
        }
    }
    else 
    {        
        row.timer.redmine.issueId = nil;
        row.timer.redmine.activityId = nil;
        row.timer.redmine.activityName = nil;
        
        [TimeeData commit];
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
        [self.redmineView.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        
        self.redmineView.tableView.scrollEnabled = YES;
        self.redmineView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
    }
    
    self.redmineView.doneButton.enabled = YES;
    self.redmineView.cancelButton.enabled = YES;
}

#pragma mark - NSURLConnection Data Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    responseReceived = YES;
    
    if ([response.URL.absoluteString rangeOfString:@"time_entries"].length != 0)
    {
        int percent = (totalRegistrations - pendingRequests + 1) * 100 / totalRegistrations;
        NSString *text = [NSString stringWithFormat:@"%d%%", percent];
        
        if (![self.redmineView.progressLabel.text isEqualToString:text])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.redmineView.progressLabel.text = text;
            });
        }

        NSInteger index = self.serverUrl.absoluteString.length + @"/issues/".length;
        NSString *issueId = [response.URL.absoluteString substringFromIndex:index];
        issueId = [issueId substringToIndex:issueId.length - @"/time_entries.json".length];
        
        UIAlertView *alertView = [Integration verifyIssueId:issueId fromResponse:(NSHTTPURLResponse *)response];        
        
        if (alertView != nil)
            [self.alertsByIssueId setValue:alertView forKey:issueId];
        
        if (OSAtomicDecrement32(&pendingRequests) == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                for (NSString *key in self.alertsByIssueId.allKeys)
                    [(UIAlertView *)[self.alertsByIssueId valueForKey:key] show];
                
                [self.doneDelegate selectRegistrationsViewControllerDidFinish:nil];
            });
        }
        
        return;
    }

    if (isUploading)
    {
        if (!errorHandled)
        {
            NSInteger index = self.serverUrl.absoluteString.length + @"/issues/".length;
            NSString *issueId = [response.URL.absoluteString substringFromIndex:index];
            issueId = [issueId substringToIndex:issueId.length - 4];
            
            UIAlertView *alertView = [Integration verifyIssueId:issueId fromResponse:(NSHTTPURLResponse *)response];
            
            if (alertView != nil)
            {            
                self.redmineView.progressLabel.text = @"";
                self.redmineView.doneButton.alpha = 1;
                [self enableUserInteraction];
                
                errorHandled = YES;
                [alertView show];          
            }
            else 
            {
                if (OSAtomicIncrement32(&verifiedIssues) == self.timerTableRows.count)
                {
                    self.alertsByIssueId = [[NSMutableDictionary alloc] init];
                    
                    for (TimerSection *section in self.sections)
                        [self uploadTimeEntriesForSection:section];
                }
            }
        }
    }
    else
    {
        NSIndexPath *indexPath = self.redmineView.tableView.indexPathForSelectedRow;
        UITableViewCell *cell = [self.redmineView.tableView cellForRowAtIndexPath:indexPath];
        UITextField *textField = (UITextField *)[cell viewWithTag:1];
        TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
        UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:2];
        
        [activityIndicator stopAnimating];
        textField.alpha = 1;
        self.redmineView.tableView.scrollEnabled = YES; 
        self.redmineView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
        
        UIAlertView *alertView = [Integration verifyIssueId:textField.text fromResponse:(NSHTTPURLResponse *)response];
        
        if (alertView != nil)
        {
            textField.text = row.timer.redmine.issueId;
            
            if (!errorHandled)
            {
                errorHandled = YES;
                [alertView show];
            }
        }
        else
        {
            if (row.timer.redmine == nil)
                row.timer.redmine = [NSEntityDescription insertNewObjectForEntityForName:@"RedmineInfo" inManagedObjectContext:[TimeeData context]];
            
            row.timer.redmine.issueId = textField.text;
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
    if (!isUploading)
    {
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];    
        NSRange range = [content rangeOfString:@"subject>"];
        
        if (range.length != 0)
        {
            content = [content substringFromIndex:range.location + range.length];
            range = [content rangeOfString:@"<"];
            
            NSIndexPath *indexPath = self.redmineView.tableView.indexPathForSelectedRow;
            TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
            
            content = [content substringToIndex:range.location];
            
            for (NSString *key in self.xmlCharacterMap.allKeys)
            {
                content = [content stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"&%@;", key] withString:[self.xmlCharacterMap valueForKey:key]];
            }
            
            row.timer.redmine.issueSubject = content;
                 
            [TimeeData commit];
            
            [self.redmineView.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (responseReceived)
        return;
    
    [self.redmineView.tableView reloadData];
    [self enableUserInteraction];
    self.redmineView.progressLabel.text = @"";
    self.redmineView.doneButton.alpha = 1;
    self.redmineView.tableView.scrollEnabled = YES; 
    self.redmineView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No response!" message:@"No server responded at the specified URL." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    if (!errorHandled)
    {
        errorHandled = YES;
        [alertView show];
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace 
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] 
    || [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge 
{    
    responseReceived = YES;
    
    if (challenge.previousFailureCount == 0)
    {
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
        {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
            [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
        else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic])
        {
            NSURLCredential *credentials = [[NSURLCredential alloc] initWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceForSession];
            
            [[challenge sender] useCredential:credentials forAuthenticationChallenge:challenge];
        }
        else 
        {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];            
        }
    }
    else 
    {
        [[challenge sender] cancelAuthenticationChallenge:challenge];            
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Authentication failed!" message:@"Authentication with the server was unsuccessful. Check your credentials." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        if (!isUploading)
            [self.redmineView.tableView reloadData];
        
        if (!errorHandled)
        {
            [self enableUserInteraction];
            self.redmineView.progressLabel.text = @"";
            self.redmineView.doneButton.alpha = 1;
            self.redmineView.doneButton.enabled = YES;
            self.redmineView.cancelButton.enabled = YES;
            self.redmineView.tableView.scrollEnabled = YES;
            
            errorHandled = YES;
            [alertView show];
        }
    }
}

@end
