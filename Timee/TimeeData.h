//
//  TimeeData.h
//  Timee
//
//  Created by Morten Hornbech on 09/01/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Timer;
@class Registration;
@class TimerTable;
@class TimerTableRow;

@interface TimeeData : NSObject

@property (nonatomic, strong) TimerTable *timerTable;
@property (nonatomic, strong) NSMutableArray *timerTableRows;
@property (nonatomic, strong) NSMutableArray *registrationTableSections;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

+ (void)clear;
+ (TimeeData *)instance;
+ (NSManagedObjectContext *)context;

- (void)setContext:(NSManagedObjectContext *)context;
- (void)addTimer:(Timer *)timer;
- (void)addRegistration:(Registration *)registration toTimer:(Timer *)timer;

- (void)updateRegistration:(Registration *)registration startTime:(NSDate *)newStartTime endTime:(NSDate *)newEndTime;
- (void)updateTimerSectionInTimer:(Timer *)timer withRegistration:(Registration *)registration;
- (void)updateRegistrationTableSectionsWithRegistration:(Registration *)registration;

- (void)deleteRegistration:(Registration *)registration;
- (void)deleteTimerTableRow:(TimerTableRow *)timerTableRow;

- (NSMutableArray *)fetchTimerTableRows;
- (NSMutableArray *)fetchRegistrationTableSections;
- (void)onContextSave:(NSNotification *)notification;

+ (void)commit;
+ (void)rollback;

@end
