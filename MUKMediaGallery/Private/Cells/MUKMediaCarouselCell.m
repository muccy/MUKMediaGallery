#import "MUKMediaCarouselCell.h"
#import "MUKMediaGalleryToolbar.h"

static CGFloat const kCaptionLabelMaxHeight = 80.0f;
static CGFloat const kCaptionLabelLateralPadding = 8.0f;
static CGFloat const kCaptionLabelBottomPadding = 5.0f;
static CGFloat const kCaptionLabelTopPadding = 3.0f;

@interface MUKMediaCarouselCell ()
@property (nonatomic, weak, readwrite) UIView *overlayView;
@property (nonatomic, weak, readwrite) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak, readwrite) UILabel *captionLabel;
@property (nonatomic, weak, readwrite) UIView *captionBackgroundView;

@property (nonatomic, strong) NSLayoutConstraint *captionLabelBottomConstraint, *captionLabelTopConstraint, *captionBackgroundViewBottomConstraint, *captionBackgroundViewTopConstraint;
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
        
        UILabel *captionLabel = [self newBottomAttachedCaptionLabelInSuperview:overlayView];
        self.captionLabel = captionLabel;
        
        UIView *captionBackgroundView = [self newBottomAttachedBackgroundViewForCaptionLabel:captionLabel inSuperview:overlayView];
        self.captionBackgroundView = captionBackgroundView;

        [self updateCaptionConstraintsWhenHidden:NO];
        
        [self registerToContentSizeCategoryNotifications];
    }
    return self;
}

- (void)dealloc {
    [self unregisterFromContentSizeCategoryNotifications];
}

#pragma mark - Caption

- (void)setCaptionHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completionHandler
{
    NSTimeInterval const duration = animated ? UINavigationControllerHideShowBarDuration : 0.0;
    
    if (hidden) {
        [UIView animateWithDuration:duration animations:^{
            self.captionLabel.alpha = 0.0f;
            self.captionBackgroundView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            if (finished) {
                [self updateCaptionConstraintsWhenHidden:hidden];
                
                // Animate constraints change too, if requested
                [UIView animateWithDuration:duration animations:^{
                    [self layoutIfNeeded];
                } completion:nil];
            }
            
            // Notify completion immediately, because caption has already
            // disappeared
            if (completionHandler) {
                completionHandler(finished);
            }
        }];
    }
    else {
        self.captionLabel.alpha = 1.0f;
        self.captionBackgroundView.alpha = 1.0f;
        
        [self updateCaptionConstraintsWhenHidden:hidden];
        
        [UIView animateWithDuration:duration animations:^{
            [self layoutIfNeeded];
        } completion:completionHandler];
    }
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

- (UILabel *)newBottomAttachedCaptionLabelInSuperview:(UIView *)superview {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 20.0f, 20.0f)];
    label.userInteractionEnabled = NO;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [superview addSubview:label];
    
    NSDictionary *viewsDict = NSDictionaryOfVariableBindings(label);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(padding)-[label]-(padding)-|" options:0 metrics:@{@"padding" : @(kCaptionLabelLateralPadding)} views:viewsDict];
    [superview addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[label(<=maxHeight)]" options:0 metrics:@{ @"maxHeight" : @(kCaptionLabelMaxHeight) } views:viewsDict];
    [superview addConstraints:constraints];

    return label;
}

- (UIView *)newBottomAttachedBackgroundViewForCaptionLabel:(UILabel *)label inSuperview:(UIView *)superview
{
    // A toolbar gives live blurry effect on iOS 7
    MUKMediaGalleryToolbar *view = [[MUKMediaGalleryToolbar alloc] initWithFrame:label.frame];
    view.userInteractionEnabled = NO;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.barStyle = UIBarStyleBlack;
    [superview insertSubview:view belowSubview:label];
    
    NSDictionary *viewsDict = NSDictionaryOfVariableBindings(view);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[view]-(0)-|" options:0 metrics:nil views:viewsDict];
    [superview addConstraints:constraints];

    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:label attribute:NSLayoutAttributeHeight multiplier:1.0f constant:kCaptionLabelBottomPadding + kCaptionLabelTopPadding];
    [superview addConstraint:constraint];
    
    return view;
}

#pragma mark - Private — Caption

- (void)updateCaptionConstraintsWhenHidden:(BOOL)hidden {
    UIView *const superview = self.captionLabel.superview;
    
    // Create all constraints
    if (self.captionLabelTopConstraint == nil) {
        self.captionLabelTopConstraint = [NSLayoutConstraint constraintWithItem:self.captionLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1.0f constant:kCaptionLabelTopPadding];
        [self.captionLabel.superview addConstraint:self.captionLabelTopConstraint];
    }
    
    if (self.captionBackgroundViewTopConstraint == nil) {
        self.captionBackgroundViewTopConstraint = [NSLayoutConstraint constraintWithItem:self.captionBackgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1.0f constant:kCaptionLabelTopPadding];
        [self.captionBackgroundView.superview addConstraint:self.captionBackgroundViewTopConstraint];
    }
    
    if (self.captionLabelBottomConstraint == nil) {
        self.captionLabelBottomConstraint = [NSLayoutConstraint constraintWithItem:self.captionLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-kCaptionLabelBottomPadding];
        [self.captionLabel.superview addConstraint:self.captionLabelBottomConstraint];
    }
    
    if (self.captionBackgroundViewBottomConstraint == nil) {
        self.captionBackgroundViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.captionBackgroundView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
        [self.captionBackgroundView.superview addConstraint:self.captionBackgroundViewBottomConstraint];
    }

    // Change constraints
    NSArray *unusedConstraints, *usedConstraints;
    
    if (hidden) {
        usedConstraints = @[ self.captionLabelTopConstraint, self.captionBackgroundViewTopConstraint ];
        unusedConstraints = @[ self.captionLabelBottomConstraint, self.captionBackgroundViewBottomConstraint ];
    }
    else {
        usedConstraints = @[ self.captionLabelBottomConstraint, self.captionBackgroundViewBottomConstraint ];
        unusedConstraints = @[ self.captionLabelTopConstraint, self.captionBackgroundViewTopConstraint ];
    }
    
    [superview removeConstraints:unusedConstraints];
    [superview addConstraints:usedConstraints];
    
    // Notify
    [self setNeedsUpdateConstraints];
}

#pragma mark - Notifications

- (void)registerToContentSizeCategoryNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(contentSizeCategoryDidChangeNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)unregisterFromContentSizeCategoryNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)contentSizeCategoryDidChangeNotification:(NSNotification *)notification
{
    self.captionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
}

@end
