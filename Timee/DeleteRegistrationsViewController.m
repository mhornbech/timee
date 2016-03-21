//
//  DeleteRegistrationsViewController.m
//  Timee
//
//  Created by Morten Hornbech on 25/05/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppDelegate.h"
#import "DeleteRegistrationsViewController.h"
#import "Registration.h"
#import "SelectRegistrationsView.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerSection.h"
#import "TimerTableRow.h"

@implementation DeleteRegistrationsViewController

@synthesize emptyTimersAfterDeletion = _emptyTimersAfterDeletion;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addEmptyTimers];
	((SelectRegistrationsView *)self.view).title.text = @"Delete Data";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.selectRegistrationsView.tableView.userInteractionEnabled = YES;
    self.selectRegistrationsView.cancelButton.enabled = YES;
}

- (void)addEmptyTimers
{
    NSMutableArray *allTimers = [NSMutableArray arrayWithArray:self.timerTableRows];
    
    for(TimerTableRow *row in [TimeeData instance].timerTableRows)
    {
        if (row.timer.sections.count == 0)
            [allTimers addObject:row];
    }
    
    self.timerTableRows = allTimers;
}

- (void)performActionOnTimerSections:(NSArray *)sections andEmptyTimers:(NSArray *)timers
{
    [self.selectRegistrationsView.activityIndicator startAnimating];
    
    self.selectRegistrationsView.tableView.userInteractionEnabled = NO;
    self.selectRegistrationsView.cancelButton.enabled = NO;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:0.3];
    [UIView setAnimationDuration:0.3];
    
    self.selectRegistrationsView.doneButton.alpha = 0.0;
    self.selectRegistrationsView.activityIndicator.alpha = 1.0;
    
    [UIView commitAnimations];
    
    __block NSMutableArray *emptyTimers = [[NSMutableArray alloc] init];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
        context.persistentStoreCoordinator = [TimeeData context].persistentStoreCoordinator;
        [[TimeeData instance] setContext:context];
        [[TimeeData instance] setRegistrationTableSections:[[TimeeData instance] fetchRegistrationTableSections]];
        
        NSMutableArray *movedSections = [[NSMutableArray alloc] initWithCapacity:sections.count];
        
        for (TimerSection *section in sections)
            [movedSections addObject:[[TimeeData context] objectWithID:section.objectID]];

        for (Timer *timer in timers)
            [emptyTimers addObject:[[TimeeData context] objectWithID:timer.objectID]];
        
        for (TimerSection *section in movedSections)
        {
            if (section.timer.sections.count == 1)
                [emptyTimers addObject:section.timer];
            
            NSArray *registrations = [NSArray arrayWithArray:section.registrations.allObjects];
            
            for (Registration *registration in registrations)
            {
                if (registration.endTime != nil)
                    [[TimeeData instance] deleteRegistration:registration];
                else 
                {
                    if (section.timer.sections.count == 1)
                        [emptyTimers removeObject:section.timer];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[TimeeData context] save:NULL];
            
            [[TimeeData instance] setContext:[(AppDelegate *)[UIApplication sharedApplication].delegate managedObjectContext]];
            [[TimeeData instance] setRegistrationTableSections:[[TimeeData instance] fetchRegistrationTableSections]];
            [TimeeData commit];
            
            self.selectRegistrationsView.doneButton.alpha = 1.0;
            self.selectRegistrationsView.activityIndicator.alpha = 0.0;
            [self.selectRegistrationsView.activityIndicator stopAnimating];
            
            self.selectRegistrationsView.tableView.userInteractionEnabled = YES;
            self.selectRegistrationsView.cancelButton.enabled = YES;
            
            if (emptyTimers.count != 0)
            {
                NSMutableArray *movedEmptyTimers = [[NSMutableArray alloc] init];
                
                for (Timer* timer in emptyTimers)
                    [movedEmptyTimers addObject:[[TimeeData context] objectWithID:timer.objectID]];

                self.emptyTimersAfterDeletion = movedEmptyTimers;
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" 
                                                                    message:@"Should timers with no remaining registrations be deleted?"
                                                                   delegate:self
                                                          cancelButtonTitle:@"No" 
                                                          otherButtonTitles:@"Yes", nil];
                
                [alertView show];      
            }
            else
                [self.delegate selectRegistrationsViewControllerDidFinish:self];
        });
    });
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        for (Timer *timer in self.emptyTimersAfterDeletion)
        {
            [[TimeeData instance] deleteTimerTableRow:timer.timerTableRow];
            [[TimeeData instance].timerTableRows removeObject:timer.timerTableRow];
        }
        
        [TimeeData commit];
    }
    
    [self.delegate selectRegistrationsViewControllerDidFinish:self];
}

@end
