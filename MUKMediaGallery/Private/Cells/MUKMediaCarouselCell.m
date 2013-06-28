#import "MUKMediaCarouselCell.h"

@interface MUKMediaCarouselCell ()
@property (nonatomic, weak, readwrite) UIView *overlayView;
@property (nonatomic, weak, readwrite) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation MUKMediaCarouselCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *overlayView = [self newOverlayViewInSuperview:self.contentView];
        self.overlayView = overlayView;
        
        UIActivityIndicatorView *activityIndicatorView = [self newCenteredActivityIndicatorViewInSuperview:overlayView];
        self.activityIndicatorView = activityIndicatorView;
        
    }
    return self;
}


#pragma mark - Private

- (UIView *)newOverlayViewInSuperview:(UIView *)superview {
    UIView *overlayView = [[UIView alloc] initWithFrame:superview.bounds];
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    overlayView.userInteractionEnabled = NO;
    overlayView.backgroundColor = [UIColor clearColor];
    [superview addSubview:overlayView];
    return overlayView;
}

- (UIActivityIndicatorView *)newCenteredActivityIndicatorViewInSuperview:(UIView *)superview
{
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [superview addSubview:activityIndicatorView];
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:superview attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:activityIndicatorView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:superview attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:activityIndicatorView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f];
    [superview addConstraints:@[centerX, centerY]];
    
    return activityIndicatorView;
}

@end
