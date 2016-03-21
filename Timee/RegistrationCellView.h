//
//  RegistrationCellView.h
//  Timee
//
//  Created by Morten Hornbech on 22/12/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegistrationCellView : UIView

@property (strong, nonatomic) IBOutlet UILabel *timespanLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UIImageView *hasNoteImage;

@end
