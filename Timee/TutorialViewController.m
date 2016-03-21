//
//  TutorialViewController.h
//  Timee
//
//  Created by Morten Hornbech on 20/12/12.
//  Copyright (c) 2012 snAPProducts I/S. All rights reserved.
//

#import "AppColors.h"
#import "TutorialView.h"
#import "TutorialViewController.h"

@implementation TutorialViewController

@synthesize delegate = _delegate;
@synthesize tutorialView = _tutorialView;
@synthesize pageBackgroundNumbers = _pageBackgroundNumbers;
@synthesize backgroundRightTransitions = _backgroundRightTransitions;
@synthesize currentPageNumber = _currentPageNumber;
@synthesize lock = _lock;

CGFloat currentTranslation;
BOOL isIphone5;
BOOL interactionEnabled;

#define kFade   @"fade"
#define kSlide   @"slide"

#pragma mark - View lifecycle

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated
{
    interactionEnabled = YES;
}

- (void)viewDidLoad
{
    isIphone5 = [[UIScreen mainScreen] bounds].size.height == 568;
    
    if (isIphone5)
    {
        CGRect centerFrame = CGRectMake(0, 0, 320, 568);
        CGRect leftFrame = CGRectMake(-320, 0, 320, 568);
        CGRect rightFrame = CGRectMake(320, 0, 320, 568);
        
        self.tutorialView.frame = centerFrame;
        self.tutorialView.leftBackground.frame = leftFrame;
        self.tutorialView.currentBackground.frame = centerFrame;
        self.tutorialView.rightBackground.frame = rightFrame;
        self.tutorialView.leftOverlay.frame = leftFrame;
        self.tutorialView.currentOverlay.frame = centerFrame;
        self.tutorialView.rightOverlay.frame = rightFrame;
        
        CGRect frame = self.tutorialView.closeButton.frame;
        self.tutorialView.closeButton.frame = CGRectMake(frame.origin.x, frame.origin.y + 66, frame.size.width, frame.size.height);
        
        frame = self.tutorialView.counterLabel.frame;
        self.tutorialView.counterLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 66, frame.size.width, frame.size.height);
        
        frame = self.tutorialView.totalLabel.frame;
        self.tutorialView.totalLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + 66, frame.size.width, frame.size.height);
    }
    
    self.tutorialView.counterLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18.0];
    self.tutorialView.counterLabel.textColor = [AppColors gold];
    self.tutorialView.totalLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18.0];
    self.tutorialView.totalLabel.textColor = [AppColors gold];
    
    self.lock = [[NSLock alloc] init];
    
    currentTranslation = 0;
    self.currentPageNumber = 0;
    self.pageBackgroundNumbers = [NSArray arrayWithObjects:
                                  [NSNumber numberWithInteger:0],
                                  [NSNumber numberWithInteger:1],
                                  [NSNumber numberWithInteger:2],
                                  [NSNumber numberWithInteger:2],
                                  [NSNumber numberWithInteger:3],
                                  [NSNumber numberWithInteger:4],
                                  [NSNumber numberWithInteger:5],
                                  [NSNumber numberWithInteger:5],
                                  [NSNumber numberWithInteger:5],
                                  [NSNumber numberWithInteger:6],
                                  [NSNumber numberWithInteger:7],
                                  [NSNumber numberWithInteger:7],
                                  [NSNumber numberWithInteger:8], nil];
    
    self.backgroundRightTransitions = [NSArray arrayWithObjects:kSlide, kSlide, kFade, kFade, kSlide, kFade, kSlide, kSlide, kSlide, nil];
    
    [self.tutorialView.currentOverlay addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanRecognized:)]];
    [self.tutorialView.leftOverlay addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanRecognized:)]];
    [self.tutorialView.rightOverlay addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanRecognized:)]];
    
    [self setBackgroundOnPage:0 inView:self.tutorialView.currentBackground];
    [self setBackgroundOnPage:1 inView:self.tutorialView.rightBackground];
    [self setOverlayOnPage:0 inView:self.tutorialView.currentOverlay];
    [self setOverlayOnPage:1 inView:self.tutorialView.rightOverlay];
}

