//
//  RegistrationViewController.m
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
#import "RegistrationView.h"
#import "RegistrationViewController.h"
#import "TimeeData.h"
#import <QuartzCore/QuartzCore.h> 

@implementation RegistrationViewController

@synthesize delegate = _delegate;
@synthesize endTime = _endTime;
@synthesize objectId = objectId;
@synthesize registrationView = _registrationView;
@synthesize startTime = _startTime;
@synthesize note = _note;
@synthesize startLabel = _startLabel;
@synthesize endLabel = _endLabel;
@synthesize noteTextField = _noteTextField;
@synthesize selectedRow = _selectedRow;

#pragma mark - Actions

- (IBAction)cancel:(id)sender
{
    [self textFieldDidEndEditing:self.noteTextField];
    [self.delegate registrationViewControllerDidFinish:self saveContext:NO];
}

- (IBAction)dateChanged:(id)sender
{
    if (self.selectedRow < 2)
    {
        NSDate *date = self.registrationView.datePicker.date;
        
        NSString *text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
        
        if (self.selectedRow == 0)
        {
            self.startLabel.text = text;
            self.startTime = date;
        }
        else
        {
            self.endLabel.text = text;
            self.endTime = date;
        }
                
        self.startLabel.alpha = self.isValid ? 1.0 : 0.5;
        self.endLabel.alpha = self.isValid ? 1.0 : 0.5;
        
        self.registrationView.doneButton.enabled = self.isValid;
    }
}

- (IBAction)done:(id)sender
{
    [self textFieldDidEndEditing:self.noteTextField];
    
    NSInteger numberToReplace = [self numberOfRegistrationsToReplace];
    
    if (numberToReplace > 0)
    {
        NSString *message = [NSString stringWithFormat:@"This will delete %d overlapping registrations.", numberToReplace];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel" 
                                                  otherButtonTitles:@"OK", nil];
        
        [alertView show];      
    }
    else
        [self.delegate registrationViewControllerDidFinish:self saveContext:YES];
}

#pragma mark - Instance Methods

- (void)textFieldDone:(id)sender
{
    [sender resignFirstResponder];
}

- (BOOL)isValid
{
    if (self.startTime == nil)
        return NO;
    
    return [(self.endTime == nil ? [NSDate date] : self.endTime) timeIntervalSinceDate:self.startTime] > 59.9;
}

- (NSInteger)numberOfRegistrationsToReplace
{    
    NSInteger number = 0;
    
    NSDate *date = [NSDate date];
    NSArray *sections = [NSArray arrayWithArray:[TimeeData instance].registrationTableSections];
    
    for (int i = 0; i < sections.count; i++)
    {
        RegistrationTableSection *section = [sections objectAtIndex:i];
        
        if ([self.startTime timeIntervalSinceDate:section.date] > 24 * 3600)
            break;
        
        if ([(self.endTime == nil ? date : self.endTime) compare:section.date] != NSOrderedDescending)
            continue;
        
        NSArray *rows = section.rows.allObjects;
        
        for (int i = 0; i < rows.count; i++)
        {
            RegistrationTableRow *row = [rows objectAtIndex:i]; 
            NSArray *registrations = row.registrations.allObjects;
            
            for (int j = 0; j < registrations.count; j++)
            {
                Registration *reg = [registrations objectAtIndex:j];
                
                if (reg.objectID != self.objectId && reg.endTime != nil
                    && [reg.endTime compare:self.startTime] != NSOrderedAscending
                    && [reg.startTime compare:(self.endTime == nil ? date : self.endTime)] != NSOrderedDescending
                    && [self.startTime timeIntervalSinceDate:reg.startTime] < 59.9
                    && [reg.endTime timeIntervalSinceDate:(self.endTime == nil ? date : self.endTime)] < 59.9)
                {
                    number++;
                }
            }
        }
    }
    
    return number;
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
    selectionMarker.frame = CGRectMake(7, [[UIScreen mainScreen] scale] == 2.0 ? 2.5 : 3, 32, 25);
    selectionMarker.contentMode = UIViewContentModeBottom;
    selectionMarker.tag = 1;
    selectionMarker.hidden = YES;
    [cell.contentView addSubview:selectionMarker];

    if (indexPath.row == 2)
    {
        leftLabel.text = @"Note";                
        self.noteTextField.text = self.note;
        [cell.contentView addSubview:self.noteTextField];
    }
    else
    {
        leftLabel.text = indexPath.row == 0 ? @"Starts" : @"Ends";
        
        NSDate *date = indexPath.row == 0 ? self.startTime : self.endTime;
        
        UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 0, 151, 44)];
        rightLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
        rightLabel.textColor = leftLabel.textColor;
        rightLabel.shadowColor = leftLabel.shadowColor;
        rightLabel.shadowOffset = leftLabel.shadowOffset;
        rightLabel.backgroundColor = leftLabel.backgroundColor;
        rightLabel.textAlignment = UITextAlignmentRight;
        [cell.contentView addSubview:rightLabel];
        
        if (date != nil)
        {            
            rightLabel.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
            cell.userInteractionEnabled = YES;
        }
        else
        {
            rightLabel.text = @"";
            cell.userInteractionEnabled = NO;
        }
        
        if (indexPath.row == 0)
        {
            self.startLabel = rightLabel;
            selectionMarker.hidden = NO;
        }
        else
            self.endLabel = rightLabel;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

