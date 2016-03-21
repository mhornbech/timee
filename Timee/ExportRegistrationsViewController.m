//
//  DeleteRegistrationsViewController.m
//  Timee
//
//  Created by Morten Hornbech on 25/05/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "ExportRegistrationsViewController.h"
#import "SelectRegistrationsView.h"
#import "TargetView.h"
#import "TargetViewController.h"
#import "ViewControllerCache.h"

@implementation ExportRegistrationsViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	((SelectRegistrationsView *)self.view).title.text = @"Export Data";
}

#pragma mark - Instance Methods

- (void)performActionOnTimerSections:(NSArray *)sections andEmptyTimers:(NSArray *)timers
{
    TargetViewController *viewController = (TargetViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Target"];
    
    if (viewController == nil)
    {   
        viewController = [[TargetViewController alloc] initWithNibName:@"TargetView" bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Target"];
    }
    else
        [viewController.targetView.tableView reloadData];
    
    viewController.selectedRows = self.selectedRows;
    viewController.timerTableRows = self.timerTableRows;
    viewController.startTime = self.startTime;
    viewController.endTime = self.endTime;
    viewController.sections = sections;
    viewController.cancelDelegate = self;
    viewController.doneDelegate = self.delegate; 
    
    [self presentModalViewController:viewController animated:YES]; 
}

#pragma mark - Target View Delegate

- (void)targetViewControllerDidFinish:(TargetViewController *)controller
{
    [self refresh];
    [self.selectRegistrationsView.tableView reloadData];
    [self dismissModalViewControllerAnimated:YES];
}

@end
