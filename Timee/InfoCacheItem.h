//
//  InfoCacheItem.h
//  Timee
//
//  Created by Morten Hornbech on 11/05/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface InfoCacheItem : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * lastUse;

@end
