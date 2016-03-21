//
//  InfoCache.m
//  Timee
//
//  Created by Morten Hornbech on 11/05/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "InfoCache.h"
#import "InfoCacheItem.h"
#import "TimeeData.h"

#define kInfoCacheItemEntityName    @"InfoCacheItem"
#define kCacheLimit                 100

@implementation InfoCache

@synthesize itemsByTitle = _itemsByTitle;
@synthesize itemsByLastUse = _itemsByLastUse;

static InfoCache *_instance;

- (id)init
{
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kInfoCacheItemEntityName];   
    NSArray *items = [[TimeeData context] executeFetchRequest:fetchRequest error:&error];
    
    self.itemsByTitle = [NSMutableArray arrayWithArray:[items sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((InfoCacheItem *)obj1).title compare:((InfoCacheItem *)obj2).title];
    }]];
    self.itemsByLastUse = [NSMutableArray arrayWithArray:[items sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((InfoCacheItem *)obj1).lastUse compare:((InfoCacheItem *)obj2).lastUse];
    }]];
    
    return self;
}

+ (InfoCache *)instance
{
    if (_instance == nil)
        _instance = [[InfoCache alloc] init];
    
    return _instance;
}

- (NSString *)getTitleForPrefix:(NSString *)prefix
{
    NSMutableArray *
    matches = [[NSMutableArray alloc] init];
    NSInteger index = -1;
    
    for (int i = 0; i < self.itemsByTitle.count; i++)
    {
        if ([((InfoCacheItem *)[self.itemsByTitle objectAtIndex:i]).title hasPrefix:prefix])
        {
            index = i;
            break;
        }
    }
    
    if (index != -1)
    {
        do 
        {
            [matches addObject:[self.itemsByTitle objectAtIndex:index]];
            index++;
        } 
        while (index < self.itemsByTitle.count && [((InfoCacheItem *)[self.itemsByTitle objectAtIndex:index]).title hasPrefix:prefix]);
        
        InfoCacheItem *mostRecentMatch = [matches objectAtIndex:0];
        
        for (int i = 1; i < matches.count; i++)
        {
            InfoCacheItem *candidate = [matches objectAtIndex:i];
            
            if ([mostRecentMatch.lastUse compare:candidate.lastUse] == NSOrderedAscending)
                mostRecentMatch = candidate;
        }
        
        return mostRecentMatch.title;
    }
    
    return nil;
}

- (void)insertOrUpdate:(NSString *)title
{
    if ([title isEqualToString:@""])
        return; 
    
    InfoCacheItem *item = nil;
    
    for (int i = 0; i < self.itemsByTitle.count; i++)
    {
        InfoCacheItem *candidate = [self.itemsByTitle objectAtIndex:i];
        
        if ([title isEqualToString:candidate.title])
        {
            item = candidate;
            break;
        }
    }
    
    if (item != nil)
    {
        [self.itemsByLastUse removeObjectIdenticalTo:item];
    }
    else 
    {
        if (self.itemsByTitle.count == kCacheLimit)
        {
            InfoCacheItem *leastRecentlyUsed = [self.itemsByLastUse objectAtIndex:0];
            [self.itemsByLastUse removeObjectAtIndex:0];
            [self.itemsByTitle removeObjectIdenticalTo:leastRecentlyUsed];
            [[TimeeData context] deleteObject:leastRecentlyUsed];
        }
        
        item = [NSEntityDescription insertNewObjectForEntityForName:kInfoCacheItemEntityName inManagedObjectContext:[TimeeData context]];
        item.title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        for (int i = 0; i < self.itemsByTitle.count; i++) 
        {
            InfoCacheItem *successor = [self.itemsByTitle objectAtIndex:i];
            
            if ([item.title compare:successor.title] == NSOrderedAscending)
            {
                [self.itemsByTitle insertObject:item atIndex:i];
                break;
            }
        }
        
        if (self.itemsByLastUse.count == self.itemsByTitle.count)
            [self.itemsByTitle addObject:item];
    }
    
    item.lastUse = [NSDate date];
    [self.itemsByLastUse addObject:item];
}

@end