#pragma mark - Instance Methods

- (void)onPanRecognized:(UIPanGestureRecognizer *)recognizer
{
    if (!interactionEnabled)
        return;
    
    [self.lock lock];
    
    CGFloat translation = [recognizer translationInView:self.tutorialView].x;
    
    if ((translation > 0 && self.currentPageNumber == 0) || (translation < 0 && self.currentPageNumber == 12))
        translation = 0;
    
    NSInteger rightBackground = ((NSNumber *)[self.pageBackgroundNumbers objectAtIndex:[self getImageNumber:self.currentPageNumber + 1]]).integerValue;
    NSInteger leftBackground = ((NSNumber *)[self.pageBackgroundNumbers objectAtIndex:[self getImageNumber:self.currentPageNumber - 1]]).integerValue;
    
    NSInteger currentBackground = ((NSNumber *)[self.pageBackgroundNumbers objectAtIndex:[self getImageNumber:self.currentPageNumber]]).integerValue;
    NSInteger nextBackground = translation > 0 ? leftBackground : rightBackground;
    NSString *transitionType = [self.backgroundRightTransitions objectAtIndex:nextBackground == leftBackground ? leftBackground : currentBackground];
    
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGFloat delta = translation - currentTranslation;
        
        [self translateFrame:delta inView:self.tutorialView.currentOverlay];
        [self translateFrame:delta inView:self.tutorialView.leftOverlay];
        [self translateFrame:delta inView:self.tutorialView.rightOverlay];
        
        if (self.tutorialView.leftOverlay.frame.origin.x > -320 && leftBackground != currentBackground && [transitionType isEqualToString:kFade])
        {
            [self fadeInLeftBackground:(self.tutorialView.leftOverlay.frame.origin.x + 320) / 320];
        }
        else if (self.tutorialView.rightOverlay.frame.origin.x < 320 && rightBackground != currentBackground && [transitionType isEqualToString:kFade])
        {
            [self fadeInRightBackground:(320 - self.tutorialView.rightOverlay.frame.origin.x) / 320];
        }
        else
        {
            [self translateFrame:delta
                      lowerBound:rightBackground == currentBackground ? 0 : MIN(0, self.tutorialView.currentOverlay.frame.origin.x)
                      upperBound:leftBackground == currentBackground ? 0 : MAX(0, self.tutorialView.currentOverlay.frame.origin.x)
                          inView:self.tutorialView.currentBackground];
            
            [self translateFrame:delta
                      lowerBound:rightBackground == currentBackground ? -320 : MIN(-320, self.tutorialView.leftOverlay.frame.origin.x)
                      upperBound:leftBackground == currentBackground ? -320 : MAX(-320, self.tutorialView.leftOverlay.frame.origin.x)
                          inView:self.tutorialView.leftBackground];
            
            [self translateFrame:delta
                      lowerBound:rightBackground == currentBackground ? 320 : MIN(320, self.tutorialView.rightOverlay.frame.origin.x)
                      upperBound:leftBackground == currentBackground ? 320 : MAX(320, self.tutorialView.rightOverlay.frame.origin.x)
                          inView:self.tutorialView.rightBackground];
        }
        
        currentTranslation = translation;
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        BOOL toNewPage = NO;
        
        if (abs(translation) > 160 || abs([recognizer velocityInView:self.tutorialView].x) > 1000)
        {
            if (translation > 0 && self.currentPageNumber > 0)
                [self rightCycle:currentBackground != nextBackground];
            else if (translation < 0 && self.currentPageNumber < self.pageBackgroundNumbers.count - 1)
                [self leftCycle:currentBackground != nextBackground];
            
            self.tutorialView.counterLabel.text = [NSNumber numberWithInteger:self.currentPageNumber + 1].stringValue;
            toNewPage = YES;
        }
        
        currentTranslation = 0;
        interactionEnabled = NO;
        
        [self animateTransition:currentBackground != nextBackground ofType:transitionType duration:0.25 toNewPage:toNewPage];
    }
    
    [self.lock unlock];
}

