//
//  TargetViewController.m
//  Timee
//
//  Created by Morten Hornbech on 06/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppColors.h"
#import "Integration.h"
#import "JiraView.h"
#import "JiraViewController.h"
#import "JiraSettingsViewController.h"
#import "RedmineView.h"
#import "RedmineViewController.h"
#import "RedmineSettingsViewController.h"
#import "Registration.h"
#import "TargetView.h"
#import "TargetViewController.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerInfo.h"
#import "TimerSection.h"
#import "TimerTableRow.h"
#import "ViewControllerCache.h"

#import <MessageUI/MessageUI.h>

@interface TargetViewController ()

@end

@implementation TargetViewController

@synthesize targetView = _targetView;
@synthesize csvFilePath = _csvFilePath;
@synthesize dateFormatter = _dateFormatter;
@synthesize selectedRows = _selectedRows;
@synthesize timerTableRows = _timerTableRows;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;
@synthesize sections = _sections;
@synthesize activityIndicator = _activityIndicator;
@synthesize cancelDelegate = _cancelDelegate;
@synthesize doneDelegate = _doneDelegate;

#pragma mark - View lifecycle

BOOL iOS5OrLater;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.targetView = (TargetView *)self.view;
    self.targetView.tableView.backgroundColor = [AppColors gold];   
    self.targetView.title.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.targetView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.targetView.tableView.frame;
        self.targetView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
    }

    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    self.csvFilePath = [documentsDirectory stringByAppendingPathComponent:@"export.csv"];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    iOS5OrLater = [[UIDevice currentDevice].systemVersion substringToIndex:1].integerValue > 4;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.targetView.tableView.userInteractionEnabled = YES;
    self.targetView.cancelButton.enabled = YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Actions

- (IBAction)cancel
{
    [self.cancelDelegate targetViewControllerDidFinish:self];
}

#pragma mark - Instance Methods

- (NSArray *)getSelectedRows
{
    NSMutableArray *selectedRows = nil;
    
    if (self.selectedRows.count == 0)
        selectedRows = [NSMutableArray arrayWithArray:self.timerTableRows];
    else
    {
        selectedRows = [[NSMutableArray alloc] init];
        
        for (TimerTableRow *row in self.timerTableRows)
        {
            if ([self.selectedRows containsObject:row.objectID])
                [selectedRows addObject:row];
        }
    }
    
    return selectedRows;
}

