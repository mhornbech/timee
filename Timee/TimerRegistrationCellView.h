//
//  TimerRegistrationCellView.h
//  Timee
//
//  Created by Morten Hornbech on 14/02/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerRegistrationCellView : UIView

@property (strong, nonatomic) IBOutlet UILabel *timespanLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UIImageView *hasNoteImage;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeRecognizer;

@end