#pragma mark - Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath    
{
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:self.selectedRow inSection:0];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:oldIndexPath];
    UIImageView *selectionMarker = (UIImageView *)[cell.contentView viewWithTag:1];
    selectionMarker.hidden = YES;

    self.selectedRow = indexPath.row;
    
    cell = [tableView cellForRowAtIndexPath:indexPath];
    selectionMarker = (UIImageView *)[cell.contentView viewWithTag:1];
    selectionMarker.hidden = NO;
    
    if (indexPath.row == 2)
        [self.noteTextField becomeFirstResponder];
    else
    {
        [self.noteTextField resignFirstResponder];
        [self.registrationView.datePicker setDate:indexPath.row == 0 ? self.startTime : self.endTime];
    }
}

#pragma mark - Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self tableView:self.registrationView.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *trimmed = [self.noteTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.note = [trimmed isEqualToString:@""] ? nil : trimmed;
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [self.delegate registrationViewControllerDidFinish:self saveContext:YES];
}


#pragma mark - View lifecycle

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    self.registrationView = (RegistrationView *)self.view;     
    self.registrationView.title.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];

    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.registrationView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.registrationView.tableView.frame;
        self.registrationView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
        
        frame = self.registrationView.datePicker.frame;
        self.registrationView.datePicker.frame = CGRectMake(frame.origin.x, frame.origin.y + 88, frame.size.width, frame.size.height);
    }

    self.registrationView.datePicker.locale = [NSLocale currentLocale];
    self.registrationView.datePicker.backgroundColor = [AppColors gold];
    self.noteTextField = [[UITextField alloc] initWithFrame:CGRectMake(120, 0, 151, 44)];
    self.noteTextField.delegate = self;
    self.noteTextField.returnKeyType = UIReturnKeyDone;
    self.noteTextField.textColor = [AppColors black];
    self.noteTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.noteTextField.textAlignment = UITextAlignmentRight;
    self.noteTextField.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    self.noteTextField.layer.shadowOpacity = 1.0;   
    self.noteTextField.layer.shadowRadius = 0.0;
    self.noteTextField.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.noteTextField.layer.shadowOffset = CGSizeMake(0.0, 1.0);

    [self.noteTextField addTarget:self action:@selector(textFieldDone:) forControlEvents:UIControlEventEditingDidEndOnExit];    
    
    self.noteTextField.text = self.note != nil ? self.note : @"";
    
    self.selectedRow = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.registrationView.datePicker setDate:self.startTime animated:NO];
}

@end
