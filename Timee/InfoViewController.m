//
//  InfoViewController.m
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "InfoView.h"
#import "InfoViewController.h"
#import <MessageUI/MessageUI.h>

@implementation InfoViewController

@synthesize delegate = _delegate;
@synthesize infoView = _infoView;

#pragma mark - View lifecycle

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    self.infoView.companyLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:12.0];
    self.infoView.versionLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:12.0];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        self.infoView.frame = self.infoView.background.frame = CGRectMake(0, 0, 320, 568);
        self.infoView.doneButton.frame = CGRectMake(0, 0, 320, 568);
        
        CGRect frame = self.infoView.companyLabel.frame;
        self.infoView.companyLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 88, frame.size.width, frame.size.height);
        
        frame = self.infoView.versionLabel.frame;
        self.infoView.versionLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 15, frame.size.width, frame.size.height);
        
        frame = self.infoView.feedbackButton.frame;
        self.infoView.feedbackButton.frame = CGRectMake(frame.origin.x, frame.origin.y + 38, frame.size.width, frame.size.height);
        
        [self.infoView.background setImage:[UIImage imageNamed:@"credits-568h"]];
    }
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate infoViewControllerDidFinish:self];
}

- (IBAction)submitFeedback
{
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    mailer.mailComposeDelegate = (id<MFMailComposeViewControllerDelegate>)self.delegate;
    [mailer setToRecipients:[NSArray arrayWithObject:@"contact@snapproducts.dk"]];
    [self presentModalViewController:mailer animated:YES];
}

@end
