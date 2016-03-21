//
//  TimerSection.h
//  Timee
//
//  Created by Morten Hornbech on 09/01/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Registration, Timer;

@interface TimerSection : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSSet *registrations;
@property (nonatomic, retain) Timer *timer;
@end

@interface TimerSection (CoreDataGeneratedAccessors)

- (void)addRegistrationsObject:(Registration *)value;
- (void)removeRegistrationsObject:(Registration *)value;
- (void)addRegistrations:(NSSet *)values;
- (void)removeRegistrations:(NSSet *)values;
@end
