//
//  Integration.m
//  Timee
//
//  Created by Morten Hornbech on 30/07/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "Integration.h"

@implementation Integration

+ (UIAlertView *)verifyIssueId:(NSString *)issueId fromResponse:(NSHTTPURLResponse *)response
{
    NSString *title = nil;
    NSString *message = nil;
    
    if (response.statusCode == 401)
    {
        title = @"Not authorized!";
        message = [NSString stringWithFormat:@"Access to issue '%@' could not be authorized by the server.", issueId];
    }
    else if (response.statusCode == 404) 
    {        
        title = @"Issue not found!";
        message = [NSString stringWithFormat:@"Issue '%@' could not be found on the server.", issueId];
    }
    else if (response.statusCode == 403) 
    {        
        title = @"Access denied!"; 
        message = [NSString stringWithFormat:@"Access to issue '%@' was denied by the server.", issueId];
    }
    else if (response.statusCode >= 400)
    {
        title = @"Bad response!"; 
        message = [NSString stringWithFormat:@"Request for issue '%@' returned an unsuccessful response (%d).", issueId, response.statusCode];
    }
    
    if (title != nil)
        return [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    return nil;
}

+ (UIAlertView *)verifySettingsForApplication:(NSString *)name
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *title = nil;
    NSString *message = nil;
    NSString *username = [userDefaults stringForKey:[NSString stringWithFormat:@"%@Username", name]];
    NSString *password = [userDefaults stringForKey:[NSString stringWithFormat:@"%@Password", name]];
    
    if (username.length == 0 || password.length == 0)
    {
        title = @"Authentication required!";
        message = @"You must provide your credentials.";
    }
    else if ([[NSString stringWithFormat:@"%@%@", username, password] cStringUsingEncoding:NSASCIIStringEncoding] == nil)
    {
        title = @"Unsupported credentials!";
        message = @"The provided credentials contains unsupported (non-ASCII) characters.";
    }
    
    if (title != nil)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        return alertView;
    }
    
    return nil;
}

@end
