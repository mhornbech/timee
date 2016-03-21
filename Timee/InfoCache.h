//
//  InfoCache.h
//  Timee
//
//  Created by Morten Hornbech on 11/05/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfoCache : NSObject

@property (nonatomic, strong) NSMutableArray *itemsByTitle;
@property (nonatomic, strong) NSMutableArray *itemsByLastUse;

- (NSString *)getTitleForPrefix:(NSString *)prefix;
- (void)insertOrUpdate:(NSString *)title;

+ (InfoCache *)instance;

@end
