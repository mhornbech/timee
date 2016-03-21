//
//  TimerInfoCellView.h
//  Timee
//
//  Created by Morten Hornbech on 24/03/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerInfoCellView : UIView

@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) IBOutlet UIButton *acceptButton;
@property (strong, nonatomic) IBOutlet UIButton *clearButton;
@property (strong, nonatomic) IBOutlet UILabel *onDeleteLabel;
@property (strong, nonatomic) IBOutlet UILabel *suggestionLabel;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeRecognizer;

@end
