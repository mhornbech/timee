//
//  TimerTableViewController.m
//  Timee
//
//  Created by Morten Hornbech on 06/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppColors.h"
#import "AppDelegate.h"
#import "OptionsView.h"
#import "Registration.h"
#import "RegistrationTableRow.h"
#import "RegistrationTableSection.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerInfo.h"
#import "TimerSection.h"
#import "TimerTable.h"
#import "TimerTableCellView.h"
#import "TimerTableRow.h"
#import "TimerTableView.h"
#import "TimerTableView_Landscape.h"
#import "TimerTableViewController.h"
#import "TimerView.h"
#import "ViewControllerCache.h"
#import "TestUtilities.h"
#import "dispatch/queue.h"

#define kTimerTableCellIdentifier                   @"TimerTableCell"

#define kOptionsViewNibName                         @"OptionsView"
#define kInfoViewNibName                            @"InfoView"
#define kTimerViewNibName                           @"TimerView"

#define kRegistrationEntityName                     @"Registration"
#define kTimerEntityName                            @"Timer"
#define kTimerInfoEntityName                        @"TimerInfo"
#define kTimerTableEntityName                       @"TimerTable"

#define kTutorialKey                                @"TutorialShown"

@implementation TimerTableViewController

@synthesize counter = _counter;
@synthesize timerTableAdjuster = _timerTableAdjuster;
@synthesize indexPathForTimerBeingDeleted = _indexPathForTimerBeingDeleted;
@synthesize cell = _cell;
@synthesize timerTableView = _timerTableView;
@synthesize timerTableView_Landscape = _timerTableView_Landscape;
@synthesize viewWillAppearCompleted = _viewWillAppearCompleted;
@synthesize landscapeMode = _landscapeMode;

static TimerTableViewController *_instance;
dispatch_queue_t queue;
int maxFullRowsInView;

#pragma mark - Actions

- (IBAction)onDisplayTapped:(id)sender
{
    BOOL isRunning = [[TimeeData instance].timerTable.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]];
    
    if (isRunning)
    {
        [TimeeData instance].timerTable.isRunning = [NSNumber numberWithBool:NO];        
        TimerTableRow *row = [[TimeeData instance].timerTableRows objectAtIndex:0];
       
        Registration *registration = [row.registrations objectsPassingTest:^BOOL(id obj, BOOL *stop) {
            return ((Registration *)obj).endTime == nil;
        }].anyObject;        
        
        registration.endTime = row.lastUseTime = [NSDate date];
        
        [TimerViewController adaptRegistrationstoRegistration:registration];
        [TimerViewController splitMultiDayRegistration:registration];
    }
    else
    {        
        if ([TimeeData instance].timerTableRows.count != 0)
        {
            [TimeeData instance].timerTable.isRunning = [NSNumber numberWithBool:YES];            
            TimerTableRow *row = [[TimeeData instance].timerTableRows objectAtIndex:0];

            Registration *registration = [NSEntityDescription insertNewObjectForEntityForName:kRegistrationEntityName inManagedObjectContext:[TimeeData context]];
            registration.startTime = [NSDate date];            
            registration.endTime = row.lastUseTime = nil;
            
            [[TimeeData instance] addRegistration:registration toTimer:row.timer];                            
        }
        else
        {            
            [self showAddTimer];
            return;
        }
    }
    
    [TimeeData commit];
}

- (IBAction)fadeWheelOut
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.15];
    
    self.timerTableView.wheel.alpha = self.timerTableView_Landscape.wheel.alpha = 0.5;
    
    [UIView commitAnimations];
}

- (IBAction)fadeWheelIn
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.15];
    
    self.timerTableView.wheel.alpha = self.timerTableView_Landscape.wheel.alpha = 1.0;
    
    [UIView commitAnimations];
}

