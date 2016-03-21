//
//  TestUtilities.h
//  Timee
//
//  Created by Morten Hornbech on 16/10/12.
//
//

#import <Foundation/Foundation.h>

@interface TestUtilities : NSObject

+ (void)createScreenshotData;
+ (void)createTestRegistrationsAndTimers;
+ (void)createTimerWithInfo:(NSArray *)info andRegistrations:(NSArray *)registrations andLastResetTime:(NSString *)resetTime;

@end
