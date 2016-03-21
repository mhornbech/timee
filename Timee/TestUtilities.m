//
//  TestUtilities.m
//  Timee
//
//  Created by Morten Hornbech on 16/10/12.
//
//

#import "Registration.h"
#import "TestUtilities.h"
#import "TimeeData.h"
#import "Timer.h"
#import "TimerInfo.h"

@implementation TestUtilities

+ (void)createScreenshotData
{
    [self createTimerWithInfo:[NSArray arrayWithObjects:
                               @"iOS 6 compatibility",
                               @"Test", nil]
             andRegistrations:[NSArray arrayWithObjects:nil]
             andLastResetTime:nil];
    
    [self createTimerWithInfo:[NSArray arrayWithObjects:
                               @"Font drawing",
                               @"Design", nil]
             andRegistrations:[NSArray arrayWithObjects:
                               @"13/10/12 12.00", @"13/10/12 15.25", nil]
             andLastResetTime:nil];
    
    [self createTimerWithInfo:[NSArray arrayWithObjects:
                               @"Custom search bar",
                               @"Development", nil]
             andRegistrations:[NSArray arrayWithObjects:
                               @"14/10/12 14.08", @"14/10/12 16.15", nil]
             andLastResetTime:nil];
    
    [self createTimerWithInfo:[NSArray arrayWithObjects:
                               @"Stress scenarios",
                               @"Test", nil]
             andRegistrations:[NSArray arrayWithObjects:
                               @"16/10/12 15.05", @"16/10/12 16.02", nil]
             andLastResetTime:nil];
    
    [self createTimerWithInfo:[NSArray arrayWithObjects:
                               @"Feedback icon",
                               @"Design", nil]
             andRegistrations:[NSArray arrayWithObjects:
                               @"16/10/12 10.36", @"16/10/12 11.30",
                               @"16/10/12 12.42", @"16/10/12 15.05",
                               @"15/10/12 11.59", @"15/10/12 14.00", nil]
             andLastResetTime:nil];
    
    [self createTimerWithInfo:[NSArray arrayWithObjects:
                               @"iPhone 5 support",
                               @"Development",
                               @"Timee", nil]
             andRegistrations:[NSArray arrayWithObjects:
                               @"16/10/12 08.03", @"16/10/12 10.36",
                               @"16/10/12 12.01", @"16/10/12 12.42",
                               @"16/10/12 20.16", @"16/10/12 21.11",
                               @"15/10/12 20.07", @"15/10/12 22.20",
                               @"15/10/12 14.00", @"15/10/12 15.58", nil]
             andLastResetTime:@"15/10/12 22.20"];
}

+ (void)createTimerWithInfo:(NSArray *)info andRegistrations:(NSArray *)registrations andLastResetTime:(NSString *)resetTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"da_DK"];
    
    Timer *timer = [NSEntityDescription  insertNewObjectForEntityForName:@"Timer" inManagedObjectContext:[TimeeData context]];
    
    for (NSString *infoElement in info)
    {
        TimerInfo *timerInfo = [NSEntityDescription  insertNewObjectForEntityForName:@"TimerInfo" inManagedObjectContext:[TimeeData context]];
        timerInfo.title = infoElement;
        timerInfo.index = [NSNumber numberWithInt:[info indexOfObject:infoElement]];
        [timer addInfoObject:timerInfo];
    }
    
    timer.creationTime = [NSDate date];
    timer.timerTableSummaryType = @"current";
    
    if (resetTime != nil)
        timer.lastResetTime = [formatter dateFromString:resetTime];
    
    [[TimeeData instance] addTimer:timer];
    
    for (int i = 0; i < registrations.count; i += 2)
    {
        Registration *registration = [NSEntityDescription insertNewObjectForEntityForName:@"Registration"
                                                                   inManagedObjectContext:[TimeeData context]];
        
        registration.startTime = [formatter dateFromString:[registrations objectAtIndex:i]];
        registration.endTime = [formatter dateFromString:[registrations objectAtIndex:i + 1]];
        [[TimeeData instance] addRegistration:registration toTimer:timer];
    }
    
    [TimeeData commit];
}

+ (void)createTestRegistrationsAndTimers
{
    int timers = 10;
    int registrationsPerTimer = 100;
    int duration = 1800;
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-timers * registrationsPerTimer * duration];
    
    for (int i = 0; i < timers; i++)
    {
        Timer *timer = [NSEntityDescription  insertNewObjectForEntityForName:@"Timer" inManagedObjectContext:[TimeeData context]];
        TimerInfo *info1 = [NSEntityDescription  insertNewObjectForEntityForName:@"TimerInfo" inManagedObjectContext:[TimeeData context]];
        TimerInfo *info2 = [NSEntityDescription  insertNewObjectForEntityForName:@"TimerInfo" inManagedObjectContext:[TimeeData context]];
        info1.title = [NSString stringWithFormat:@"TimerTitle%d", i];
        info1.index = [NSNumber numberWithInt:0];
        info2.title = [NSString stringWithFormat:@"TimerSubtitle%d", i];
        info2.index = [NSNumber numberWithInt:1];
        [timer addInfoObject:info1];
        [timer addInfoObject:info2];
        
        for (int j = 0; j < registrationsPerTimer; j++)
        {
            Registration *registration = [NSEntityDescription insertNewObjectForEntityForName:@"Registration"
                                                                       inManagedObjectContext:[TimeeData context]];
            
            registration.startTime = [startDate dateByAddingTimeInterval:(timers * j + i) * duration];
            registration.endTime = [registration.startTime dateByAddingTimeInterval:duration];
            
            if (timer.creationTime == nil)
            {
                timer.creationTime = registration.startTime;
                timer.timerTableSummaryType = @"current";
                [[TimeeData instance] addTimer:timer];
            }
            
            [[TimeeData instance] addRegistration:registration toTimer:timer];
        }
    }
    
    [TimeeData commit];
}

@end
