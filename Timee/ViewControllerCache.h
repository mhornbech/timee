//
//  ViewControllerCache.h
//  Timee
//
//  Created by Morten Hornbech on 29/05/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ViewControllerCache : NSObject

@property (strong, nonatomic) NSMutableDictionary *viewControllersByName; 

- (UIViewController *)getViewControllerForName:(NSString *)name;
- (void)addViewController:(UIViewController *)viewController forName:(NSString *)name;

+ (void)clear;
+ (ViewControllerCache *)instance;

@end
