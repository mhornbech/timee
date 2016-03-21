//
//  RegistrationTableViewController.m
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppColors.h"
#import "Registration.h"
#import "RegistrationCellView.h"
#import "RegistrationTableView.h"
#import "RegistrationTableViewController.h"
#import "RegistrationView.h"
#import "SearchCellView.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerInfo.h"
#import "TimerSection.h"
#import "TimerTableCellView.h"
#import "TimerTableViewController.h"
#import "TimerView.h"
#import "ViewControllerCache.h"

#define kTimerTableViewCellIdentifier               @"TimerTableViewCell"
#define kRegistrationCellIdentifier                 @"RegistrationCell"

#define kTimerViewNibName                           @"TimerView"
#define kRegistrationViewNibName                    @"RegistrationView"
#define kRegistrationTableMainCellNibName           @"RegistrationTableMainCell"
#define kRegistrationTableSubCellNibName            @"RegistrationTableSubCell"
#define kSearchCellNibName                          @"SearchCell"

#define kRegistrationEntityName                     @"Registration"

@implementation RegistrationTableViewController

@synthesize delegate = _delegate;
@synthesize sectionCaches = _sectionCaches;
@synthesize registrationTableSections = _registrationTableSections;
@synthesize cell = _cell;
@synthesize searchCell = _searchCell;
@synthesize registrationTableView = _registrationTableView;
@synthesize timeFormatter = _timeFormatter;
@synthesize dateFormatter = _dateFormatter;
@synthesize expandedIndexPaths = _expandedIndexPaths;
@synthesize secondsPerDay = _secondsPerDay;
@synthesize secondsFromGMT = _secondsFromGMT;
@synthesize searchActive = _searchActive;
@synthesize searchCancelled = _searchCancelled;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    self.secondsFromGMT = [NSTimeZone localTimeZone].secondsFromGMT;
    self.secondsPerDay = 24 * 3600;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;

    self.timeFormatter = [[NSDateFormatter alloc] init];
    self.timeFormatter.timeStyle = NSDateFormatterShortStyle;
    self.timeFormatter.dateStyle = NSDateFormatterNoStyle;
    
    self.registrationTableView.noResultsLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    self.registrationTableView.noResultsLabel.textColor = [AppColors black];
    
    [[NSBundle mainBundle] loadNibNamed:kSearchCellNibName owner:self options:nil];
    SearchCellView *cellView = (SearchCellView *)[self.searchCell.contentView.subviews objectAtIndex:0];
    
    cellView.searchTextField.textColor = [AppColors gold];
    cellView.searchTextField.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];
    
    self.registrationTableView.title.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    self.registrationTableView.tableView.backgroundColor = [AppColors gold];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.registrationTableView.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.registrationTableView.tableView.frame;
        self.registrationTableView.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + 88);
        
        frame = self.registrationTableView.activityIndicator.frame;
        self.registrationTableView.activityIndicator.frame = CGRectMake(frame.origin.x, frame.origin.y + 44, frame.size.width, frame.size.height);
    }

    [self prepareDataForView];
}

- (void)viewWillAppear:(BOOL)animated
{
    SearchCellView *cellView = (SearchCellView *)[self.searchCell.contentView.subviews objectAtIndex:0];
    
    if(cellView.searchTextField.text.length == 0)
        cellView.searchTextField.text = @"Search";

    cellView.searchCancelButton.hidden = [cellView.searchTextField.text isEqualToString:@"Search"];
    
    self.registrationTableView.noResultsLabel.hidden = YES;
    self.registrationTableView.doneButton.enabled = YES;
    self.registrationTableView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
}

- (void)prepareDataForView
{
    self.sectionCaches = [[NSMutableDictionary alloc] init];
    self.expandedIndexPaths = [[NSMutableArray alloc] init];
    
    SearchCellView *cellView = (SearchCellView *)[self.searchCell.contentView.subviews objectAtIndex:0];
    
    if (self.searchActive)
        self.registrationTableSections = [self getSearchResults:cellView.searchTextField.text];
    else
        self.registrationTableSections = [TimeeData instance].registrationTableSections;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate registrationTableViewControllerDidFinish:self];
}

