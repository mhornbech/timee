//
//  TimerTableView_Landscape.h
//  Timee
//
//  Created by Morten Hornbech on 28/11/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerTableView_Landscape : UIView

@property (strong, nonatomic) IBOutlet UIButton *stopTimerButton;

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) IBOutlet UIImageView *wheel;
@property (strong, nonatomic) IBOutlet UIImageView *background;

@end
