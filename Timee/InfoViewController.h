//
//  InfoViewController.h
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

@class InfoView;
@class InfoViewController;

@protocol InfoViewControllerDelegate

- (void)infoViewControllerDidFinish:(InfoViewController *)controller;

@end

@interface InfoViewController : UIViewController

@property (assign, nonatomic) IBOutlet id<InfoViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet InfoView *infoView;

- (IBAction)done:(id)sender;
- (IBAction)submitFeedback;

@end