- (IBAction)showAddTimer
{
    Timer *timer = [NSEntityDescription insertNewObjectForEntityForName:kTimerEntityName inManagedObjectContext:[TimeeData context]];
    TimerInfo *info = [NSEntityDescription insertNewObjectForEntityForName:kTimerInfoEntityName inManagedObjectContext:[TimeeData context]];
    
    timer.timerTableSummaryType = @"current";
    info.index = [NSNumber numberWithInt:0];
    info.title = @"";
    [timer addInfoObject:info];
    
    TimerViewController *viewController = (TimerViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Timer"];
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {
        viewController = [[TimerViewController alloc] initWithNibName:kTimerViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Timer"];
    }
    
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

- (void)onInfoButtonTapped:(id)sender
{
    InfoViewController *viewController = (InfoViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Info"];
    
    if (viewController == nil)
    {
        viewController = [[InfoViewController alloc] initWithNibName:kInfoViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Info"];
    }
        
    viewController.delegate = self;    
    [self presentModalViewController:viewController animated:YES]; 
}

- (void)onOptionsButtonTapped:(id)sender
{
    OptionsViewController *viewController = (OptionsViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Options"];
    
    if (viewController == nil)
    {
        viewController = [[OptionsViewController alloc] initWithNibName:kOptionsViewNibName bundle:[NSBundle mainBundle]];    
        [[ViewControllerCache instance] addViewController:viewController forName:@"Options"];
    }
    else
    {
        [viewController.optionsView.tableView reloadData];
        [viewController.optionsView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    viewController.delegate = self;

    [self presentModalViewController:viewController animated:YES]; 
}

- (void)onShowRunningTimerButtonTapped:(id)sender
{    
    TimerTableRow *row = [[TimeeData instance].timerTableRows objectAtIndex:0];
    
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

- (void)onShowTimerButtonTapped:(id)sender
{
    UIView *view = (UIView *)sender;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.timerTableView.tableView indexPathForCell:cell];    
    TimerTableRow *row = [[TimeeData instance].timerTableRows objectAtIndex:indexPath.row + 1];
    
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

- (void)onDeleteButtonTapped:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
                                                            message:@"This will delete the timer and all contained registrations."
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel" 
                                                  otherButtonTitles:@"OK", nil];
        
        
    if (![((UIView *)sender).superview isKindOfClass:[TimerTableView class]])
    {
        UIView *view = (UIView *)sender;
        while (![view isKindOfClass:[UITableViewCell class]]) {
            view = [view superview];
        }
        
        UITableViewCell *cell = (UITableViewCell *)view;
        self.indexPathForTimerBeingDeleted = [self.timerTableView.tableView indexPathForCell:cell];
    }
    else 
    {
        self.indexPathForTimerBeingDeleted = nil;
    }
    
    [alertView show];        
}

#pragma mark - Info View Delegate

- (void)infoViewControllerDidFinish:(InfoViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Static Methods

+ (TimerTableViewController *)instance;
{
    if (_instance == nil)
        _instance = [[TimerTableViewController alloc] initWithNibName:@"TimerTableView" bundle:nil];
    
    return _instance;
}

+ (NSArray *)getTitleLabelTexts:(NSArray *)info
{
    NSArray *sortedInfo = [info sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((TimerInfo *)obj1).index compare:((TimerInfo *)obj2).index];
    }];
    
    NSString *titleLabelText = ((TimerInfo *)[sortedInfo objectAtIndex:0]).title;
    NSString *subtitleLabelText = info.count > 1 ? ((TimerInfo *)[sortedInfo objectAtIndex:1]).title : @"";
    
    return [NSArray arrayWithObjects:titleLabelText, subtitleLabelText, nil];
}

+ (NSArray *)getRunningTime:(TimerTableRow *)row ofType:(NSString *)type
{
    return [TimerTableViewController getRunningTime:row ofType:type between:nil and:nil];
}

+ (NSArray *)getRunningTime:(TimerTableRow *)row ofType:(NSString *)type between:(NSDate *)startDate and:(NSDate *)endDate
{
    int totalSeconds = 0;
    
    if ([type isEqualToString:@"current"] && row.timer.lastResetTime != nil)
    {
        for (Registration *reg in row.registrations)
        {
            NSDate *lastResetTime = row.timer.lastResetTime; 
            NSDate *currentTime = [NSDate date];
            NSDate *startTime = reg.startTime;
            NSDate *endTime = reg.endTime;
            
            if ([startTime compare:currentTime] == NSOrderedDescending
                || (endTime != nil && [reg.endTime compare:lastResetTime] == NSOrderedAscending))
                continue;
            
            if ([startTime compare:lastResetTime] == NSOrderedAscending)
                startTime = lastResetTime;
            
            if (endTime == nil)
            {
                for (Registration *otherReg in row.registrations)
                {
                    if([otherReg.endTime compare:startTime] == NSOrderedDescending 
                       && [otherReg.startTime compare:currentTime] == NSOrderedAscending)
                    {
                        NSDate *otherStartTime = [otherReg.startTime compare:startTime] == NSOrderedAscending ? startTime : otherReg.startTime;                    
                        NSDate *otherEndTime = [otherReg.endTime compare:currentTime] == NSOrderedDescending ? currentTime : otherReg.endTime;
                        
                        totalSeconds -= [otherEndTime timeIntervalSinceDate:otherStartTime];
                    }
                }
            }
            
            if (endTime == nil || [endTime compare:currentTime] == NSOrderedDescending)
                endTime = currentTime;
            
            totalSeconds += [NSNumber numberWithDouble:[endTime timeIntervalSinceDate:startTime]].intValue;
        }
    }
    else 
    {
        NSArray *sections = nil;
        
        if (startDate != nil || endDate != nil)
        {
            sections = [row.timer.sections.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [((TimerSection *)obj2).date compare:((TimerSection *)obj1).date];
            }];
        }
        else
            sections = row.timer.sections.allObjects;
        
        for (TimerSection *section in sections)
        {
            if (endDate != nil && [section.date compare:endDate] == NSOrderedDescending)
                continue;
            
            if (startDate != nil && [section.date compare:startDate] == NSOrderedAscending)
                break;
            
            totalSeconds += [TimerViewController getTotalForRegistrations:section.registrations.allObjects];
        }
        
        for (Registration *reg in row.registrations.allObjects)
        {
            if (reg.endTime != nil)
            {
                double duration = [reg.endTime timeIntervalSinceDate:reg.startTime];
                
                if (duration < 59.9)
                {
                    if ((endDate != nil && [reg.startTime compare:endDate] == NSOrderedDescending)
                        || (startDate != nil && [reg.startTime compare:startDate] == NSOrderedAscending))
                        continue;
                    
                    totalSeconds += duration;
                }
            }
        }
    }
    
    int hours = totalSeconds / 3600;
    int minutes = (totalSeconds - hours * 3600) / 60;
    int seconds = totalSeconds - hours * 3600 - minutes * 60;
    
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:hours], [NSNumber numberWithInt:minutes], [NSNumber numberWithInt:seconds], nil];
}

#pragma mark - Instance Methods

- (void)deleteTimerAtIndexPath:(NSIndexPath *)indexPath
{
    [[TimeeData instance] deleteTimerTableRow:[[TimeeData instance].timerTableRows objectAtIndex:indexPath.row + 1]];
    [[TimeeData instance].timerTableRows removeObjectAtIndex:indexPath.row + 1];
    
    NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
    [self.timerTableView.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    
    int rowCount = [TimeeData instance].timerTableRows.count;
    
    if (rowCount < maxFullRowsInView + 1)
    {
        [self transformArrowButton];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        CGFloat height = (rowCount - 1) * 63.0;
        [self.timerTableView.tableView setFrame:CGRectMake(0.0, [[UIScreen mainScreen] bounds].size.height - height, 320, height)];
        
        [UIView commitAnimations];
        
        if (rowCount == 0)
        {
            [self.timerTableView.displayButton setImage:[UIImage imageNamed:@"options_big"] forState:UIControlStateNormal];
            self.timerTableView.addTimerArrow.hidden = YES;
            self.timerTableView.addTimerSmallLabel.hidden = YES;
        }
    }
    
    [TimeeData commit];
}

- (NSArray *)getLabelTexts:(TimerTableRow *)row;
{
    NSArray *runningTime = [TimerTableViewController getRunningTime:row ofType:row.timer.timerTableSummaryType];
    int hours = ((NSNumber *)[runningTime objectAtIndex:0]).intValue;
    int minutes = ((NSNumber *)[runningTime objectAtIndex:1]).intValue;

    NSArray *titleLabelTexts = [TimerTableViewController getTitleLabelTexts:row.timer.info.allObjects];
    NSString *timeLabelText = hours < 1000 ? [NSString stringWithFormat:@"%d:%@%d", hours, minutes < 10 ? @"0" : @"", minutes] : [NSString stringWithFormat:@"%d", hours];
    
    return [NSArray arrayWithObjects:[titleLabelTexts objectAtIndex:0], [titleLabelTexts objectAtIndex:1], timeLabelText, nil];
}

- (void)initTimer
{
    self.counter = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimerFire) userInfo:nil repeats:YES];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:self.counter forMode:NSRunLoopCommonModes];
    [runLoop addTimer:self.counter forMode:UITrackingRunLoopMode];
}

- (void)initAdjuster
{
    self.timerTableAdjuster = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onAdjustTableView) userInfo:nil repeats:YES];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:self.timerTableAdjuster forMode:NSRunLoopCommonModes];
    [runLoop addTimer:self.timerTableAdjuster forMode:UITrackingRunLoopMode];
}

