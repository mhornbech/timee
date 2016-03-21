//
//  OptionsViewController.m
//  Timee
//
//  Created by Morten Hornbech on 06/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppColors.h"
#import "OptionsView.h"
#import "OptionsViewController.h"
#import "RegistrationTableViewController.h"
#import "DeleteRegistrationsViewController.h"
#import "ExportRegistrationsViewController.h"
#import "RegistrationTableView.h"
#import "SelectRegistrationsView.h"
#import "SearchCellView.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerInfo.h"
#import "TimerView.h"
#import "TimerViewController.h"
#import "ViewControllerCache.h"

#define kAddTimerRow                        1
#define kRegistrationsRow                   2
#define kExportRow                          3
#define kDeleteRow                          4
#define kTutorialRow                        5

#define kOptionCellIdentifier               @"OptionCell"

#define kOptionsCellNibName                 @"OptionsCell"
#define kTimerViewNibName                   @"TimerView"
#define kRegistrationTableViewNibName       @"RegistrationTableView"
#define kSelectRegistrationsViewNibName     @"SelectRegistrationsView"
#define kTutorialViewNibName                @"TutorialView"

#define kTimerEntityName                    @"Timer"
#define kTimerInfoEntityName                @"TimerInfo"

@implementation OptionsViewController

@synthesize delegate = _delegate;
@synthesize cell = _cell;
@synthesize optionsView = _optionsView;

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate optionsViewControllerDidFinish:self];
}

