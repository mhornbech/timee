//
//  TimerTable.h
//  Timee
//
//  Created by Morten Hornbech on 09/01/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TimerTableRow;

@interface TimerTable : NSManagedObject

@property (nonatomic, retain) NSNumber * isRunning;

@end