- (void)onTimerFire
{
    [self onTimerFire:0.5];
}

- (void)onTimerFire:(NSTimeInterval)animationDuration
{
    if ([[TimeeData instance].timerTable.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]] && self.viewWillAppearCompleted)
    {
        TimerTableRow *row = [[TimeeData instance].timerTableRows objectAtIndex:0];
        
        NSArray *runningTime = [TimerTableViewController getRunningTime:row ofType:row.timer.timerTableSummaryType];
        int hours = ((NSNumber *)[runningTime objectAtIndex:0]).intValue;
        int minutes = ((NSNumber *)[runningTime objectAtIndex:1]).intValue;
        int seconds = ((NSNumber *)[runningTime objectAtIndex:2]).intValue;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        
        CGAffineTransform transform = CGAffineTransformMakeRotation((seconds + 1) * M_PI / 30);
        
        if (self.landscapeMode)
            self.timerTableView_Landscape.wheel.transform = transform;
        else
            self.timerTableView.wheel.transform = transform;
        
        [UIView commitAnimations];

        NSString *text = hours < 1000 ? [NSString stringWithFormat:@"%d:%@%d", hours, minutes < 10 ? @"0" : @"", minutes] : [NSString stringWithFormat:@"%d", hours];
        
        if (self.landscapeMode)
            self.timerTableView_Landscape.timeLabel.text = text;
        else
            self.timerTableView.timeLabel.text = text;
    }
}


