//
//  JiraViewController.m
//  Timee
//
//  Created by Morten Hornbech on 06/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "ActivitiesViewController.h"
#import "AppColors.h"
#import "Registration.h"
#import "Integration.h"
#import "JiraInfo.h"
#import "JiraView.h"
#import "JiraViewController.h"
#import "NSData+Additions.h"
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
#define kTimerTableViewCellNibName          @"JiraTableCell"
#define kTimerTableViewCellIdentifier       @"JiraTimerTableCell"

@interface JiraViewController ()

@end

@implementation JiraViewController

@synthesize jiraView = _jiraView;
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
    
    self.jiraView = (JiraView *)self.view;
    self.jiraView.tableView.backgroundColor = [AppColors gold];   
    self.jiraView.title.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.jiraView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.jiraView.tableView.frame;
        self.jiraView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
    }

    self.dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    self.dateFormatter.locale = enUSPOSIXLocale;
    self.dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSZ";
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    self.numberFormatter.locale = usLocale;
    self.numberFormatter.positiveFormat = @"#0.##";
    
    self.jiraView.progressLabel.textColor = [AppColors gold];
    self.jiraView.progressLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18];
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
    self.jiraView.progressLabel.text = @"";
    self.jiraView.doneButton.alpha = 1;
    self.jiraView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Actions

- (IBAction)cancel
{
    [self.currentConnection cancel];
    [self.cancelDelegate jiraViewControllerDidFinish:self];
}

- (IBAction)done
{
    self.jiraView.doneButton.alpha = 0;
    self.jiraView.progressLabel.text = @"0%";
    [self disableUserInteraction];
    
    [self uploadTimeEntries];
}

- (IBAction)textFieldDone
{
    UITableViewCell *cell = [self.jiraView.tableView cellForRowAtIndexPath:self.jiraView.tableView.indexPathForSelectedRow];
    [((UITextField *)[cell viewWithTag:1]) resignFirstResponder];
    self.jiraView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
}

- (IBAction)onShowTimerButtonTapped:(id)sender
{
    UIView *view = (UIView *)sender;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.jiraView.tableView indexPathForCell:cell];    
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
    self.jiraView.tableView.userInteractionEnabled = NO;
    self.jiraView.doneButton.enabled = NO;
    self.jiraView.cancelButton.enabled = NO;
}

- (void)enableUserInteraction
{
    self.jiraView.tableView.userInteractionEnabled = YES;
    self.jiraView.doneButton.enabled = YES;
    self.jiraView.cancelButton.enabled = YES;
}

- (void)refreshSettings
{    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.serverUrl = [NSURL URLWithString:[userDefaults stringForKey:@"jiraUrl"]];
    self.username = [userDefaults stringForKey:@"jiraUsername"];
    self.password = [userDefaults stringForKey:@"jiraPassword"];
    self.request = [NSMutableURLRequest requestWithURL:self.serverUrl];
    [self setAuthenticationHeader:self.request];
}

- (void)setAuthenticationHeader:(NSMutableURLRequest *)request
{
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.username, self.password];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
}

- (void)getIssueSubjectAsync:(NSString *)issueId
{
    [self.request setURL:[self.serverUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"rest/api/2/issue/%@", issueId]]];
    self.currentConnection = [NSURLConnection connectionWithRequest:self.request delegate:self];
}

- (void)uploadTimeEntries
{    
    for (TimerTableRow *row in self.timerTableRows)
    {
        NSString *title = nil;
        NSString *message = nil;
        
        if (row.timer.jira.issueId == nil)
        {
            title = @"Missing issue ID!";
            message = @"One or more timers do not have an associated issue ID.";
        }
        
        if (title != nil)
        {
            [self enableUserInteraction];
            self.jiraView.progressLabel.text = @"";
            self.jiraView.doneButton.alpha = 1;
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];            
            return;
        }
    }
    
    isUploading = YES;
    errorHandled = NO;
    responseReceived = NO;
    verifiedIssues = 0;
    
    for (TimerTableRow *row in self.timerTableRows)
        [self getIssueSubjectAsync:row.timer.jira.issueId];    
}