- (IBAction)showAddTimer
{
    TimerViewController *viewController = (TimerViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Timer"];
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {    
        viewController = [[TimerViewController alloc] initWithNibName:kTimerViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Timer"];
    }
    
    Timer *timer = [NSEntityDescription insertNewObjectForEntityForName:kTimerEntityName inManagedObjectContext:[TimeeData context]];
    TimerInfo *info = [NSEntityDescription insertNewObjectForEntityForName:kTimerInfoEntityName 
                                                    inManagedObjectContext:[TimeeData context]];        
    
    timer.timerTableSummaryType = @"current";
    info.index = [NSNumber numberWithInt:0];
    info.title = @"";
    [timer addInfoObject:info];
    viewController.timer = timer;	
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

- (IBAction)showRegistrations
{    
    [UIView commitAnimations];
    
    RegistrationTableViewController *viewController = (RegistrationTableViewController *)[[ViewControllerCache instance]getViewControllerForName:@"RegistrationTable"];
    
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {
        viewController = [[RegistrationTableViewController alloc] initWithNibName:kRegistrationTableViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"RegistrationTable"];
    }
    
    viewController.delegate = self;
    viewController.searchActive = NO;
    ((SearchCellView *)[viewController.searchCell.contentView.subviews objectAtIndex:0]).searchTextField.text = @"Search";
    
    if (cached)
    {
        [viewController prepareDataForView];
        [viewController.registrationTableView.tableView reloadData];
        [viewController.registrationTableView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    [self presentModalViewController:viewController animated:YES];
}

- (IBAction)showDeleteData
{
    DeleteRegistrationsViewController *viewController = (DeleteRegistrationsViewController *)[[ViewControllerCache instance] getViewControllerForName:@"DeleteRegistrations"];
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {   
        viewController = [[DeleteRegistrationsViewController alloc] initWithNibName:kSelectRegistrationsViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"DeleteRegistrations"];
    }
    
    NSArray *sections = [TimeeData instance].registrationTableSections;
    
    viewController.delegate = self;
    
    if (sections.count != 0)
    {
        viewController.endTime = ((RegistrationTableSection *)[sections objectAtIndex:0]).date;
        
        NSDate *earliest = ((RegistrationTableSection *)[sections objectAtIndex:sections.count - 1]).date;
        NSDate *oneWeekBack = [viewController.endTime dateByAddingTimeInterval: - 24 * 3600 * 6];
        
        viewController.startTime = [earliest compare:oneWeekBack] == NSOrderedAscending ? oneWeekBack : earliest;
    }
    else
    {
        int secondsSinceReference = [[NSDate date] timeIntervalSinceReferenceDate] + [NSTimeZone localTimeZone].secondsFromGMT;
        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:secondsSinceReference - secondsSinceReference % (24 * 3600)];
        viewController.startTime = viewController.endTime = date;
    }
    
    viewController.selectedRows = [[NSMutableSet alloc] init];
    
    if (cached)
    {
        [viewController refresh];
        [viewController addEmptyTimers];
        [viewController.selectRegistrationsView.tableView reloadData];
        [viewController.selectRegistrationsView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    [self presentModalViewController:viewController animated:YES]; 
}

- (IBAction)showExportData
{
    ExportRegistrationsViewController *viewController = (ExportRegistrationsViewController *)[[ViewControllerCache instance] getViewControllerForName:@"ExportRegistrations"];
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {   
        viewController = [[ExportRegistrationsViewController alloc] initWithNibName:kSelectRegistrationsViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"ExportRegistrations"];
    }
    
    NSArray *sections = [TimeeData instance].registrationTableSections;
    
    viewController.delegate = self;
    viewController.endTime = ((RegistrationTableSection *)[sections objectAtIndex:0]).date;
    
    NSDate *earliest = ((RegistrationTableSection *)[sections objectAtIndex:sections.count - 1]).date;
    NSDate *oneWeekBack = [viewController.endTime dateByAddingTimeInterval: - 24 * 3600 * 6];
    
    viewController.startTime = [earliest compare:oneWeekBack] == NSOrderedAscending ? oneWeekBack : earliest;
    viewController.selectedRows = [[NSMutableSet alloc] init];
    
    if (cached)
    {
        [viewController refresh];
        [viewController.selectRegistrationsView.tableView reloadData];
        [viewController.selectRegistrationsView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }

    [self presentModalViewController:viewController animated:YES]; 
}

- (IBAction)showTutorial
{
    TutorialViewController *viewController = (TutorialViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Tutorial"];
    
    if (viewController == nil)
    {
        viewController = [[TutorialViewController alloc] initWithNibName:kTutorialViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Tutorial"];
    }
    
    viewController.delegate = self;
    
    [self presentModalViewController:viewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        return 40.0;
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        if (indexPath.row == kAddTimerRow)
            return 126.0;
        
        if (indexPath.row == kRegistrationsRow)
            return 104.0;
        
        if (indexPath.row == kExportRow)
            return 108.0;
        
        if (indexPath.row == kDeleteRow)
            return 120.0;
        
        if (indexPath.row == kTutorialRow)
            return 117.0;
    }
    else
    {
        if (indexPath.row == kAddTimerRow)
            return 132.0;
        
        if (indexPath.row == kRegistrationsRow)
            return 110.0;
        
        if (indexPath.row == kExportRow)
            return 114.0;
        
        if (indexPath.row == kDeleteRow)
            return 126.0;
        
        if (indexPath.row == kTutorialRow)
            return 123.0;
    }
    
    return 0.0;
}

#pragma mark - Table View Data Source

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
    
    if (indexPath.row == kAddTimerRow)
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 132)];
        backgroundImage = [UIImage imageNamed:@"add_timer"];
        selectedBackgroundImage = [UIImage imageNamed:@"add_timer_selected"];
        
        option.frame = CGRectMake(0, 65, 320, 30);
        option.text = @"Add Timer";        
    }
    
    if (indexPath.row == kRegistrationsRow)
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 110)];
        backgroundImage = [UIImage imageNamed:@"registrations"];
        selectedBackgroundImage = [UIImage imageNamed:@"registrations_selected"];
        
        option.frame = CGRectMake(0, 43, 320, 30);
        option.text = @"Registrations";        
    }
    
    if (indexPath.row == kExportRow)
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 114)];
        backgroundImage = [UIImage imageNamed:@"export_data"];
        selectedBackgroundImage = [UIImage imageNamed:@"export_data_selected"];
        
        option.frame = CGRectMake(0, 47, 320, 30);
        option.text = @"Export Data";        
    }
    
    if (indexPath.row == kDeleteRow)
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 126)];
        backgroundImage = [UIImage imageNamed:@"delete_data"];
        selectedBackgroundImage = [UIImage imageNamed:@"delete_data_selected"];
        
        option.frame = CGRectMake(0, 59, 320, 30);
        option.text = @"Delete Data";        
    }
    
    if (indexPath.row == kTutorialRow)
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 123)];
        backgroundImage = [UIImage imageNamed:@"tutorial"];
        selectedBackgroundImage = [UIImage imageNamed:@"tutorial_selected"];
        
        option.frame = CGRectMake(0, 56, 320, 30);
        option.text = @"Tutorial";
    }
    
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (indexPath.row == kAddTimerRow)
        [self showAddTimer];        
    else if (indexPath.row == kRegistrationsRow)
    {
        if ([TimeeData instance].registrationTableSections.count != 0)
            [self showRegistrations];
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"There are no registrations to view." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            
            [alert show];
        }
    }
    else if (indexPath.row == kExportRow)
    {
        if ([TimeeData instance].registrationTableSections.count != 0)
            [self showExportData];
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"There is no data to export." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            
            [alert show];
        }
    }
    else if (indexPath.row == kDeleteRow)
    {
        if ([TimeeData instance].timerTableRows.count != 0)
            [self showDeleteData];
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"There is no data to delete." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            
            [alert show];
        }
    }
    else if (indexPath.row == kTutorialRow)
    {
        [self showTutorial];
    }
}

#pragma mark - Timer View Delegate

- (void)timerViewControllerDidFinish:(TimerViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Registration Table View Delegate

- (void)registrationTableViewControllerDidFinish:(RegistrationTableViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Select Registrations View Delegate

- (void)selectRegistrationsViewControllerDidFinish:(SelectRegistrationsViewController *)controller 
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Tutorial View Delegate

- (void)tutorialViewControllerDidFinish:(TutorialViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - MFMailComposeViewController Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.optionsView.tableView deselectRowAtIndexPath:[self.optionsView.tableView indexPathForSelectedRow] animated:NO];
}

#pragma mark - View lifecycle

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.optionsView.tableView reloadData];
}

- (void)viewDidLoad
{
    self.optionsView.tableView.backgroundColor = [AppColors gold];
    self.optionsView.title.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.optionsView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.optionsView.tableView.frame;
        self.optionsView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
    }
}

@end