NSInteger lastTopRowIndex = 0;
BOOL observePosition = NO;
BOOL scrollingDown = NO;
BOOL adjustEnabled = YES;

- (void)onAdjustTableView
{
    if (!adjustEnabled || self.timerTableView.tableView.visibleCells.count == 0)
        return;
    
    NSInteger topRowIndex = [self.timerTableView.tableView indexPathForCell:[self.timerTableView.tableView.visibleCells objectAtIndex:0]].row;
    
    if (topRowIndex != lastTopRowIndex)
    {
        scrollingDown = topRowIndex > lastTopRowIndex;
        observePosition = YES;
        lastTopRowIndex = topRowIndex;
    }
    else
    {
        if (observePosition && !self.timerTableView.tableView.isTracking)
        {
            observePosition = NO;
            lastTopRowIndex = scrollingDown ? topRowIndex + 1 : topRowIndex;
            [self.timerTableView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastTopRowIndex inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

- (void)onTimerTableCellTapped:(NSIndexPath *)indexPath
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];

    [self setLabelsAlpha:0.0];
    
    [UIView commitAnimations];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelay:0.25];
    
    TimerTableCellView *cellView = (TimerTableCellView *)[[self.timerTableView.tableView cellForRowAtIndexPath:indexPath].contentView.subviews objectAtIndex:0];    
    self.timerTableView.titleLabel.text = cellView.titleLabel.text;
    self.timerTableView.subtitleLabel.text = cellView.subtitleLabel.text;    
    self.timerTableView.timeLabel.text = cellView.timeLabel.text;    
    
    [self setLabelsAlpha:1.0];    
    
    [UIView commitAnimations];
}

- (void)setLabelsAlpha:(CGFloat)alpha
{
    self.timerTableView.timeLabel.alpha = alpha;
    self.timerTableView.titleLabel.alpha = alpha;
    self.timerTableView.subtitleLabel.alpha = alpha;
}

BOOL addTimerArrowRotated = NO;

- (void)onPanRecognized:(UIPanGestureRecognizer *)recognizer
{
    if(addTimerArrowRotated ^ (((NSIndexPath *)self.timerTableView.tableView.indexPathsForVisibleRows.lastObject).row < maxFullRowsInView
       && [recognizer translationInView:self.timerTableView.tableView].y > (maxFullRowsInView - 1) * 63 - 20))
    {
        if ((recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged))
        {
            addTimerArrowRotated = !addTimerArrowRotated;
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.3];
            
            self.timerTableView.addTimerArrow.transform = CGAffineTransformMakeRotation(addTimerArrowRotated ? 0 : M_PI / 2);
            
            [UIView commitAnimations];
        }
    }
    
    if (addTimerArrowRotated && recognizer.state == UIGestureRecognizerStateEnded)
        [self showAddTimer];
}

- (void)onSwipeRecognized:(UISwipeGestureRecognizer *)recognizer
{
    recognizer.enabled = NO;    
    
    if ([recognizer.view.superview isKindOfClass:[TimerTableView class]])
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        
        self.timerTableView.titleLabel.alpha = 0.0;
        self.timerTableView.subtitleLabel.alpha = 0.0;
        
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelay:0.25];
        
        self.timerTableView.deleteButton.alpha = 1.0;
        
        [UIView commitAnimations];
        
        if (self.timerTableView.tapRecognizer == nil)
        {
            self.timerTableView.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapRecognized:)];
            self.timerTableView.tapRecognizer.delegate = self;
            [self.timerTableView.displayButton addGestureRecognizer:self.timerTableView.tapRecognizer];        
        }
        
        self.timerTableView.tapRecognizer.enabled = YES;
    }
    else 
    {    
        TimerTableCellView *cellView = (TimerTableCellView *)recognizer.view;
        
        UIView *view = cellView;
        while (![view isKindOfClass:[UITableViewCell class]]) {
            view = [view superview];
        }
        
        UITableViewCell *cell = (UITableViewCell *)view;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        
        cellView.detailsButton.alpha = 0.0;
        cellView.timeLabel.alpha = 0.0;
        
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelay:0.25];
        
        cellView.deleteButton.alpha = 1.0;
        cellView.deleteButton.highlighted = NO;
        
        [UIView commitAnimations];
        
        if (cellView.tapRecognizer == nil)
        {
            cellView.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapRecognized:)];
            cellView.tapRecognizer.delegate = self;
            [cellView addGestureRecognizer:cellView.tapRecognizer];
        }
        
        cellView.tapRecognizer.enabled = YES;
    }
}