- (IBAction)onShowTimerButtonTapped:(id)sender
{
    TimerViewController *viewController = (TimerViewController *)[[ViewControllerCache instance] getViewControllerForName:@"Timer"];
    BOOL cached = viewController != nil;
    
    if (viewController == nil)
    {
        viewController = [[TimerViewController alloc] initWithNibName:kTimerViewNibName bundle:[NSBundle mainBundle]];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[ViewControllerCache instance] addViewController:viewController forName:@"Timer"];
    }
    
    UIView *view = (UIView *)sender;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.registrationTableView.tableView indexPathForCell:cell];
    
    Timer *timer = ((id<RegistrationTableRowProtocol>)[[self getRegistrationTableRowWithIndexPathForIndexPath:indexPath] objectAtIndex:0]).timer;    
    viewController.timer = timer;
    viewController.delegate = self;
    
    RegistrationTableSection *section = (RegistrationTableSection *)[self.registrationTableSections objectAtIndex:indexPath.section - 1];
    viewController.dateScrollOffset = section.date;
    
    if (cached)
    {
        [viewController prepareDataForView];
        [viewController.timerView.tableView reloadData];
        [viewController.timerView.tableView setFrame:CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45)];
    }
    
    [self presentModalViewController:viewController animated:YES]; 
}

- (IBAction)searchBarSearchButtonClicked
{
    SearchCellView *cellView = (SearchCellView *)[self.searchCell.contentView.subviews objectAtIndex:0];
    [cellView.searchTextField resignFirstResponder];
    self.searchCancelled = NO;
    
    if (cellView.searchTextField.text.length == 0)
    {
        [self searchBarCancelButtonClicked];
        return;
    }
    
    self.registrationTableView.doneButton.enabled = NO;
    self.registrationTableView.tableView.frame = CGRectMake(0, 45, 320, 44);
    [self.registrationTableView.activityIndicator startAnimating];
    
    __block NSMutableArray *registrationTableSections = nil;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.sectionCaches = [[NSMutableDictionary alloc] init];
        registrationTableSections = [self getSearchResults:cellView.searchTextField.text];
        
        dispatch_async(dispatch_get_main_queue(), ^{
                        
            self.registrationTableView.doneButton.enabled = YES;
            self.registrationTableView.tableView.frame = CGRectMake(0, 45, 320, [[UIScreen mainScreen] bounds].size.height - 45);
            
            [self.registrationTableView.activityIndicator stopAnimating];
            
            if (!self.searchCancelled)
            {
                self.registrationTableSections = registrationTableSections;
                self.expandedIndexPaths = [[NSMutableArray alloc] init];
                [self.registrationTableView.tableView reloadData];
                self.registrationTableView.noResultsLabel.hidden = self.registrationTableSections.count != 0;
                
                self.searchActive = YES;
            }
            
            if (cellView.searchTextField.text.length == 0)
            {
                cellView.searchTextField.text = @"Search";
                cellView.searchCancelButton.hidden = YES;
            }
        });
    });
}

- (IBAction)searchBarCancelButtonClicked
{
    SearchCellView *cellView = (SearchCellView *)[self.searchCell.contentView.subviews objectAtIndex:0];
    cellView.searchTextField.text = @"Search";
    cellView.searchCancelButton.hidden = YES;
    [cellView.searchTextField resignFirstResponder];
    self.searchCancelled = YES;
    self.registrationTableView.noResultsLabel.hidden = YES;
    
    if (self.searchActive)
    {
        self.searchActive = NO;
        self.sectionCaches = [[NSMutableDictionary alloc] init];
        self.registrationTableSections = [TimeeData instance].registrationTableSections;        
        self.expandedIndexPaths = [[NSMutableArray alloc] init];
        [self.registrationTableView.tableView reloadData];
    }
}

#pragma mark - Instance Methods