- (void)uploadTimeEntriesForSection:(TimerSection *)section
{
    NSString *issueId = section.timer.jira.issueId;
    
    for (Registration *registration in section.registrations)
    {
        if (registration.endTime != nil)
        {
            NSNumber *amount = [NSNumber numberWithDouble:[registration.endTime timeIntervalSinceDate:registration.startTime]];
            
            NSArray *sortedInfo = [registration.timerSection.timer.info.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [((TimerInfo *)obj1).index compare:((TimerInfo *)obj2).index];
            }];
            
            NSMutableArray *sortedInfoTitles = [[NSMutableArray alloc] init];
            for (int i = 0; i < sortedInfo.count; i++)
                [sortedInfoTitles addObject:((TimerInfo *)[sortedInfo objectAtIndex:i]).title];
            
            NSString *subject = [sortedInfoTitles componentsJoinedByString:@", "];
            if (registration.note != nil && registration.note.length > 0)
                subject = [subject stringByAppendingString:[NSString stringWithFormat:@": %@", registration.note]];

            subject = [[subject stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            
            [self uploadTimeEntryWithIssueId:issueId date:registration.startTime amount:amount comments:subject];
        }
    }
}

- (void)uploadTimeEntryWithIssueId:(NSString *)issueId date:(NSDate *)date amount:(NSNumber *)amount comments:(NSString *)comments
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self.serverUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"rest/api/2/issue/%@/worklog", issueId]]];
    [self setAuthenticationHeader:request];
    
    NSString *post = [NSString stringWithFormat:@"{\"comment\":\"%@\",\"started\":\"%@\",\"timeSpentSeconds\":%d}", comments, [self.dateFormatter stringFromDate:date], amount.intValue];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
    NSURLResponse *response;
    NSError *error;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (response != nil)
        [self connection:nil didReceiveResponse:response];
    else if (error != nil)
        [self connection:nil didFailWithError:error];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.timerTableRows.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
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
        NSString *text = row.timer.jira.issueSubject;
        
        if (view.tag == section)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (row.timer.jira.issueId == nil)
                    label.text = @"FILL IN ISSUE ID";
                else
                    label.text = [text uppercaseString];
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
        NSString *identifier = @"IssueCell";
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
            label.text = @"Issue ID";
            [cell addSubview:label];
            
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(111, 0, 160, 44)];
            textField.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
            textField.layer.shadowOpacity = 1.0;
            textField.layer.shadowRadius = 0.0;
            textField.layer.shadowColor = [UIColor whiteColor].CGColor;
            textField.layer.shadowOffset = CGSizeMake(0.0, 1.0);
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
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
        
        UITextField *textField = (UITextField *)[cell viewWithTag:1];
        UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:2];
        
        TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
        cell.backgroundView.tag = indexPath.section + 3;
        
        dispatch_async(queue, ^{
            NSString *text = row.timer.jira.issueId != nil ? row.timer.jira.issueId : @"";
            
            if (cell.backgroundView.tag == indexPath.section + 3)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    textField.text = text;
                });
            }
        });
        
        textField.alpha = 1;
        [activityIndicator stopAnimating];
        
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
}

#pragma mark - Timer View Delegate

- (void)timerViewControllerDidFinish:(TimerViewController *)controller
{
    [self.jiraView.tableView reloadData];
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
    [self.jiraView.tableView selectRowAtIndexPath:[self.jiraView.tableView indexPathForCell:cell] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self performSelector:@selector(setFrameAndScrollWithDelay) withObject:nil afterDelay:0.5];    
    
    self.jiraView.doneButton.enabled = NO;
    self.jiraView.cancelButton.enabled = NO;
}

- (void)setFrameAndScrollWithDelay
{
    NSIndexPath *indexPath = self.jiraView.tableView.indexPathForSelectedRow;
    NSIndexPath *scrollTo = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
    self.jiraView.tableView.frame = CGRectMake(0.0, 45.0, 320.0, [[UIScreen mainScreen] bounds].size.height - 45 - 216);
    [self.jiraView.tableView scrollToRowAtIndexPath:scrollTo atScrollPosition:UITableViewScrollPositionTop animated:YES];
    self.jiraView.tableView.scrollEnabled = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UIView *view = textField;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.jiraView.tableView indexPathForCell:cell];
    TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
    
    if (textField.text.length != 0)
    {    
        if (![textField.text isEqualToString:row.timer.jira.issueId])
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
            self.jiraView.tableView.scrollEnabled = YES;
            self.jiraView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
        }
    }
    else 
    {        
        row.timer.jira.issueId = nil;
        
        [TimeeData commit];
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
        [self.jiraView.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        
        self.jiraView.tableView.scrollEnabled = YES;
        self.jiraView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
    }
    
    self.jiraView.doneButton.enabled = YES;
    self.jiraView.cancelButton.enabled = YES;
}

