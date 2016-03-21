//
//  TimeeData.m
//  Timee
//
//  Created by Morten Hornbech on 09/01/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppDelegate.h"
#import "Registration.h"
#import "RegistrationTableRow.h"
#import "RegistrationTableSection.h"
#import "Timer.h"
#import "TimerSection.h"
#import "TimerTable.h"
#import "TimerTableRow.h"
#import "TimeeData.h"

#define kTimerTableEntityName                   @"TimerTable"
#define kTimerTableRowEntityName                @"TimerTableRow"
#define kTimerSectionEntityName                 @"TimerSection"
#define kRegistrationTableSectionEntityName     @"RegistrationTableSection"
#define kRegistrationTableRowEntityName         @"RegistrationTableRow"

@implementation TimeeData

@synthesize timerTable = _timerTable;
@synthesize dateFormatter = _dateFormatter;

NSManagedObjectContext *_context;
NSMutableArray *_timerTableRows;
NSMutableArray *_registrationTableSections;

static TimeeData *_instance;

#pragma mark - Constructor

- (id)init
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kTimerTableEntityName];    
    NSError *error;    
    NSManagedObjectContext *context = [TimeeData context];
    NSArray *fetchResponse = [context executeFetchRequest:fetchRequest error:&error];
    
    self.timerTable = fetchResponse.count > 0 ? [fetchResponse objectAtIndex:0] : [NSEntityDescription insertNewObjectForEntityForName:kTimerTableEntityName inManagedObjectContext:context];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    self.dateFormatter.dateStyle = NSDateFormatterFullStyle;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContextSave:) 
                                                 name:NSManagedObjectContextDidSaveNotification object:nil];
    
    return self;
}

#pragma mark - Properties

- (NSArray *)timerTableRows
{
    if(_timerTableRows == nil)
        _timerTableRows = [self fetchTimerTableRows];
    
    return _timerTableRows;
}

- (NSMutableArray *)fetchTimerTableRows
{
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kTimerTableRowEntityName];        
    NSMutableArray *timerTableRows = [NSMutableArray arrayWithArray:[[[TimeeData context] executeFetchRequest:fetchRequest error:&error] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        NSDate *date1 = ((TimerTableRow *)obj1).lastUseTime;
        NSDate *date2 = ((TimerTableRow *)obj2).lastUseTime;
        
        if (date1 == nil)
            return NSOrderedAscending;
        
        if (date2 == nil)
            return NSOrderedDescending;
        
        return [date2 compare:date1];
    }]];
    
    return timerTableRows;
}

- (void)setTimerTableRows:(NSMutableArray *)value
{
    _timerTableRows = value;
}

- (NSArray *)registrationTableSections
{
    if(_registrationTableSections == nil)
        _registrationTableSections = [self fetchRegistrationTableSections];
    
    return _registrationTableSections;
}

- (NSMutableArray *)fetchRegistrationTableSections
{
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kRegistrationTableSectionEntityName];        
    NSMutableArray *registrationTableSections = [NSMutableArray arrayWithArray:[[[TimeeData context] executeFetchRequest:fetchRequest error:&error] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((RegistrationTableSection *)obj2).date compare:((RegistrationTableSection *)obj1).date];
    }]];
    
    return registrationTableSections;
}

- (void)setRegistrationTableSections:(NSMutableArray *)value
{
    _registrationTableSections = value;
}

- (void)setContext:(NSManagedObjectContext *)context;
{
    _context = context;
}

#pragma mark - Static methods

+ (void)clear
{
    _instance = nil;
}

+ (TimeeData *)instance;
{
    if(_instance == nil)
        _instance = [[TimeeData alloc] init];
    
    return _instance;
}

+ (NSManagedObjectContext *)context;
{
    if(_context == nil)
        _context = [(AppDelegate *)[UIApplication sharedApplication].delegate managedObjectContext];
    
    return _context;
}

+ (void)commit
{
    [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext]; 
}

+ (void)rollback
{
    [[(AppDelegate *)[UIApplication sharedApplication].delegate managedObjectContext] rollback]; 
}

#pragma mark - Instance methods