- (NSDictionary *)getCacheForSection:(id<RegistrationTableSectionProtocol>)section
{
    NSDictionary *cache = [self.sectionCaches objectForKey:section.date];
    
    if (cache == nil)
    {
        NSMutableDictionary *totalsByObjectId = [NSMutableDictionary dictionaryWithCapacity:section.rows.count];
        NSMutableDictionary *sortedRegistrationsByObjectId = [NSMutableDictionary dictionaryWithCapacity:section.rows.count];
        
        for (id<RegistrationTableRowProtocol> row in section.rows)
        {
            double total = 0;
            
            for (Registration *reg in row.registrations)
                total += [(reg.endTime == nil ? [NSDate date] : reg.endTime) timeIntervalSinceDate:reg.startTime];
            
            [totalsByObjectId setObject:[NSNumber numberWithDouble:total] forKey:row.objectID];

            NSArray *sortedRegistrations = [row.registrations.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [((Registration *)obj2).startTime compare:((Registration *)obj1).startTime];
            }];   
                                            
            [sortedRegistrationsByObjectId setObject:sortedRegistrations forKey:row.objectID];
        }
        
        NSArray *rows = [section.rows.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSNumber *number1 = [totalsByObjectId objectForKey:((id<RegistrationTableRowProtocol>)obj1).objectID];
            NSNumber *number2 = [totalsByObjectId objectForKey:((id<RegistrationTableRowProtocol>)obj2).objectID];
            return [number2 compare:number1];
        }];
        
        NSMutableArray *expandedTimers = [[NSMutableArray alloc] init];
        
        cache = [NSDictionary dictionaryWithObjectsAndKeys:rows, @"rows", 
                 totalsByObjectId, @"totals",
                 sortedRegistrationsByObjectId, @"sortedRegistrations",
                 expandedTimers, @"expanded", nil];
        
        [self.sectionCaches setObject:cache forKey:section.date];
    }
    
    return cache;
}

- (NSArray *)getRegistrationTableRowWithIndexPathForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *cache = [self getCacheForSection:[self.registrationTableSections objectAtIndex:indexPath.section - 1]];
    NSArray *rows = [cache objectForKey:@"rows"];
    NSArray *expandedRows = [cache objectForKey:@"expanded"];
    
    NSUInteger rowIndex = 0;
    id<RegistrationTableRowProtocol>row = nil;
    
    for (int i = 0; i < rows.count; i++)
    {
        row = [rows objectAtIndex:i];
        NSUInteger increment = 1 + ([expandedRows containsObject:row.objectID] ? row.registrations.count : 0); 
        
        if (rowIndex + increment > indexPath.row)
            break;
        
        rowIndex += increment;
    }
    
    return [NSArray arrayWithObjects:row, [NSNumber numberWithInteger:rowIndex], nil];
}

- (NSMutableArray *)getSearchResults:(NSString *)searchString
{
    if ([searchString isEqualToString:@""])
        return [TimeeData instance].registrationTableSections;
    
    NSArray *searchTerms = [searchString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    for (RegistrationTableSection *section in [TimeeData instance].registrationTableSections)
    {
        if (self.searchCancelled)
            return nil;
        
        BOOL includeSection = NO;
        NSMutableSet *resultRows = nil;
        
        for (RegistrationTableRow *row in section.rows)
        {
            BOOL includeRow = NO;
            NSSet *resultRegistrations = nil;
            NSMutableArray *searchTermsCopy = [NSMutableArray arrayWithArray:searchTerms];
            
            for (NSString *term in searchTerms)
            {
                for (TimerInfo *info in row.timer.info)
                {
                    if ([info.title rangeOfString:term options:NSCaseInsensitiveSearch].length > 0)
                    {
                        [searchTermsCopy removeObject:term];
                        break;
                    }
                }
            }            

            includeRow = searchTermsCopy.count == 0;
            
            if (!includeRow)
            {
                for (Registration *registration in row.registrations)
                {
                    NSMutableArray *remainingTermsCopy = [NSMutableArray arrayWithArray:searchTermsCopy];
                    
                    for (NSString *term in searchTermsCopy)
                    {       
                        if ([registration.note rangeOfString:term options:NSCaseInsensitiveSearch].length > 0)
                            [remainingTermsCopy removeObject:term];                                                        
                    }
                    
                    if (remainingTermsCopy.count == 0)
                    {
                        if (resultRegistrations == nil)
                            resultRegistrations = [[NSMutableSet alloc] init];

                        [((NSMutableSet *)resultRegistrations) addObject:registration];                         
                        includeRow = YES;                    
                    }
                }
            }
            else
                resultRegistrations = row.registrations;
            
            if (includeRow)
            {
                RegistrationTableRowContainer *resultRow = [[RegistrationTableRowContainer alloc] init];
                resultRow.timer = row.timer;
                resultRow.objectID = row.objectID;
                resultRow.registrations = resultRegistrations;
                
                if (resultRows == nil)
                    resultRows = [[NSMutableSet alloc] init];
                
                [resultRows addObject:resultRow];                 
                includeSection = YES;
            }
        }
        
        if (includeSection)
        {
            RegistrationTableSectionContainer *resultSection = [[RegistrationTableSectionContainer alloc] init];
            resultSection.date = section.date;
            resultSection.rows = resultRows;            
            [results addObject:resultSection];
        }                    
    }
    
    return results;
}

- (void)addExpandedIndexPaths:(NSArray *)indexPaths following:(NSIndexPath *)indexPath
{
    NSInteger insertionIndex = -1;
    for (int i = 0; i < self.expandedIndexPaths.count; i++)
    {
        NSIndexPath *current = [self.expandedIndexPaths objectAtIndex:i];
        
        if (current.section > indexPath.section)
        {
            insertionIndex = i;
            break;
        }
        
        if (current.section == indexPath.section)
        {
            if (current.row > indexPath.row)
            {
                insertionIndex = i;
                break;
            }
        }
    }
    
    if (insertionIndex != -1)
    {
        for (int i = insertionIndex; i < self.expandedIndexPaths.count; i++) 
        {
            NSIndexPath *current = [self.expandedIndexPaths objectAtIndex:i];
            
            if (current.section > indexPath.section)
                break;
            
            NSIndexPath *new = [NSIndexPath indexPathForRow:current.row + indexPaths.count inSection:current.section];
            [self.expandedIndexPaths replaceObjectAtIndex:i withObject:new];
        }
        
        [self.expandedIndexPaths insertObjects:indexPaths atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertionIndex, indexPaths.count)]]; 
    }
    else
        [self.expandedIndexPaths addObjectsFromArray:indexPaths];
}