- (void)onTapRecognized:(UITapGestureRecognizer *)recognizer
{
    recognizer.enabled = NO;
    
    if ([recognizer.view.superview isKindOfClass:[TimerTableView class]])
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        
        self.timerTableView.deleteButton.alpha = 0.0;
        
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelay:0.25];
        
        self.timerTableView.titleLabel.alpha = 1.0;
        self.timerTableView.subtitleLabel.alpha = 1.0;
        
        [UIView commitAnimations];
        
        self.timerTableView.swipeRecognizer.enabled = YES;
    }
    else
    {
        TimerTableCellView *view = (TimerTableCellView *)recognizer.view;    
        
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
        
        view.detailsButton.alpha = 1.0;
        view.timeLabel.alpha = 1.0;
        
        [UIView commitAnimations];
        
        view.swipeRecognizer.enabled = YES;
    }
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer.class isSubclassOfClass:[UITapGestureRecognizer class]] && touch.view.tag == -1)
        return NO;
    else if ([gestureRecognizer.class isSubclassOfClass:[UIPanGestureRecognizer class]] && !self.timerTableView.tableView.scrollEnabled)
        return NO;

    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.indexPathForTimerBeingDeleted != nil)
    {
        UITableViewCell *cell = [self.timerTableView.tableView cellForRowAtIndexPath:self.indexPathForTimerBeingDeleted];
        
        TimerTableCellView *cellView = [cell.contentView.subviews objectAtIndex:0];
        cellView.swipeRecognizer.enabled = YES;
        cellView.tapRecognizer.enabled = NO;
        cellView.deleteButton.alpha = 0.0;
        cellView.detailsButton.alpha = 1.0;
        cellView.timeLabel.alpha = 1.0;
        
        if (buttonIndex == 1)
            [self deleteTimerAtIndexPath:self.indexPathForTimerBeingDeleted];
    }
    else 
    {
        self.timerTableView.titleLabel.alpha = 1.0;
        self.timerTableView.subtitleLabel.alpha = 1.0;        
        self.timerTableView.deleteButton.alpha = 0.0;
        self.timerTableView.swipeRecognizer.enabled = YES;
        self.timerTableView.tapRecognizer.enabled = NO;
        
        if (buttonIndex == 1)
        {                        
            if ([[TimeeData instance].timerTable.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]])
                [self onDisplayTapped:nil];
            
            [[TimeeData instance] deleteTimerTableRow:[[TimeeData instance].timerTableRows objectAtIndex:0]];
            [[TimeeData instance].timerTableRows removeObjectAtIndex:0];                        
            
            [TimeeData commit];
            
            if ([TimeeData instance].timerTableRows.count == 0)
            {
                self.timerTableView.titleLabel.text = @"";
                self.timerTableView.subtitleLabel.text = @"";
                self.timerTableView.timeLabel.text = @"";

                self.timerTableView.showTimerButton.hidden = YES;
                [self.timerTableView.displayButton setImage:[UIImage imageNamed:@"options_big"] forState:UIControlStateNormal];
                self.timerTableView.addTimerArrow.hidden = YES;
                self.timerTableView.addTimerSmallLabel.hidden = YES;
                
                self.timerTableView.addTimerLabel.hidden = NO;   
                self.timerTableView.swipeRecognizer.enabled = NO;
                
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.5];
                
                CGAffineTransform transform = CGAffineTransformMakeRotation(0);
                
                if (self.landscapeMode)
                    self.timerTableView_Landscape.wheel.transform = transform;
                else
                    self.timerTableView.wheel.transform = transform;
                
                [UIView commitAnimations];
            }
            else
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                [self onTimerTableCellTapped:indexPath];
                [self.timerTableView.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
                
                int rowCount = [TimeeData instance].timerTableRows.count;
                
                if (rowCount < maxFullRowsInView + 1)
                {
                    [self transformArrowButton];
                    [UIView beginAnimations:nil context:NULL];
                    [UIView setAnimationDuration:0.25];
                    CGFloat height = (rowCount - 1) * 63.0;
                    [self.timerTableView.tableView setFrame:CGRectMake(0.0, [[UIScreen mainScreen] bounds].size.height - height, 320, height)];
                    [UIView commitAnimations];
                }
            }
        }
    }
}

#pragma mark - Options View Delegate

- (void)optionsViewControllerDidFinish:(OptionsViewController *)controller
{    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTimerTableCellIdentifier];
    TimerTableCellView *cellView = nil;
    
    if (cell == nil)
    {
        [[NSBundle mainBundle] loadNibNamed:kTimerTableCellIdentifier owner:self options:nil];
        cell = self.cell;
        
        cellView = [cell.contentView.subviews objectAtIndex:0];
        cellView.deleteButton.alpha = 0.0;
        cellView.swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeRecognized:)];
        cellView.swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft;        
        [cellView addGestureRecognizer:cellView.swipeRecognizer];
        
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;

        cellView.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:16.0];
        cellView.subtitleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:15.0];
        cellView.timeLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18.0];
        
        cellView.titleLabel.textColor = cellView.subtitleLabel.textColor = cellView.timeLabel.textColor = [AppColors black];
    }
    else
        cellView = [cell.contentView.subviews objectAtIndex:0];
    
    TimerTableRow *row = [[TimeeData instance].timerTableRows objectAtIndex:indexPath.row + 1];
    
    cellView.titleLabel.text = cellView.subtitleLabel.text = cellView.timeLabel.text = @"";
    cellView.detailsButton.hidden = YES;
    cellView.detailsButton.alpha = 1;
    cellView.deleteButton.alpha = 0;
    cellView.timeLabel.alpha = 1;
    cellView.swipeRecognizer.enabled = YES;
    
    if (cellView.tapRecognizer != nil)
        cellView.tapRecognizer.enabled = NO;
    
    cell.userInteractionEnabled = NO;
    [cellView.activityIndicator startAnimating];
    
    cellView.tag = indexPath.row;
    
    dispatch_async(queue, ^{
        NSArray *labelTexts = [self getLabelTexts:row];            
        
        if (cellView.tag == indexPath.row)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [cellView.activityIndicator stopAnimating];
                cellView.titleLabel.text = [labelTexts objectAtIndex:0];
                cellView.subtitleLabel.text = [labelTexts objectAtIndex:1];
                cellView.timeLabel.text = [labelTexts objectAtIndex:2];
                cellView.detailsButton.hidden = NO;
                cell.userInteractionEnabled = YES;
            });
        }
    });
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [TimeeData instance].timerTableRows.count - 1;
}

