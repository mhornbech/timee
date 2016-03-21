//
//  TimerInfo.h
//  Timee
//
//  Created by Morten Hornbech on 09/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TimerInfo : NSManagedObject

@property (nonatomic, retain) NSNumber *index;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSManagedObject *timer;

@end