- (void)removeExpandedIndexPaths:(NSArray *)indexPaths following:(NSIndexPath *)indexPath
{
    NSInteger removalIndex = -1;
    for (int i = 0; i < self.expandedIndexPaths.count; i++)
    {
        NSIndexPath *current = [self.expandedIndexPaths objectAtIndex:i];
        
        if (current.section > indexPath.section)
        {
            removalIndex = i;
            break;
        }
        
        if (current.section == indexPath.section)
        {
            if (current.row > indexPath.row)
            {
                removalIndex = i;
                break;
            }
        }
    }
    
    if (removalIndex != -1)
    {
        [self.expandedIndexPaths removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(removalIndex, indexPaths.count)]]; 
        
        for (int i = removalIndex; i < self.expandedIndexPaths.count; i++) 
        {
            NSIndexPath *current = [self.expandedIndexPaths objectAtIndex:i];
            
            if (current.section > indexPath.section)
                break;
            
            NSIndexPath *new = [NSIndexPath indexPathForRow:current.row - indexPaths.count inSection:current.section];
            [self.expandedIndexPaths replaceObjectAtIndex:i withObject:new];
        }
    }
    else
        [self.expandedIndexPaths addObjectsFromArray:indexPaths];   
}

#pragma mark - Timer View Delegate

- (void)timerViewControllerDidFinish:(TimerViewController *)controller
{
    [self prepareDataForView];
    [self.registrationTableView.tableView reloadData];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 & indexPath.section == 0)
        return 44;
    
    if ([self.expandedIndexPaths containsObject:indexPath])
    {
        NSIndexPath *below = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        
        if ([self.expandedIndexPaths containsObject:below])
            return 23;
        else
            return 33;
    }
    else
        return 63;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        [((SearchCellView *)[self.searchCell.contentView.subviews objectAtIndex:0]).searchTextField becomeFirstResponder];
        return;
    }
    
    NSDictionary *cache = [self getCacheForSection:[self.registrationTableSections objectAtIndex:indexPath.section - 1]];
    NSArray *rowAndIndex = [self getRegistrationTableRowWithIndexPathForIndexPath:indexPath];
    id<RegistrationTableRowProtocol> row = [rowAndIndex objectAtIndex:0];
    NSUInteger index = ((NSNumber *)[rowAndIndex objectAtIndex:1]).integerValue;
        
    if (indexPath.row == index)
    {            
        NSMutableArray *expandedRows = [cache objectForKey:@"expanded"];            
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:row.registrations.count];
        
        for (int i = 0; i < row.registrations.count; i++)
            [indexPaths addObject:[NSIndexPath indexPathForRow:indexPath.row + i + 1 inSection:indexPath.section]];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        TimerTableCellView *cellView = ((TimerTableCellView *)[cell.contentView.subviews objectAtIndex:0]);
        
        if ([expandedRows containsObject:row.objectID])
        {
            [expandedRows removeObject:row.objectID];
            cell.backgroundView = cellView.background;
            cellView.selectionMarker.hidden = YES;
            [self removeExpandedIndexPaths:indexPaths following:indexPath];            
            [self.registrationTableView.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];            
        }
        else 
        {
            [expandedRows addObject:row.objectID];
            cell.backgroundView = cellView.selectedBackground;
            cellView.selectionMarker.hidden = NO;
            [self addExpandedIndexPaths:indexPaths following:indexPath];            
            [self.registrationTableView.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        }
    }
}

