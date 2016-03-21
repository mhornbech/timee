//
//  TutorialViewController.h
//  Timee
//
//  Created by Morten Hornbech on 20/12/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

@class TutorialView;
@class TutorialViewController;

@protocol TutorialViewControllerDelegate

- (void)tutorialViewControllerDidFinish:(TutorialViewController *)controller;

@end

@interface TutorialViewController : UIViewController<UIGestureRecognizerDelegate>

@property (assign, nonatomic) IBOutlet id<TutorialViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet TutorialView *tutorialView;
@property (strong, nonatomic) NSArray *pageBackgroundNumbers;
@property (strong, nonatomic) NSArray *backgroundRightTransitions;
@property (strong, nonatomic) NSLock *lock;
@property (nonatomic) NSInteger currentPageNumber;

- (IBAction)close:(id)sender;

- (void)onPanRecognized:(UIPanGestureRecognizer *)recognizer;
- (void)animateTransition:(BOOL)includeBackgrounds ofType:(NSString *)type duration:(NSTimeInterval)duration toNewPage:(BOOL)toNewPage;
- (void)leftCycle:(BOOL)includeBackgrounds;
- (void)rightCycle:(BOOL)includeBackgrounds;
- (void)leftCycleOverlays;
- (void)rightCycleOverlays;
- (void)leftCycleBackgrounds;
- (void)rightCycleBackgrounds;
- (void)setOverlayOnPage:(NSInteger)pageNumber inView:(UIImageView *)view;
- (void)setBackgroundOnPage:(NSInteger)pageNumber inView:(UIImageView *)view;
- (NSInteger)getImageNumber:(NSInteger)pageNumber;
- (void)translateFrame:(CGFloat)translation inView:(UIView *)view;
- (void)translateFrame:(CGFloat)translation lowerBound:(CGFloat)lower upperBound:(CGFloat)upper inView:(UIView *)view;
- (void)fadeInLeftBackground:(CGFloat)alpha;
- (void)fadeInRightBackground:(CGFloat)alpha;

@end
