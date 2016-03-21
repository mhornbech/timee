//
//  RedmineInfo.h
//  Timee
//
//  Created by Morten Hornbech on 08/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Timer;

@interface RedmineInfo : NSManagedObject

@property (nonatomic, retain) NSString *issueId;
@property (nonatomic, retain) NSString *issueSubject;
@property (nonatomic, retain) NSString *activityId;
@property (nonatomic, retain) NSString *activityName;
@property (nonatomic, retain) Timer *timer;

@end