#pragma mark - Table View Data Soruce

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 && indexPath.section == 0)
        return self.searchCell;
    
    NSDictionary *cache = [self getCacheForSection:[self.registrationTableSections objectAtIndex:indexPath.section - 1]];
    NSArray *rowAndIndex = [self getRegistrationTableRowWithIndexPathForIndexPath:indexPath];
    id<RegistrationTableRowProtocol> row = [rowAndIndex objectAtIndex:0];
    NSUInteger index = ((NSNumber *)[rowAndIndex objectAtIndex:1]).integerValue;
    
    UITableViewCell *cell = nil;
    TimerTableCellView *cellView = nil;
    
    if (indexPath.row == index)
    {        
        cell = [tableView dequeueReusableCellWithIdentifier:kTimerTableViewCellIdentifier];
        
        if (cell == nil) 
        {
            [[NSBundle mainBundle] loadNibNamed:kRegistrationTableMainCellNibName owner:self options:nil];
            cell = self.cell;
            
            cellView = [cell.contentView.subviews objectAtIndex:0];
            cellView.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:16.0];
            cellView.subtitleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:15.0];
            cellView.timeLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18.0];
            cellView.titleLabel.textColor = cellView.subtitleLabel.textColor = cellView.timeLabel.textColor = [AppColors black];
        }
        else
            cellView = [cell.contentView.subviews objectAtIndex:0];
        
        NSArray *labelTexts = [TimerTableViewController getTitleLabelTexts:row.timer.info.allObjects];
        cellView.titleLabel.text = [labelTexts objectAtIndex:0];
        cellView.subtitleLabel.text = [labelTexts objectAtIndex:1];
        
        NSDictionary *totalsByObjectId = [cache objectForKey:@"totals"];
        int totalSeconds = ((NSNumber *)[totalsByObjectId objectForKey:row.objectID]).intValue;
        int hours = totalSeconds / 3600;
        int minutes = (totalSeconds - hours * 3600) / 60;
        
        cellView.timeLabel.text = [NSString stringWithFormat:@"%d:%@%d", hours, minutes < 10 ? @"0" : @"", minutes];
        
        NSMutableArray *expandedRows = [cache objectForKey:@"expanded"];            
        
        TimerTableCellView *cellView = ((TimerTableCellView *)[cell.contentView.subviews objectAtIndex:0]);
        
        if ([expandedRows containsObject:row.objectID])
        {
            cell.backgroundView = cellView.selectedBackground;
            cellView.selectionMarker.hidden = NO;
        }   
        else 
        {
            cell.backgroundView = cellView.background;
            cellView.selectionMarker.hidden = YES;
        }
    }
    else
    {        
        NSUInteger registrationIndex = indexPath.row - index - 1;
        NSArray *sortedRegistrations = [(NSDictionary *)[cache objectForKey:@"sortedRegistrations"] objectForKey:row.objectID];
        Registration *registration = [sortedRegistrations objectAtIndex:registrationIndex];        

        NSString *startTime = [self.timeFormatter stringFromDate:registration.startTime];
        NSString *endTime = registration.endTime != nil ? [self.timeFormatter stringFromDate:registration.endTime] : @"";

        NSInteger cellHeight = registrationIndex == sortedRegistrations.count - 1 ? 33 : 23;
        
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, cellHeight)];
        
        UIImage *backgroundImage = cellHeight == 23 ? [UIImage imageNamed:@"cell_1"] : [UIImage imageNamed:@"cell_2"];
        cell.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
        
        UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 170, 17)];
        leftLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:15];
        leftLabel.textColor = [AppColors black];
        leftLabel.backgroundColor = [UIColor clearColor];
        leftLabel.shadowColor = [UIColor whiteColor];
        leftLabel.shadowOffset = CGSizeMake(0, 1);
        
        UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(171, 0, 100, 17)];
        rightLabel.font = leftLabel.font;
        rightLabel.textColor = leftLabel.textColor;
        rightLabel.backgroundColor = leftLabel.backgroundColor;
        rightLabel.shadowColor = leftLabel.shadowColor;
        rightLabel.shadowOffset = leftLabel.shadowOffset;
        rightLabel.textAlignment = UITextAlignmentRight;

        UIImageView *note = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"note"]];
        note.frame = CGRectMake(190, 0, 23, 17);
        note.contentMode = UIViewContentModeRight;
         
        [cell addSubview:leftLabel];
        [cell addSubview:rightLabel];
        [cell addSubview:note];
        
        leftLabel.text = [NSString stringWithFormat:@"%@ – %@", startTime, endTime];
        
        int total = [(registration.endTime != nil ? registration.endTime : [NSDate date]) timeIntervalSinceDate:registration.startTime];
        int hours = total / 3600;
        int minutes = (total - hours * 3600) / 60;
        
        rightLabel.text = [NSString stringWithFormat:@"%d:%@%d", hours, minutes < 10 ? @"0" : @"", minutes]; 
        note.hidden = registration.note == nil;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;
    
    RegistrationTableSection *registrationTableSection = [self.registrationTableSections objectAtIndex:section - 1];
    NSInteger numberOfRows = registrationTableSection.rows.count;
    
    for (NSIndexPath *indexPath in self.expandedIndexPaths)
    {
        if (indexPath.section == section)
            numberOfRows++;
    }
    
    return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.registrationTableSections.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 0;
    
    return 34.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return nil;
    
    id<RegistrationTableSectionProtocol> tableSection = [self.registrationTableSections objectAtIndex:section - 1];
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 34.0)];
    view.backgroundColor = [AppColors darkGold];
    
    UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 0.0, 200.0, 34.0)];
    leftLabel.backgroundColor = [UIColor clearColor];
    leftLabel.textColor = [AppColors grey];
    leftLabel.font = [UIFont fontWithName:@"SourceSansPro-It" size:15];
    leftLabel.text = [[self.dateFormatter stringFromDate:tableSection.date] uppercaseString];
    
    [view addSubview:leftLabel];
    
    UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(191.0, 0.0, 80.0, 34.0)]; 
    rightLabel.backgroundColor = leftLabel.backgroundColor;
    rightLabel.textColor = leftLabel.textColor;
    rightLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:16];
    
    __block double total = 0;        
    [tableSection.rows enumerateObjectsUsingBlock:^(id obj1, BOOL *stop) {
        id<RegistrationTableRowProtocol> row = obj1; 
        
        [row.registrations enumerateObjectsUsingBlock:^(id obj2, BOOL *stop) {
            Registration *reg = obj2;
            total += [(reg.endTime == nil ? [NSDate date] : reg.endTime) timeIntervalSinceDate:reg.startTime];
        }];
    }];
    
    int hours = total / 3600;
    int minutes = (total - hours * 3600) / 60;
    
    rightLabel.text = [NSString stringWithFormat:@"%d:%@%d", hours, minutes < 10 ? @"0" : @"", minutes]; 
    rightLabel.textAlignment = UITextAlignmentRight;
    
    [view addSubview:rightLabel];        
    
    return view;
}

#pragma mark - Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIView *view = textField;
    while (![view isKindOfClass:[SearchCellView class]]) {
        view = [view superview];
    }
    
    SearchCellView *cell = (SearchCellView *)view;    
    cell.searchCancelButton.hidden = NO;
    
    if ([textField.text isEqualToString:@"Search"])
        textField.text = @"";
}

@end

#pragma mark -

@implementation RegistrationTableSectionContainer

@synthesize date = _date;
@synthesize rows = _rows;

@end

@implementation RegistrationTableRowContainer

@synthesize timer = _timer;
@synthesize registrations = _registrations;
@synthesize objectID = _objectID;

@end
