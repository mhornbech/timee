//
//  TimerTableRow.h
//  Timee
//
//  Created by Morten Hornbech on 09/01/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Registration, Timer, TimerTable;

@interface TimerTableRow : NSManagedObject

@property (nonatomic, retain) NSDate * lastUseTime;
@property (nonatomic, retain) Timer *timer;
@property (nonatomic, retain) NSSet *registrations;
@end

@interface TimerTableRow (CoreDataGeneratedAccessors)

- (void)addRegistrationsObject:(Registration *)value;
- (void)removeRegistrationsObject:(Registration *)value;
- (void)addRegistrations:(NSSet *)values;
- (void)removeRegistrations:(NSSet *)values;
@end
