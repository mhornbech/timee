//
//  ViewControllerCache.m
//  Timee
//
//  Created by Morten Hornbech on 29/05/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "ViewControllerCache.h"

@implementation ViewControllerCache

static ViewControllerCache *_instance;

@synthesize viewControllersByName = _viewControllersByName;

- (UIViewController *)getViewControllerForName:(NSString *)name
{
    return [self.viewControllersByName valueForKey:name];
}

- (void)addViewController:(UIViewController *)viewController forName:(NSString *)name
{
    [self.viewControllersByName setValue:viewController forKey:name];
}

+ (void)clear
{
    _instance = nil;
}

+ (ViewControllerCache *)instance
{
    if (_instance == nil)
    {        
        _instance = [[ViewControllerCache alloc] init];
        _instance.viewControllersByName = [[NSMutableDictionary alloc] init];
    }
    
    return _instance;
}

@end
