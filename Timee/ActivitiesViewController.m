//
//  ActivitiesViewController.m
//  Timee
//
//  Created by Morten Hornbech on 06/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppColors.h"
#import "ActivitiesView.h"
#import "ActivitiesViewController.h"
#import "RedmineInfo.h"
#import "RedmineView.h"
#import "RedmineViewController.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerTableRow.h"

@interface ActivitiesViewController ()

@end

@implementation ActivitiesViewController

@synthesize activitiesView = _activitiesView;
@synthesize activitiesById = _activitiesById;
@synthesize sortedIds = _sortedIds;
@synthesize redmine = _redmine;;
@synthesize redmineViewController = _redmineViewController;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    self.activitiesView = (ActivitiesView *)self.view;
    self.activitiesView.tableView.backgroundColor = self.activitiesView.backgroundColor = [AppColors gold];   
    self.activitiesView.title.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.activitiesView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.activitiesView.tableView.frame;
        self.activitiesView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
    }
    
    [self refreshActivities];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.activitiesView.tableView.indexPathForSelectedRow != nil)
    {
        [self.activitiesView.tableView deselectRowAtIndexPath:self.activitiesView.tableView.indexPathForSelectedRow animated:NO];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Actions

- (IBAction)cancel
{
    [self.redmineViewController activitiesViewControllerDidFinish:self];
}

#pragma mark - Instance Methods

- (IBAction)refreshActivities
{
    self.activitiesView.cancelButton.enabled = NO;
    self.activitiesView.refreshButton.enabled = NO;
    self.activitiesView.tableView.hidden = YES;
    [self.activitiesView.activityIndicator startAnimating];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL *serverUrl = self.redmineViewController.serverUrl;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[serverUrl URLByAppendingPathComponent:@"login"]];
        
        NSString *username = [self.redmineViewController.username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *password = [self.redmineViewController.password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *post = [NSString stringWithFormat:@"username=%@&password=%@", username, password];
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
        
        [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
        [request setHTTPMethod:@"POST"];
        
        NSHTTPURLResponse *response;
        NSError *error;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (error != nil)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No response!" message:@"No server responded at the specified URL." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            
            [alertView show];
        }
        else
        {
            @try
            {
                NSString *path = [NSString stringWithFormat:@"issues/%@/time_entries/new", self.redmine.issueId];
                request = [NSMutableURLRequest requestWithURL:[serverUrl URLByAppendingPathComponent:path]];
                [request setValue:[response.allHeaderFields valueForKey:@"Set-Cookie"] forHTTPHeaderField:@"Cookie"];

                NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];            
                NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                NSRange range = [content rangeOfString:@"id=\"time_entry_activity_id\""];
                
                content = [content substringFromIndex:range.location + range.length];
                range = [content rangeOfString:@"<option"];
                
                NSMutableDictionary *activitiesById = [[NSMutableDictionary alloc] init];
                
                while (range.length != 0)
                {
                    NSRange leftBoundId = [content rangeOfString:@"value=\""];
                    content = [content substringFromIndex:leftBoundId.location + leftBoundId.length];            
                    NSInteger rightBoundId = [content rangeOfString:@"\""].location;
                    NSString *activityId = [content substringToIndex:rightBoundId];
                    
                    if (activityId.length != 0)
                    {
                        NSInteger leftBoundName = [content rangeOfString:@">"].location + 1;
                        NSInteger rightBoundName = [content rangeOfString:@"<"].location;
                        NSString *activityName = [content substringWithRange:NSMakeRange(leftBoundName, rightBoundName - leftBoundName)];
                        
                        [activitiesById setValue:activityName forKey:activityId];            
                        range = [content rangeOfString:@"<option"];
                    }
                }
                
                self.activitiesById = activitiesById;                
                self.sortedIds = [activitiesById.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    return [[NSNumber numberWithInt:((NSString *)obj1).intValue] compare:[NSNumber numberWithInt:((NSString *)obj2).intValue]];
                }];
            }
            @catch(id exception)
            {
                self.sortedIds = nil;
                self.activitiesById = nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unexpected error!" message:@"The list of activities could not be retrieved. The most likely cause is authentication failure." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    
                    [alertView show];
                });
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.activitiesView.cancelButton.enabled = YES;
            self.activitiesView.refreshButton.enabled = YES;
            self.activitiesView.tableView.hidden = NO;
            [self.activitiesView.activityIndicator stopAnimating];
            [self.activitiesView.tableView reloadData];
        });
    });
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sortedIds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"ActivitiesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
    {                
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.frame = CGRectMake(0, 0, 320, 44);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_small"]];
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_small_selected"]];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 280, 44)];
        label.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
        label.textColor = [AppColors black];
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        label.backgroundColor = [UIColor clearColor];
        label.tag = 1;
        [cell addSubview:label];
    }
    
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    label.text = [self.activitiesById valueForKey:[self.sortedIds objectAtIndex:indexPath.row]];
    
    return cell;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.redmine.activityId = [self.sortedIds objectAtIndex:indexPath.row];
    self.redmine.activityName = [self.activitiesById valueForKey:self.redmine.activityId];
    [TimeeData commit];
    
    NSIndexPath *selectedIndexPath = self.redmineViewController.redmineView.tableView.indexPathForSelectedRow;
    [self.redmineViewController.redmineView.tableView reloadSections:[NSIndexSet indexSetWithIndex:selectedIndexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    [self.redmineViewController activitiesViewControllerDidFinish:self];
}

@end