- (void)leftCycle:(BOOL)includeBackgrounds
{
    [self leftCycleOverlays];
    
    if (includeBackgrounds)
    {
        [self leftCycleBackgrounds];
        self.tutorialView.rightBackground.frame = CGRectMake(320, 0, 320, [UIScreen mainScreen].bounds.size.height);
    }
    
    [self setOverlayOnPage:self.currentPageNumber + 2 inView:self.tutorialView.rightOverlay];
    [self setBackgroundOnPage:self.currentPageNumber + 2 inView:self.tutorialView.rightBackground];
    self.tutorialView.rightOverlay.frame = CGRectMake(320, 0, 320, [UIScreen mainScreen].bounds.size.height);
    
    self.currentPageNumber++;
}

- (void)rightCycle:(BOOL)includeBackgrounds
{
    [self rightCycleOverlays];
    
    if (includeBackgrounds)
    {
        [self rightCycleBackgrounds];
        self.tutorialView.leftBackground.frame = CGRectMake(-320, 0, 320, [UIScreen mainScreen].bounds.size.height);
    }
    
    [self setOverlayOnPage:self.currentPageNumber - 2 inView:self.tutorialView.leftOverlay];
    [self setBackgroundOnPage:self.currentPageNumber - 2 inView:self.tutorialView.leftBackground];
    self.tutorialView.leftOverlay.frame = CGRectMake(-320, 0, 320, [UIScreen mainScreen].bounds.size.height);
    
    self.currentPageNumber--;
}

- (void)animateTransition:(BOOL)includeBackgrounds ofType:(NSString *)type duration:(NSTimeInterval)duration toNewPage:(BOOL)toNewPage
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    
    self.tutorialView.currentOverlay.frame = CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height);
    self.tutorialView.rightOverlay.frame = CGRectMake(320, 0, 320, [UIScreen mainScreen].bounds.size.height);
    self.tutorialView.leftOverlay.frame = CGRectMake(-320, 0, 320, [UIScreen mainScreen].bounds.size.height);

    if (includeBackgrounds)
    {
        if ([type isEqualToString:kFade])
        {
            if (toNewPage)
            {
                self.tutorialView.currentBackground.alpha = 1;
            }
            else
            {
                self.tutorialView.rightBackground.alpha = 0;
                self.tutorialView.leftBackground.alpha = 0;
            }
        }
        else
        {
            self.tutorialView.currentBackground.frame = CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height);
            self.tutorialView.rightBackground.frame = CGRectMake(320, 0, 320, [UIScreen mainScreen].bounds.size.height);
            self.tutorialView.leftBackground.frame = CGRectMake(-320, 0, 320, [UIScreen mainScreen].bounds.size.height);
        }
    }
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(onAnimationCompleted) withObject:nil afterDelay:duration];
}

- (void)onAnimationCompleted
{
    self.tutorialView.currentBackground.frame = CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height);
    self.tutorialView.rightBackground.frame = CGRectMake(320, 0, 320, [UIScreen mainScreen].bounds.size.height);
    self.tutorialView.leftBackground.frame = CGRectMake(-320, 0, 320, [UIScreen mainScreen].bounds.size.height);
    
    self.tutorialView.currentBackground.alpha = 1;
    self.tutorialView.rightBackground.alpha = 1;
    self.tutorialView.leftBackground.alpha = 1;
    
    interactionEnabled = YES;
}

- (void)leftCycleOverlays
{
    UIImageView* leftOverlay = self.tutorialView.leftOverlay;
    UIImageView* currentOverlay = self.tutorialView.currentOverlay;
    UIImageView* rightOverlay = self.tutorialView.rightOverlay;
        
    self.tutorialView.leftOverlay = currentOverlay;
    self.tutorialView.currentOverlay = rightOverlay;
    self.tutorialView.rightOverlay = leftOverlay;
}

