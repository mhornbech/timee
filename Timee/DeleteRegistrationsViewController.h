//
//  DeleteRegistrationsViewController.h
//  Timee
//
//  Created by Morten Hornbech on 25/05/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectRegistrationsViewController.h"

@interface DeleteRegistrationsViewController : SelectRegistrationsViewController<UIAlertViewDelegate>

@property (nonatomic, retain) NSArray *emptyTimersAfterDeletion;

- (void)addEmptyTimers;

@end
