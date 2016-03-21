//
//  Registration.h
//  Timee
//
//  Created by Morten Hornbech on 16/01/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RegistrationTableRow, Timer, TimerSection, TimerTableRow;

@interface Registration : NSManagedObject

@property (nonatomic, retain) NSDate *endTime;
@property (nonatomic, retain) NSDate *startTime;
@property (nonatomic, retain) NSString *note;
@property (nonatomic, retain) RegistrationTableRow *registrationTableRow;
@property (nonatomic, retain) TimerSection *timerSection;
@property (nonatomic, retain) TimerTableRow *timerTableRow;

@end