- (void)onContextSave:(NSNotification *)notification
{
    [[(AppDelegate *)[UIApplication sharedApplication].delegate managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
}

- (void)addTimer:(Timer *)timer
{
    NSMutableArray *timerTableRows = self.timerTableRows;
    
    TimerTableRow *row = [NSEntityDescription insertNewObjectForEntityForName:kTimerTableRowEntityName 
                                                       inManagedObjectContext:[TimeeData context]];
    row.timer = timer;
    row.lastUseTime = timer.creationTime;
    
    NSUInteger index = [self.timerTable.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]] ? 1 : 0;
    [timerTableRows insertObject:row atIndex:index];
}

- (void)addRegistration:(Registration *)registration toTimer:(Timer *)timer
{
    if (registration.endTime == nil || [timer.lastResetTime compare:registration.endTime] == NSOrderedAscending)
        [timer.timerTableRow addRegistrationsObject:registration];
    
    [self updateTimerSectionInTimer:timer withRegistration:registration];
    [self updateRegistrationTableSectionsWithRegistration:registration];
}

- (void)updateRegistration:(Registration *)registration startTime:(NSDate *)newStartTime endTime:(NSDate *)newEndTime
{            
    Timer *timer = registration.timerSection.timer;
    
    if (![[self.dateFormatter stringFromDate:newStartTime] isEqualToString:[self.dateFormatter stringFromDate:registration.startTime]])
    {
        if (registration.timerSection.registrations.count == 1)
        {
            [registration.timerSection.timer removeSectionsObject:registration.timerSection];
            [[TimeeData context] deleteObject:registration.timerSection];
        }
        else 
            [registration.timerSection removeRegistrationsObject:registration];
        
        if (registration.registrationTableRow.registrations.count == 1)
        {
            if (registration.registrationTableRow.section.rows.count == 1)
            {
                [self.registrationTableSections removeObject:registration.registrationTableRow.section];
                [[TimeeData context] deleteObject:registration.registrationTableRow.section];
            }
            else 
            {
                [registration.registrationTableRow.section removeRowsObject:registration.registrationTableRow];
                [[TimeeData context] deleteObject:registration.registrationTableRow];
            }
        }
        else
            [registration.registrationTableRow removeRegistrationsObject:registration]; 
        
        registration.startTime = newStartTime;
        registration.endTime = newEndTime;
        
        [self updateTimerSectionInTimer:timer withRegistration:registration];
        [self updateRegistrationTableSectionsWithRegistration:registration];
    }
    else
    {
        registration.startTime = newStartTime;
        registration.endTime = newEndTime;
    }
    
    if (registration.timerTableRow == nil && [registration.timerSection.timer.lastResetTime compare:newEndTime] == NSOrderedAscending)
        [registration.timerSection.timer.timerTableRow addRegistrationsObject:registration];
    else if (registration.timerTableRow != nil && newEndTime != nil && [registration.timerSection.timer.lastResetTime compare:newEndTime] == NSOrderedDescending)
        [registration.timerTableRow removeRegistrationsObject:registration];
}

- (void)updateTimerSectionInTimer:(Timer *)timer withRegistration:(Registration *)registration
{
    int secondsSinceReference = registration.startTime.timeIntervalSinceReferenceDate + [NSTimeZone localTimeZone].secondsFromGMT;
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:secondsSinceReference - secondsSinceReference % (24 * 3600)];
    TimerSection *timerSection = nil;
    
    for (TimerSection *section in timer.sections)
    {
        if ([section.date isEqualToDate:date])
        {
            timerSection = section;
            break;
        }
    }
    
    if (timerSection == nil)
    {
        timerSection = [NSEntityDescription insertNewObjectForEntityForName:kTimerSectionEntityName inManagedObjectContext:[TimeeData context]];
        timerSection.date = date;
        [timer addSectionsObject:timerSection];
    }
    
    [timerSection addRegistrationsObject:registration];
}

- (void)updateRegistrationTableSectionsWithRegistration:(Registration *)registration
{
    int secondsSinceReference = registration.startTime.timeIntervalSinceReferenceDate + [NSTimeZone localTimeZone].secondsFromGMT;
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:secondsSinceReference - secondsSinceReference % (24 * 3600)];
    NSUInteger registrationTableSectionIndex = 0;
    NSComparisonResult comparison = NSOrderedAscending;
    
    RegistrationTableSection *registrationTableSection = nil;
        
    while (registrationTableSectionIndex < self.registrationTableSections.count) 
    {
        RegistrationTableSection *section = [self.registrationTableSections objectAtIndex:registrationTableSectionIndex];
        comparison = [date compare:section.date];
        
        if (comparison == NSOrderedDescending)
            break;
        
        if (comparison == NSOrderedSame)
        {
            registrationTableSection = section;
            break;
        }
        
        registrationTableSectionIndex++;
    }        
    
    if (comparison != NSOrderedSame)
    {
        registrationTableSection = [NSEntityDescription insertNewObjectForEntityForName:kRegistrationTableSectionEntityName inManagedObjectContext:[TimeeData context]];
        registrationTableSection.date = date;
        [self.registrationTableSections insertObject:registrationTableSection atIndex:registrationTableSectionIndex];        
    }
    
    RegistrationTableRow *registrationTableRow = nil;
    
    for (RegistrationTableRow *row in registrationTableSection.rows)
    {
        if (row.timer.objectID == registration.timerSection.timer.objectID)
        {
            registrationTableRow = row;
            break;
        }
    }
    
    if (registrationTableRow == nil)
    {
        registrationTableRow = [NSEntityDescription insertNewObjectForEntityForName:kRegistrationTableRowEntityName inManagedObjectContext:[TimeeData context]];
        registrationTableRow.timer = registration.timerSection.timer;
        [registrationTableSection addRowsObject:registrationTableRow];
    }
    
    [registrationTableRow addRegistrationsObject:registration];
}

- (void)deleteTimerTableRow:(TimerTableRow *)timerTableRow
{
    for (RegistrationTableRow *row in timerTableRow.timer.registrationTableRows)
    {
        if (row.section.rows.count == 1)
        {
            [self.registrationTableSections removeObject:row.section];
            [[TimeeData context] deleteObject:row.section];
        }            
    }
    
    [[TimeeData context] deleteObject:timerTableRow];
}

- (void)deleteRegistration:(Registration *)registration
{
    if (registration.timerSection.registrations.count == 1)
    {
        [registration.timerSection.timer removeSectionsObject:registration.timerSection];        
        [[TimeeData context] deleteObject:registration.timerSection];
    }
    else
    {
        [registration.timerSection removeRegistrationsObject:registration];
        [[TimeeData context] deleteObject:registration];
    }
    
    if (registration.registrationTableRow.registrations.count == 1)
    {
        if (registration.registrationTableRow.section.rows.count == 1)
        {
            [self.registrationTableSections removeObject:registration.registrationTableRow.section];
            [[TimeeData context] deleteObject:registration.registrationTableRow.section];
        }
        else
        {
            [registration.registrationTableRow.section removeRowsObject:registration.registrationTableRow];
            [[TimeeData context] deleteObject:registration.registrationTableRow];
        }
    }
    else
        [registration.registrationTableRow removeRegistrationsObject:registration];
}

@end
