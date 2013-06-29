#import "MUKMediaCarouselCell.h"

static CGFloat const kCaptionLabelMaxHeight = 80.0f;
static CGFloat const kCaptionLabelLateralPadding = 8.0f;
static CGFloat const kCaptionLabelBottomPadding = 5.0f;

@interface MUKMediaCarouselCell ()
@property (nonatomic, weak, readwrite) UIView *overlayView;
@property (nonatomic, weak, readwrite) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak, readwrite) UILabel *captionLabel;
@property (nonatomic, weak, readwrite) UIView *captionBackgroundView;
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
        
        [self registerToContentSizeCategoryNotifications];
    }
    return self;
}

- (void)dealloc {
    [self unregisterFromContentSizeCategoryNotifications];
}

#pragma mark - Methods

- (void)setCaption:(NSString *)caption {
    if ([caption length]) {
        self.captionLabel.text = caption;
        self.captionLabel.hidden = NO;
        self.captionBackgroundView.hidden = NO;
    }
    else {
        self.captionLabel.hidden = YES;
        self.captionBackgroundView.hidden = YES;
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
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [superview addSubview:label];
    
    NSDictionary *viewsDict = NSDictionaryOfVariableBindings(label);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(padding)-[label]-(padding)-|" options:0 metrics:@{@"padding" : @(kCaptionLabelLateralPadding)} views:viewsDict];
    [superview addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[label(<=maxHeight)]-(padding)-|" options:0 metrics:@{@"padding" : @(kCaptionLabelBottomPadding), @"maxHeight" : @(kCaptionLabelMaxHeight)} views:viewsDict];
    [superview addConstraints:constraints];
    
    return label;
}

- (UIView *)newBottomAttachedBackgroundViewForCaptionLabel:(UILabel *)label inSuperview:(UIView *)superview
{
    UIView *view = [[UIView alloc] initWithFrame:label.frame];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    [superview insertSubview:view belowSubview:label];
    
    NSDictionary *viewsDict = NSDictionaryOfVariableBindings(view);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[view]-(0)-|" options:0 metrics:nil views:viewsDict];
    [superview addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[view]-(0)-|" options:0 metrics:nil views:viewsDict];
    [superview addConstraints:constraints];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:label attribute:NSLayoutAttributeHeight multiplier:1.0f constant:kCaptionLabelBottomPadding + 3.0f];
    [superview addConstraint:constraint];
    
    return view;
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
