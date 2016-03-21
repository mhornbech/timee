//
//  TimerTableView.h
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerTableView : UIView

@property (strong, nonatomic) IBOutlet UIButton *displayButton;
@property (strong, nonatomic) IBOutlet UIButton *showTimerButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *panRecognizer;

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *addTimerLabel;
@property (strong, nonatomic) IBOutlet UILabel *companyLabel;

@property (strong, nonatomic) IBOutlet UIImageView *wheel;
@property (strong, nonatomic) IBOutlet UIImageView *background;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIButton *addTimerArrow;
@property (strong, nonatomic) IBOutlet UILabel *addTimerSmallLabel;

@end
