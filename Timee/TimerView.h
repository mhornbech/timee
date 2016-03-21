//
//  TimerView.h
//  Timee
//
//  Created by Morten Hornbech on 07/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerView : UIView

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;

@end
