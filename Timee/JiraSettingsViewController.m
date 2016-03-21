//
//  JiraSettingsViewController.m
//  Timee
//
//  Created by Morten Hornbech on 22/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "Integration.h"
#import "JiraSettingsView.h"
#import "JiraSettingsViewController.h"

@implementation JiraSettingsViewController

@synthesize jiraSettingsView = _jiraSettingsView;
@synthesize userDefaults = _userDefaults;
@synthesize textFieldBeingEdited = _textFieldBeingEdited;
@synthesize jiraViewController = _jiraViewController;
@synthesize delegate = _delegate;

#pragma mark - Actions

- (void)cancel
{
    [self.delegate jiraSettingsViewControllerDidFinish:self];
}

- (void)done
{
    if (self.textFieldBeingEdited != nil)
        [self.textFieldBeingEdited resignFirstResponder];
    
    UIAlertView *alertView = [Integration verifySettingsForApplication:@"jira"];
    [self.jiraSettingsView.tableView setFrame:CGRectMake(0, 44, 320, [[UIScreen mainScreen] bounds].size.height - 45)];
    
    if (alertView == nil)
    {
        [self.jiraViewController refreshSettings];
        alertView = [[UIAlertView alloc] initWithTitle:nil message:@"You can change this information later from the iOS Settings." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    }
    
    [alertView show];
}

#pragma mark - Instance Methods

- (NSString *)userDefaultsKeyForIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) 
    {
        case 0:
            return @"jiraUrl";
            break;
            
        case 1:
            return indexPath.row == 0 ? @"jiraUsername" : @"jiraPassword";
            break;
    }
    
    return nil;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    self.jiraSettingsView = (JiraSettingsView *)self.view;
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.jiraSettingsView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.jiraSettingsView.tableView.frame;
        self.jiraSettingsView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
    }

    self.userDefaults = [NSUserDefaults standardUserDefaults];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) 
    {
        case 0:
            return 1;
            break;
            
        case 1:
            return 2;
            break;            
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UITextField *textField = [[UITextField alloc] init];
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.textColor = [UIColor colorWithRed:56.0/255.0 green:84.0/255.0 blue:135.0/255.0 alpha:1];
    textField.adjustsFontSizeToFitWidth = YES;
    textField.delegate = self;    
    textField.tag = 1;
    textField.text = [self.userDefaults stringForKey:[self userDefaultsKeyForIndexPath:indexPath]];
    [cell addSubview:textField];

    switch (indexPath.section) 
    {

        case 0:
        {   
            textField.frame = CGRectMake(30, 0, 270, 44);
            break;
        }
            
        case 1:
        {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 100, 44)];
            label.text = indexPath.row == 0 ? @"Username" : @"Password";
            label.backgroundColor = [UIColor clearColor];
            label.font = [UIFont boldSystemFontOfSize:17];
            [cell addSubview:label];
            
            textField.frame = CGRectMake(120, 0, 180, 44);
            
            if (indexPath.row == 1)
                textField.secureTextEntry = YES;
            
            break;
        }
            
        case 2:
        {   
            textField.frame = CGRectMake(30, 0, 270, 44);
            break;
        }
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) 
    {
        case 0:
            return @"URL";
            break;
            
        case 1:
            return @"Credentials";
            break;
    }
    
    return nil;
}

# pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self presentModalViewController:self.jiraViewController animated:YES];
}

# pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UITextField *textField = (UITextField *)[cell viewWithTag:1];
    [textField becomeFirstResponder];
}

# pragma mark - Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.textFieldBeingEdited = textField;
    [self performSelector:@selector(setFrameWithDelay) withObject:nil afterDelay:0.5];
}

- (void)setFrameWithDelay
{
    UIView *view = self.textFieldBeingEdited;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.jiraSettingsView.tableView indexPathForCell:cell];
    
    [self.jiraSettingsView.tableView setFrame:CGRectMake(0, 44, 320, [[UIScreen mainScreen] bounds].size.height - 44 - 216)];
    [self.jiraSettingsView.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];    
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UIView *view = self.textFieldBeingEdited;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.jiraSettingsView.tableView indexPathForCell:cell];
    
    if (indexPath.section == 0 && indexPath.row == 0)
    {
        if (![[textField.text substringWithRange:NSMakeRange(0, MIN(4, textField.text.length))].lowercaseString isEqualToString:@"http"])
            textField.text = [NSString stringWithFormat:@"http://%@", textField.text];
    }
    
    [self.userDefaults setValue:textField.text forKey:[self userDefaultsKeyForIndexPath:indexPath]];        
}


@end
