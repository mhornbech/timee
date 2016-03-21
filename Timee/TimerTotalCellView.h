//
//  TimerTotalCellView.h
//  Timee
//
//  Created by Morten Hornbech on 14/03/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerTotalCellView : UIView

@property (nonatomic, strong) IBOutlet UILabel *timeLabel;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *selectionMarker;

@end