- (void)showRedmine
{
    NSArray *selectedRows = [self getSelectedRows];
    
    RedmineViewController *viewController = (RedmineViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Redmine"];
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {
        viewController = [[RedmineViewController alloc] initWithNibName:@"RedmineView" bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Redmine"];
    }
    
    viewController.timerTableRows = selectedRows;
    viewController.startTime = self.startTime;
    viewController.endTime = self.endTime;
    viewController.sections = self.sections;
    viewController.cancelDelegate = self;
    viewController.doneDelegate = self.doneDelegate;
    
    if (cached)
    {
        [viewController.redmineView.tableView reloadData];
        [viewController.redmineView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    if ([Integration verifySettingsForApplication:@"redmine"] != nil)
    {
        RedmineSettingsViewController *settingsViewController = [[RedmineSettingsViewController alloc] initWithNibName:@"RedmineSettingsView" bundle:[NSBundle mainBundle]];;
        settingsViewController.redmineViewController = viewController;
        settingsViewController.delegate = self;
        
        [self presentModalViewController:settingsViewController animated:YES];
    }
    else
    {
        [viewController refreshSettings];
        [self presentModalViewController:viewController animated:YES];
    }
}

- (void)showJira
{
    NSArray *selectedRows = [self getSelectedRows];
    
    JiraViewController *viewController = (JiraViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Jira"];
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {
        viewController = [[JiraViewController alloc] initWithNibName:@"JiraView" bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Jira"];
    }
    
    viewController.timerTableRows = selectedRows;
    viewController.startTime = self.startTime;
    viewController.endTime = self.endTime;
    viewController.sections = self.sections;
    viewController.cancelDelegate = self;
    viewController.doneDelegate = self.doneDelegate;
    
    if (cached)
    {
        [viewController.jiraView.tableView reloadData];
        [viewController.jiraView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    if ([Integration verifySettingsForApplication:@"jira"] != nil)
    {
        JiraSettingsViewController *settingsViewController = [[JiraSettingsViewController alloc] initWithNibName:@"JiraSettingsView" bundle:[NSBundle mainBundle]];;
        settingsViewController.jiraViewController = viewController;
        settingsViewController.delegate = self;
        
        [self presentModalViewController:settingsViewController animated:YES];
    }
    else
    {
        [viewController refreshSettings];
        [self presentModalViewController:viewController animated:YES];
    }
}

- (void)exportToCsv
{
    [self.activityIndicator startAnimating];
    
    self.targetView.tableView.userInteractionEnabled = NO;
    self.targetView.cancelButton.enabled = NO;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *allRegistrations = [[NSMutableArray alloc] init];
        NSInteger timerCount = 0;
        NSManagedObjectID *previousTimer = nil;
        NSMutableArray *registrationsForTimer = [[NSMutableArray alloc] init];
        
        for (TimerSection *section in self.sections)
        {
            if (section.timer.objectID != previousTimer)
            {
                [registrationsForTimer sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    return [((Registration *)obj2).startTime compare:((Registration *)obj1).startTime];
                }];            
                [allRegistrations addObjectsFromArray:registrationsForTimer];
                
                [registrationsForTimer removeAllObjects];                        
                previousTimer = section.timer.objectID;
                timerCount++;
            }
            
            [registrationsForTimer addObjectsFromArray:section.registrations.allObjects];
        }
        
        [registrationsForTimer sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [((Registration *)obj2).startTime compare:((Registration *)obj1).startTime];
        }];            
        [allRegistrations addObjectsFromArray:registrationsForTimer];
        
        if (timerCount == [TimeeData instance].timerTableRows.count)
        {
            [allRegistrations sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [((Registration *)obj2).startTime compare:((Registration *)obj1).startTime];
            }];
        }
        
        NSMutableArray *content = [[NSMutableArray alloc] init];
        
        [content addObject:[self getHeaders]];
        
        for (Registration *registration in allRegistrations)
            [content addObject:[self getComponentsForRegistration:registration]];
        
        [[content componentsJoinedByString:@"\n"] writeToFile:self.csvFilePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.targetView.tableView.userInteractionEnabled = YES;
            self.targetView.cancelButton.enabled = YES;
            [self exportFileToMailApplication];
        });
    });
}

- (NSString *)getHeaders
{
    return @"Starts;Ends;Duration;Info;Note";
}

- (NSString *)getComponentsForRegistration:(Registration *)registration
{
    NSString *startTime = [self.dateFormatter stringFromDate:registration.startTime];
    NSString *endTime = registration.endTime != nil ? [self.dateFormatter stringFromDate:registration.endTime] : @""; 
    NSString *duration = registration.endTime != nil ? [NSString stringWithFormat:@"%d", ((int)[registration.endTime timeIntervalSinceDate:registration.startTime]) / 60] : @"";;
    
    NSArray *info = [registration.timerSection.timer.info.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((TimerInfo *)obj1).index compare:((TimerInfo *)obj2).index];
    }];
    
    NSMutableArray *infoTitles = [[NSMutableArray alloc] init];
    
    for (TimerInfo *ti in info)
        [infoTitles addObject:ti.title];
    
    NSString *infoText = [infoTitles componentsJoinedByString:@","];
    
    if ([infoText rangeOfString:@";"].length != 0 || [infoText rangeOfString:@"\""].length != 0)
    {
        NSString *escapedInfoText = [infoText stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
        infoText = [NSString stringWithFormat:@"\"%@\"", escapedInfoText];
    }
    
    NSString *note = registration.note != nil ? registration.note :  @"";
    
    if ([note rangeOfString:@";"].length != 0 || [infoText rangeOfString:@"\""].length != 0)
    {
        NSString *escapedNote = [note stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
        note = [NSString stringWithFormat:@"\"%@\"", escapedNote];
    }
    
    return [[NSArray arrayWithObjects:startTime, endTime, duration, infoText, note, nil] componentsJoinedByString:@";"];
}     

- (void)exportFileToMailApplication
{
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    mailer.mailComposeDelegate = (id<MFMailComposeViewControllerDelegate>)self.doneDelegate;
    
    NSString *timeOfExport = [[[self.dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@"/" withString:@"-"] stringByReplacingOccurrencesOfString:@":" withString:@""];
    NSString *fileName = [NSString stringWithFormat:@"Timee Data Export %@", timeOfExport]; 
    
    [mailer setSubject:fileName];
    [mailer addAttachmentData:[NSData dataWithContentsOfFile:self.csvFilePath] mimeType:@"text/csv" fileName:[NSString stringWithFormat:@"%@.csv", fileName]];
    
    [self presentModalViewController:mailer animated:YES];
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        cell.backgroundView.backgroundColor = [AppColors gold];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    UITableViewCell *cell = nil;
    UIImage *backgroundImage = nil;
    UIImage *selectedBackgroundImage = nil;
    UILabel *option = [[UILabel alloc] init];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    activityIndicator.tag = 1;
    
    if (indexPath.row == 1)
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 104)];
        backgroundImage = [UIImage imageNamed:@"mail"];
        selectedBackgroundImage = [UIImage imageNamed:@"mail_selected"];
        
        activityIndicator.frame = CGRectMake(150, 9, 20, 20);
        option.frame = CGRectMake(0, 37, 320, 30);
        option.text = @"Mail";
    }
    else if (indexPath.row == 2)
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 111)];
        backgroundImage = [UIImage imageNamed:@"redmine"];
        selectedBackgroundImage = [UIImage imageNamed:@"redmine_selected"];
        option.text = @"Redmine";
        
        activityIndicator.frame = CGRectMake(150, 17, 20, 20);
        option.frame = CGRectMake(0, 44, 320, 30);
    }
    else if (indexPath.row == 3)
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 122)];
        backgroundImage = [UIImage imageNamed:@"jira"];
        selectedBackgroundImage = [UIImage imageNamed:@"jira_selected"];
        option.text = @"Jira";
        
        activityIndicator.frame = CGRectMake(150, 18, 20, 20);
        option.frame = CGRectMake(0, 55, 320, 30);
    }
    
    [cell addSubview:activityIndicator];
    
    option.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18];
    option.textAlignment = UITextAlignmentCenter;
    option.backgroundColor = [UIColor clearColor];
    option.textColor = [AppColors beige];
    option.shadowColor = [UIColor whiteColor];
    option.shadowOffset = CGSizeMake(0, 1);
    [cell addSubview:option];    
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundView.contentMode = UIViewContentModeTop;
    backgroundView.backgroundColor = [AppColors gold];
    
    UIImageView *selectedBackgroundView = [[UIImageView alloc] initWithImage:selectedBackgroundImage];
    selectedBackgroundView.contentMode = UIViewContentModeTop;
    selectedBackgroundView.backgroundColor = [AppColors gold];
    
    cell.backgroundView = backgroundView;
    cell.selectedBackgroundView = selectedBackgroundView;
    
    return cell;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        return 50.0;
    
    if (indexPath.row == 1)
        return 104.0;
    
    if (indexPath.row == 2)
        return 111.0;
    
    if (indexPath.row == 3)
        return 122.0;
    
    return 0.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.activityIndicator = (UIActivityIndicatorView *)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:1];
    
    switch (indexPath.row)
    {
        case 1:
            [self exportToCsv];
            break;
            
        case 2:
        {
            if (iOS5OrLater)
            {
                [self showRedmine];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Requires iOS 5 or later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                
                [alert show];
            }
            
            break;
        }
            
        case 3:
        {
            if (iOS5OrLater)
            {
                [self showJira];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Requires iOS 5 or later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                
                [alert show];
            }
            
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Jira View Delegate

- (void)jiraViewControllerDidFinish:(JiraViewController *)controller
{
    [self.targetView.tableView deselectRowAtIndexPath:self.targetView.tableView.indexPathForSelectedRow animated:NO];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Jira Settings View Delegate

- (void)jiraSettingsViewControllerDidFinish:(JiraSettingsViewController *)controller
{
    [self.targetView.tableView deselectRowAtIndexPath:self.targetView.tableView.indexPathForSelectedRow animated:NO];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Redmine View Delegate

- (void)redmineViewControllerDidFinish:(RedmineViewController *)controller
{
    [self.targetView.tableView deselectRowAtIndexPath:self.targetView.tableView.indexPathForSelectedRow animated:NO];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Redmine Settings View Delegate

- (void)redmineSettingsViewControllerDidFinish:(RedmineSettingsViewController *)controller
{
    [self.targetView.tableView deselectRowAtIndexPath:self.targetView.tableView.indexPathForSelectedRow animated:NO];
    [self dismissModalViewControllerAnimated:YES];
}

@end