#pragma mark - Table View Delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    TimerTableCellView *cellView = [cell.contentView.subviews objectAtIndex:0];
    
    if (cellView.tapRecognizer.enabled)
        return nil;
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isRunning = [[TimeeData instance].timerTable.isRunning isEqualToNumber:[NSNumber numberWithInt:1]];
    TimerTableRow *row = [[TimeeData instance].timerTableRows objectAtIndex:indexPath.row + 1];
    NSDate *date = [NSDate date];
    
    [[TimeeData instance].timerTableRows removeObjectAtIndex:indexPath.row + 1];
    [[TimeeData instance].timerTableRows insertObject:row atIndex:0];
    
    if (isRunning)
    {
        TimerTableRow *previousRow = [[TimeeData instance].timerTableRows objectAtIndex:1];        
        Registration *previousRegistration = [previousRow.registrations objectsPassingTest:^BOOL(id obj, BOOL *stop) {
            return ((Registration *)obj).endTime == nil;
        }].anyObject;        
        previousRegistration.endTime = previousRow.lastUseTime = date;        
        
        [TimerViewController adaptRegistrationstoRegistration:previousRegistration];
        [TimerViewController splitMultiDayRegistration:previousRegistration];
    }
    
    Registration *newRegistration = [NSEntityDescription insertNewObjectForEntityForName:kRegistrationEntityName inManagedObjectContext:[TimeeData context]];
    newRegistration.startTime = [NSDate date];
    newRegistration.endTime = row.lastUseTime = nil;
    
    [[TimeeData instance] addRegistration:newRegistration toTimer:row.timer];
    [TimeeData instance].timerTable.isRunning = [NSNumber numberWithBool:YES];
    
    [TimeeData commit];
    
    [self onTimerTableCellTapped:indexPath];
    
    NSIndexPath *top = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];    
    [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:top] withRowAnimation: UITableViewRowAnimationTop];
    
    [tableView endUpdates];   
    
    adjustEnabled = NO;
    
    if (tableView.visibleCells.count > 0)
        [tableView scrollToRowAtIndexPath:top atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    [self performSelector:@selector(enableAdjust) withObject:nil afterDelay:2];
    
    [self.counter fire];
    [self.counter invalidate];
    [self initTimer];
}

- (void)enableAdjust
{
    adjustEnabled = YES;
}

#pragma mark - Tutorial View Delegate

