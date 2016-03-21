//
//  TimerTableCellView.h
//  Timee
//
//  Created by Morten Hornbech on 23/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCellButton : UIButton

@end

@interface TimerTableCellView : UIView

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet TableViewCellButton *deleteButton;
@property (strong, nonatomic) IBOutlet TableViewCellButton *detailsButton;
@property (strong, nonatomic) IBOutlet UIImageView *background;
@property (strong, nonatomic) IBOutlet UIImageView *selectedBackground;
@property (strong, nonatomic) IBOutlet UIImageView *selectionMarker;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeRecognizer;

@end