- (void)rightCycleOverlays
{
    UIImageView* leftOverlay = self.tutorialView.leftOverlay;
    UIImageView* currentOverlay = self.tutorialView.currentOverlay;
    UIImageView* rightOverlay = self.tutorialView.rightOverlay;
    
    self.tutorialView.leftOverlay = rightOverlay;
    self.tutorialView.currentOverlay = leftOverlay;
    self.tutorialView.rightOverlay = currentOverlay;
}

- (void)leftCycleBackgrounds
{
    UIImageView* leftBackground = self.tutorialView.leftBackground;
    UIImageView* currentBackground = self.tutorialView.currentBackground;
    UIImageView* rightBackground = self.tutorialView.rightBackground;
    
    self.tutorialView.leftBackground = currentBackground;
    self.tutorialView.currentBackground = rightBackground;
    self.tutorialView.rightBackground = leftBackground;
}

- (void)rightCycleBackgrounds
{
    UIImageView* leftBackground = self.tutorialView.leftBackground;
    UIImageView* currentBackground = self.tutorialView.currentBackground;
    UIImageView* rightBackground = self.tutorialView.rightBackground;
    
    self.tutorialView.leftBackground = rightBackground;
    self.tutorialView.currentBackground = leftBackground;
    self.tutorialView.rightBackground = currentBackground;
}

- (void)setOverlayOnPage:(NSInteger)pageNumber inView:(UIImageView *)view
{
    [view setImage:[UIImage imageNamed:[NSString stringWithFormat:@"tutorial_overlay_%d%@",
                                        [self getImageNumber:pageNumber],
                                        isIphone5 ? @"-568h" : @""]]];
}

- (void)setBackgroundOnPage:(NSInteger)pageNumber inView:(UIImageView *)view
{
    NSInteger backgroundNumber = ((NSNumber *)[self.pageBackgroundNumbers objectAtIndex:[self getImageNumber:pageNumber]]).integerValue;
    [view setImage:[UIImage imageNamed:[NSString stringWithFormat:@"tutorial_background_%d%@",
                                        backgroundNumber,
                                        isIphone5 ? @"-568h" : @""]]];
}

- (NSInteger)getImageNumber:(NSInteger)pageNumber
{
    return MIN(MAX(0, pageNumber), self.pageBackgroundNumbers.count - 1);
}

- (void)translateFrame:(CGFloat)translation inView:(UIView *)view
{
    CGRect frame = view.frame;
    view.frame = CGRectMake(frame.origin.x + translation, frame.origin.y, frame.size.width, frame.size.height);
}

- (void)translateFrame:(CGFloat)translation lowerBound:(CGFloat)lower upperBound:(CGFloat)upper inView:(UIView *)view
{
    CGFloat translatedX = MIN(upper, MAX(lower, view.frame.origin.x + translation));
    view.frame = CGRectMake(translatedX, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
}

- (void)fadeInLeftBackground:(CGFloat)alpha
{
    [self.tutorialView sendSubviewToBack:self.tutorialView.currentBackground];
    self.tutorialView.leftBackground.frame = self.tutorialView.currentBackground.frame;
    self.tutorialView.rightBackground.frame = CGRectMake(320, 0, 320, [UIScreen mainScreen].bounds.size.height);
    self.tutorialView.leftBackground.alpha = alpha;
}

- (void)fadeInRightBackground:(CGFloat)alpha
{
    [self.tutorialView sendSubviewToBack:self.tutorialView.currentBackground];
    self.tutorialView.rightBackground.frame = self.tutorialView.currentBackground.frame;
    self.tutorialView.leftBackground.frame = CGRectMake(-320, 0, 320, [UIScreen mainScreen].bounds.size.height);
    self.tutorialView.rightBackground.alpha = alpha;
}

#pragma mark - Actions

- (IBAction)close:(id)sender
{
    [self.delegate tutorialViewControllerDidFinish:self];
}

@end