- (void)tutorialViewControllerDidFinish:(TutorialViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Timer View Delegate

- (void)timerViewControllerDidFinish:(TimerViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - MFMailComposeViewController Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)applicationDidEnterBackground
{
    [self setLabelsAlpha:0.0];
    self.timerTableView.wheel.alpha = 0.0;
    [self.counter invalidate];
    [self.timerTableAdjuster invalidate];
}

- (void)applicationWillEnterForeground 
{
    [self onTimerFire:0];
    
    if (!self.counter.isValid)
        [self initTimer];
    if (!self.timerTableAdjuster.isValid)
        [self initAdjuster];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    
    [self setLabelsAlpha:1.0];
    self.timerTableView.wheel.alpha = 1.0;
    
    [UIView commitAnimations];
    
    if (self.timerTableView.tableView.visibleCells.count > 0)
    {
        [self.timerTableView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

- (BOOL)shouldAutorotate
{
    return self.viewWillAppearCompleted && [TimeeData instance].timerTableRows.count != 0 && self.timerTableView_Landscape != nil;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight || toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        self.landscapeMode = YES;   
        self.view = self.timerTableView_Landscape;
        
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
            self.view.transform = CGAffineTransformMakeRotation(-M_PI / 2);
        else
            self.view.transform = CGAffineTransformMakeRotation(M_PI / 2);

        self.view.bounds = CGRectMake(0.0, 0.0, [[UIScreen mainScreen] bounds].size.height, 320.0);
        
        self.timerTableView_Landscape.wheel.transform = self.timerTableView.wheel.transform;
        self.timerTableView_Landscape.timeLabel.text = self.timerTableView.timeLabel.text;
        self.timerTableView_Landscape.titleLabel.text = self.timerTableView.titleLabel.text;
        self.timerTableView_Landscape.subtitleLabel.text = self.timerTableView.subtitleLabel.text;        
    }
    else
    {
        self.landscapeMode = NO;        
        self.view = self.timerTableView;    
        
        self.view.transform = CGAffineTransformMakeRotation(0.0);
        self.view.bounds = CGRectMake(0.0, 0.0, 320.0, [[UIScreen mainScreen] bounds].size.height);
        
        self.timerTableView.wheel.transform = self.timerTableView_Landscape.wheel.transform;
        self.timerTableView.timeLabel.text = self.timerTableView_Landscape.timeLabel.text;        
    }
}

- (void)viewDidLoad
{
    queue = dispatch_queue_create(nil, NULL);
    maxFullRowsInView = [[UIScreen mainScreen] bounds].size.height == 568 ? 4 : 3;
    
    //[TestUtilities createTestRegistrationsAndTimers];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.timerTableView.frame = self.timerTableView.background.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.timerTableView.tableView.frame;
        self.timerTableView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y + 25, frame.size.width, frame.size.height + 63);
        
        frame = self.timerTableView.addTimerArrow.frame;
        self.timerTableView.addTimerArrow.frame = CGRectMake(frame.origin.x, frame.origin.y + 25, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.addTimerSmallLabel.frame;
        self.timerTableView.addTimerSmallLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 25, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.companyLabel.frame;
        self.timerTableView.companyLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 88, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.wheel.frame;
        self.timerTableView.wheel.frame = CGRectMake(frame.origin.x, frame.origin.y + 13, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.timeLabel.frame;
        self.timerTableView.timeLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 13, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.titleLabel.frame;
        self.timerTableView.titleLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 13, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.subtitleLabel.frame;
        self.timerTableView.subtitleLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 13, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.displayButton.frame;
        self.timerTableView.displayButton.frame = CGRectMake(frame.origin.x, frame.origin.y + 13, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.addTimerLabel.frame;
        self.timerTableView.addTimerLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 13, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.deleteButton.frame;
        self.timerTableView.deleteButton.frame = CGRectMake(frame.origin.x, frame.origin.y + 13, frame.size.width, frame.size.height);
        
        frame = self.timerTableView.showTimerButton.frame;
        self.timerTableView.showTimerButton.frame = CGRectMake(frame.origin.x, frame.origin.y + 13, frame.size.width, frame.size.height);
        
        [self.timerTableView.background setImage:[UIImage imageNamed:@"background-568h"]];
    }
    
    self.timerTableView.addTimerSmallLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:16];
    self.timerTableView.addTimerSmallLabel.textColor = [AppColors gold];
    
    self.timerTableView.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17.0];
    self.timerTableView.subtitleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:16.0];
    self.timerTableView.timeLabel.font = [UIFont fontWithName:@"snAPPit" size:47.0];
    self.timerTableView.addTimerLabel.font = self.timerTableView.titleLabel.font;
    self.timerTableView.companyLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:12.0];
    
    self.timerTableView.swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeRecognized:)];
    self.timerTableView.swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft;
    self.timerTableView.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanRecognized:)];
    self.timerTableView.panRecognizer.delegate = self;
    [self.timerTableView.displayButton addGestureRecognizer:self.timerTableView.swipeRecognizer];
    [self.timerTableView.tableView addGestureRecognizer:self.timerTableView.panRecognizer];
    
    [self initLandscapeView];
    
    [self initTimer];
    [self initAdjuster];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)initLandscapeView
{
    if (self.timerTableView_Landscape == nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"TimerTableView_Landscape" owner:self options:nil];
        self.timerTableView_Landscape.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17.0];
        self.timerTableView_Landscape.subtitleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:16.0];
        self.timerTableView_Landscape.timeLabel.font = [UIFont fontWithName:@"snAPPit" size:47.0];
        
        if ([[UIScreen mainScreen] bounds].size.height == 568)
        {
            self.timerTableView_Landscape.frame = self.timerTableView_Landscape.background.frame = CGRectMake(0, 0, 568, 320);
            
            CGRect frame = self.timerTableView_Landscape.wheel.frame;
            self.timerTableView_Landscape.wheel.frame = CGRectMake(frame.origin.x + 44, frame.origin.y, frame.size.width, frame.size.height);
            
            frame = self.timerTableView_Landscape.titleLabel.frame;
            self.timerTableView_Landscape.titleLabel.frame = CGRectMake(frame.origin.x + 44, frame.origin.y, frame.size.width, frame.size.height);
            
            frame = self.timerTableView_Landscape.subtitleLabel.frame;
            self.timerTableView_Landscape.subtitleLabel.frame = CGRectMake(frame.origin.x + 44, frame.origin.y, frame.size.width, frame.size.height);
            
            frame = self.timerTableView_Landscape.timeLabel.frame;
            self.timerTableView_Landscape.timeLabel.frame = CGRectMake(frame.origin.x + 44, frame.origin.y, frame.size.width, frame.size.height);
            
            frame = self.timerTableView_Landscape.stopTimerButton.frame;
            self.timerTableView_Landscape.stopTimerButton.frame = CGRectMake(frame.origin.x + 44, frame.origin.y, frame.size.width, frame.size.height);
            
            [self.timerTableView_Landscape.background setImage:[UIImage imageNamed:@"background_landscape-568h"]];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    self.viewWillAppearCompleted = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL tutorialShown = [defaults boolForKey:kTutorialKey];
    
    if (!tutorialShown)
    {
        TutorialViewController *viewController = [[TutorialViewController alloc] initWithNibName:@"TutorialView" bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        viewController.delegate = self;
        [defaults setBool:YES forKey:kTutorialKey];
        [self presentModalViewController:viewController animated:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.viewWillAppearCompleted = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self onTimerFire:0];
    addTimerArrowRotated = NO;
    
    int rowCount = [TimeeData instance].timerTableRows.count;
    
    if (rowCount != 0)
    {
        CGFloat height = MIN(rowCount - 1, maxFullRowsInView) * 63.0;
        [self.timerTableView.tableView setFrame:CGRectMake(0.0, [[UIScreen mainScreen] bounds].size.height - height, 320, height)];
        
        self.timerTableView.showTimerButton.hidden = NO;
        self.timerTableView.tableView.hidden = NO;
        self.timerTableView.addTimerArrow.hidden = NO;
        self.timerTableView.addTimerSmallLabel.hidden = NO;
        self.timerTableView.timeLabel.hidden = NO;
        self.timerTableView.titleLabel.hidden = NO;
        self.timerTableView.subtitleLabel.hidden = NO;
        
        if (rowCount > maxFullRowsInView)
        {
            self.timerTableView.tableView.scrollEnabled = YES;
            self.timerTableView.addTimerArrow.transform = CGAffineTransformMakeRotation(M_PI / 2);
            
            CGRect frame = self.timerTableView.addTimerArrow.frame;
            self.timerTableView.addTimerArrow.frame = CGRectMake(108, frame.origin.y, 20, frame.size.height);
            self.timerTableView.addTimerArrow.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        }
        else
        {
            [self transformArrowButton];
        }
        
        [self.timerTableView.displayButton setImage:nil forState:UIControlStateNormal];
        self.timerTableView.addTimerLabel.hidden = YES;
        self.timerTableView.swipeRecognizer.enabled = YES;
        
        TimerTableRow *row = [[TimeeData instance].timerTableRows objectAtIndex:0];
        
        NSArray *labelTexts = [self getLabelTexts:row];
        self.timerTableView.titleLabel.text = self.timerTableView_Landscape.titleLabel.text = [labelTexts objectAtIndex:0];
        self.timerTableView.subtitleLabel.text = self.timerTableView_Landscape.subtitleLabel.text = [labelTexts objectAtIndex:1];
        self.timerTableView.timeLabel.text = self.timerTableView_Landscape.timeLabel.text = [labelTexts objectAtIndex:2];
        
        int seconds = ((NSNumber *)[[TimerTableViewController getRunningTime:row ofType:row.timer.timerTableSummaryType] objectAtIndex:2]).intValue + [TimeeData instance].timerTable.isRunning.intValue;
        self.timerTableView.wheel.transform = self.timerTableView_Landscape.wheel.transform = CGAffineTransformMakeRotation(seconds * M_PI / 30);
    }
    else 
    {
        self.timerTableView.showTimerButton.hidden = YES;
        self.timerTableView.tableView.hidden = YES;
        self.timerTableView.timeLabel.hidden = YES;
        self.timerTableView.titleLabel.hidden = YES;
        self.timerTableView.subtitleLabel.hidden = YES;
        
        [self.timerTableView.displayButton setImage:[UIImage imageNamed:@"options_big"] forState:UIControlStateNormal];        
        self.timerTableView.addTimerArrow.hidden = YES;
        self.timerTableView.addTimerSmallLabel.hidden = YES;
        self.timerTableView.addTimerLabel.hidden = NO;
        self.timerTableView.swipeRecognizer.enabled = NO;
        self.timerTableView.wheel.transform = CGAffineTransformMakeRotation(0);
    }
    
    [self.timerTableView.tableView reloadData];
    
    if (self.timerTableView.tableView.visibleCells.count > 0)
    {
        [self.timerTableView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

- (void)transformArrowButton
{
    self.timerTableView.tableView.scrollEnabled = NO;
    self.timerTableView.addTimerArrow.transform = CGAffineTransformMakeRotation(0);
    self.timerTableView.addTimerArrow.frame = CGRectMake(112, self.timerTableView.addTimerArrow.frame.origin.y, 100, self.timerTableView.addTimerArrow.frame.size.height);
    self.timerTableView.addTimerArrow.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
}

@end
