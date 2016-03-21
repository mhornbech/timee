//
//  RegistrationTableSection.h
//  Timee
//
//  Created by Morten Hornbech on 09/01/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol RegistrationTableSectionProtocol

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSSet *rows;

@end

@interface RegistrationTableSection : NSManagedObject<RegistrationTableSectionProtocol>

@end

@interface RegistrationTableSection (CoreDataGeneratedAccessors)

- (void)addRowsObject:(NSManagedObject *)value;
- (void)removeRowsObject:(NSManagedObject *)value;
- (void)addRows:(NSSet *)values;
- (void)removeRows:(NSSet *)values;

@end