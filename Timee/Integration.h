//
//  Integration.h
//  Timee
//
//  Created by Morten Hornbech on 30/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Integration : NSObject

+ (UIAlertView *)verifyIssueId:(NSString *)issueId fromResponse:(NSHTTPURLResponse *)response;
+ (UIAlertView *)verifySettingsForApplication:(NSString *)name;

@end
