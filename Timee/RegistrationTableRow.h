//
//  RegistrationTableRow.h
//  Timee
//
//  Created by Morten Hornbech on 09/01/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Registration, RegistrationTableSection, Timer;

@protocol RegistrationTableRowProtocol

@property (nonatomic, retain) Timer *timer;
@property (nonatomic, retain) NSSet *registrations;
@property (nonatomic, retain) NSManagedObjectID *objectID;

@end

@interface RegistrationTableRow : NSManagedObject<RegistrationTableRowProtocol>

@property (nonatomic, retain) RegistrationTableSection *section;

@end

@interface RegistrationTableRow (CoreDataGeneratedAccessors)

- (void)addRegistrationsObject:(Registration *)value;
- (void)removeRegistrationsObject:(Registration *)value;
- (void)addRegistrations:(NSSet *)values;
- (void)removeRegistrations:(NSSet *)values;

@end
