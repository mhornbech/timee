//
//  TutorialView.h
//  Timee
//
//  Created by Morten Hornbech on 20/12/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TutorialView : UIView

@property (strong, nonatomic) IBOutlet UIImageView *leftBackground;
@property (strong, nonatomic) IBOutlet UIImageView *currentBackground;
@property (strong, nonatomic) IBOutlet UIImageView *rightBackground;
@property (strong, nonatomic) IBOutlet UIImageView *leftOverlay;
@property (strong, nonatomic) IBOutlet UIImageView *currentOverlay;
@property (strong, nonatomic) IBOutlet UIImageView *rightOverlay;
@property (strong, nonatomic) IBOutlet UILabel *counterLabel;
@property (strong, nonatomic) IBOutlet UILabel *totalLabel;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;

@end