#pragma mark - NSURLConnection Data Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    responseReceived = YES;
    
    if ([response.URL.absoluteString rangeOfString:@"worklog"].length != 0)
    {        
        int percent = (totalRegistrations - pendingRequests + 1) * 100 / totalRegistrations;
        NSString *text = [NSString stringWithFormat:@"%d%%", percent];
        
        if (![self.jiraView.progressLabel.text isEqualToString:text])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.jiraView.progressLabel.text = text;
            });
        }
        
        NSInteger index = self.serverUrl.absoluteString.length + @"/rest/api/2/issue/".length;
        NSString *issueId = [response.URL.absoluteString substringFromIndex:index];
        issueId = [issueId substringToIndex:issueId.length - @"/worklog".length];
        
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
            NSInteger index = self.serverUrl.absoluteString.length + @"/rest/api/2/issue/".length;
            NSString *issueId = [response.URL.absoluteString substringFromIndex:index];
            
            UIAlertView *alertView = [Integration verifyIssueId:issueId fromResponse:(NSHTTPURLResponse *)response];
            
            if (alertView != nil)
            {            
                self.jiraView.progressLabel.text = @"";
                self.jiraView.doneButton.alpha = 1;
                [self enableUserInteraction];
                
                errorHandled = YES;
                [alertView show];          
            }
            else 
            {
                if (OSAtomicIncrement32(&verifiedIssues) == self.timerTableRows.count)
                {
                    self.alertsByIssueId = [[NSMutableDictionary alloc] init];
                    pendingRequests = totalRegistrations;                    
                    NSOperationQueue *queueForIssue = nil;
                    NSString *currentIssue = nil;                                                        
                                        
                    for (TimerSection *section in self.sections)
                    {
                        if (queueForIssue == nil || ![currentIssue isEqualToString:section.timer.jira.issueId])
                        {
                            queueForIssue = [[NSOperationQueue alloc] init];
                            queueForIssue.maxConcurrentOperationCount = 1;
                            currentIssue = section.timer.jira.issueId;
                        }
                        
                        [queueForIssue addOperationWithBlock:^{ 
                            [self uploadTimeEntriesForSection:section];
                        }];
                    }
                }
            }
        }
    }
    else
    {
        NSIndexPath *indexPath = self.jiraView.tableView.indexPathForSelectedRow;
        UITableViewCell *cell = [self.jiraView.tableView cellForRowAtIndexPath:indexPath];
        UITextField *textField = (UITextField *)[cell viewWithTag:1];
        TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];
        UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:2];
        
        [activityIndicator stopAnimating];
        textField.alpha = 1;
        self.jiraView.tableView.scrollEnabled = YES; 
        self.jiraView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
        
        UIAlertView *alertView = [Integration verifyIssueId:textField.text fromResponse:(NSHTTPURLResponse *)response];
        
        if (alertView != nil)
        {
            textField.text = row.timer.jira.issueId;
            
            if (!errorHandled)
            {
                errorHandled = YES;
                [alertView show];
            }
        }
        else
        {
            if (row.timer.jira == nil)
                row.timer.jira = [NSEntityDescription insertNewObjectForEntityForName:@"JiraInfo" inManagedObjectContext:[TimeeData context]];
            
            row.timer.jira.issueId = textField.text;
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
    if (!isUploading)
    {
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];    
        NSRange range = [content rangeOfString:@"\"summary\":\""];
        
        if (range.length != 0)
        {
            NSIndexPath *indexPath = self.jiraView.tableView.indexPathForSelectedRow;
            TimerTableRow *row = [self.timerTableRows objectAtIndex:indexPath.section];

            content = [content substringFromIndex:range.location + range.length];
        
            for (int i = 0; i < content.length; i++)
            {
                NSString *character1 = [content substringWithRange:NSMakeRange(i, 1)];
                NSString *character2 = [content substringWithRange:NSMakeRange(i + 1, 1)];
                
                if ([character2 isEqualToString:@"\""] && ![character1 isEqualToString:@"\\"])
                {
                    row.timer.jira.issueSubject = [[[content substringToIndex:i + 1] stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""] stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
                    [TimeeData commit];
                    break;
                }                
            }
            
            [self.jiraView.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (responseReceived)
        return;
    
    [self.jiraView.tableView reloadData];
    [self enableUserInteraction];
    self.jiraView.progressLabel.text = @"";
    self.jiraView.doneButton.alpha = 1;
    self.jiraView.tableView.scrollEnabled = YES; 
    self.jiraView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
    
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
        else 
        {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];            
        }
    }
    else 
    {
        [[challenge sender] cancelAuthenticationChallenge:challenge];            
    }
}

@end
