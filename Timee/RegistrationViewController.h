//
//  RegistrationViewController.h
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

@class RegistrationViewController;

@protocol RegistrationViewControllerDelegate

- (void)registrationViewControllerDidFinish:(RegistrationViewController *)controller saveContext:(BOOL)saveContext;

@end

@class Registration;
@class RegistrationView;

@interface RegistrationViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (assign, nonatomic) id<RegistrationViewControllerDelegate> delegate;
@property (strong, nonatomic) NSDate *endTime;
@property (strong, nonatomic) NSManagedObjectID *objectId;
@property (strong, nonatomic) RegistrationView *registrationView;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSString *note;
@property (strong, nonatomic) UILabel *startLabel;
@property (strong, nonatomic) UILabel *endLabel;
@property (strong, nonatomic) UITextField *noteTextField;
@property (nonatomic) NSInteger selectedRow;

- (IBAction)cancel:(id)sender;
- (IBAction)dateChanged:(id)sender;
- (IBAction)done:(id)sender;
- (void)textFieldDone:(id)sender;

- (BOOL)isValid;
- (NSInteger)numberOfRegistrationsToReplace;

@end
