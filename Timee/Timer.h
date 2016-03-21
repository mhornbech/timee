//
//  Timer.h
//  Timee
//
//  Created by Morten Hornbech on 16/01/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Registration, RegistrationTableRow, TimerInfo, TimerSection, TimerTableRow, RedmineInfo, JiraInfo;

@interface Timer : NSManagedObject

@property (nonatomic, retain) NSDate * creationTime;
@property (nonatomic, retain) NSDate * lastResetTime;
@property (nonatomic, retain) NSString * timerTableSummaryType;
@property (nonatomic, retain) NSSet *info;
@property (nonatomic, retain) NSSet *registrationTableRows;
@property (nonatomic, retain) NSSet *sections;
@property (nonatomic, retain) TimerTableRow *timerTableRow;
@property (nonatomic, retain) RedmineInfo *redmine;
@property (nonatomic, retain) JiraInfo *jira;

@end

@interface Timer (CoreDataGeneratedAccessors)

- (void)addInfoObject:(TimerInfo *)value;
- (void)removeInfoObject:(TimerInfo *)value;
- (void)addInfo:(NSSet *)values;
- (void)removeInfo:(NSSet *)values;
- (void)addRegistrations:(NSSet *)values;
- (void)removeRegistrations:(NSSet *)values;
- (void)addRegistrationTableRowsObject:(RegistrationTableRow *)value;
- (void)removeRegistrationTableRowsObject:(RegistrationTableRow *)value;
- (void)addRegistrationTableRows:(NSSet *)values;
- (void)removeRegistrationTableRows:(NSSet *)values;
- (void)addSectionsObject:(TimerSection *)value;
- (void)removeSectionsObject:(TimerSection *)value;
- (void)addSections:(NSSet *)values;
- (void)removeSections:(NSSet *)values;
@end
