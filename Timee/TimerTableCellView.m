//
//  TimerTableCellView.m
//  Timee
//
//  Created by Morten Hornbech on 23/10/11.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "TimerTableCellView.h"

@implementation TableViewCellButton

- (void)setHighlighted:(BOOL)highlighted
{
    UIView *view = self;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)view;
    BOOL wasEnabled = self.enabled;
    
    if (cell.isHighlighted || cell.isSelected)
        self.enabled = NO;
    
    [super setHighlighted:highlighted];
    
    self.enabled = wasEnabled;
}

@end

@implementation TimerTableCellView

@synthesize titleLabel = _titleLabel;
@synthesize subtitleLabel =_subtitleLabel;
@synthesize timeLabel = _timeLabel;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize swipeRecognizer = _swipeRecognizer;
@synthesize background = _background;
@synthesize selectedBackground = _selectedBackground;
@synthesize selectionMarker = _selectionMarker;
@synthesize deleteButton = _deleteButton;
@synthesize detailsButton = _detailsButton;
@synthesize activityIndicator = _activityIndicator;

@end
