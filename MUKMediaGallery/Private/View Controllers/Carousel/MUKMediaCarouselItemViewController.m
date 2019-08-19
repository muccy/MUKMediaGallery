#import "MUKMediaCarouselItemViewController.h"
#import "MUKMediaGalleryUtils.h"

static CGFloat const kCaptionLabelMaxHeight = 80.0f;
static CGFloat const kCaptionLabelLateralPadding = 8.0f;
static CGFloat const kCaptionLabelBottomPadding = 5.0f;
static CGFloat const kCaptionLabelTopPadding = 3.0f;

@interface MUKMediaCarouselItemViewController ()
@property (nonatomic, weak, readwrite) UIView *overlayView;
@property (nonatomic, weak, readwrite) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak, readwrite) UILabel *captionLabel;
@property (nonatomic, weak, readwrite) UIView *captionBackgroundView;
@property (nonatomic, weak, readwrite) UIImageView *thumbnailImageView;

@property (nonatomic, copy, nullable) NSArray<NSLayoutConstraint *> *captionRelatedConstraints;
@end

@implementation MUKMediaCarouselItemViewController

- (void)dealloc {
    [self unregisterFromContentSizeCategoryNotifications];
}

- (instancetype)initWithMediaIndex:(NSInteger)idx {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _mediaIndex = idx;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIView *overlayView = [self newOverlayViewInSuperview:self.view];
    self.overlayView = overlayView;
    
    UIActivityIndicatorView *activityIndicatorView = [self newCenteredActivityIndicatorViewInSuperview:overlayView];
    self.activityIndicatorView = activityIndicatorView;
    
    UILabel *captionLabel = [self newBottomAttachedCaptionLabelInSuperview:overlayView];
    self.captionLabel = captionLabel;
    
    UIView *captionBackgroundView = [self newBottomAttachedBackgroundViewForCaptionLabel:captionLabel inSuperview:overlayView];
    self.captionBackgroundView = captionBackgroundView;
    
    [self updateCaptionConstraintsWhenHidden:NO];
    [self registerToContentSizeCategoryNotifications];
    [self attachTapGestureRecognizer];
}

#pragma mark - Caption

- (BOOL)isCaptionHidden {
    return self.captionBackgroundView.alpha < 1.0f;
}

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
                    [self.view layoutIfNeeded];
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
            [self.view layoutIfNeeded];
        } completion:completionHandler];
    }
}

#pragma mark - Thumbnail

- (void)createThumbnailImageViewIfNeededInSuperview:(UIView *)superview belowSubview:(UIView *)subview
{
    if (![self.thumbnailImageView.superview isEqual:superview]) {
        [self.thumbnailImageView removeFromSuperview];
        self.thumbnailImageView = nil;
    }
    
    if (self.thumbnailImageView == nil) {
        UIImageView *thumbnailImageView = [[UIImageView alloc] initWithFrame:superview.bounds];
        thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
        thumbnailImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        if (subview) {
            [superview insertSubview:thumbnailImageView belowSubview:subview];
        }
        else {
            [superview addSubview:thumbnailImageView];
        }
        
        self.thumbnailImageView = thumbnailImageView;
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
    label.font = [[self class] defaultCaptionLabelFont];
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
    UIVisualEffect *const effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *const view = [[UIVisualEffectView alloc] initWithEffect:effect];
    
    view.userInteractionEnabled = NO;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [superview insertSubview:view belowSubview:label];
    
    NSDictionary *viewsDict = NSDictionaryOfVariableBindings(view);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[view]-(0)-|" options:0 metrics:nil views:viewsDict];
    [superview addConstraints:constraints];
    
    [view.topAnchor constraintEqualToAnchor:label.topAnchor constant:-kCaptionLabelTopPadding].active = YES;
    
    return view;
}

#pragma mark - Private — Caption

- (void)updateCaptionConstraintsWhenHidden:(BOOL)hidden {
    NSArray<NSLayoutConstraint *> *newConstraints;
    
    if (hidden) {
        newConstraints = @[
            [self.captionLabel.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:kCaptionLabelTopPadding],
            [self.captionBackgroundView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:kCaptionLabelTopPadding]
        ];
    }
    else {
        NSLayoutAnchor *safeBottomAnchor;
        if (@available(iOS 11.0, *)) {
            safeBottomAnchor = self.view.safeAreaLayoutGuide.bottomAnchor;
        } else {
            safeBottomAnchor = self.view.layoutMarginsGuide.bottomAnchor;
        }
        
        newConstraints = @[
            [self.captionLabel.bottomAnchor constraintEqualToAnchor:safeBottomAnchor constant:-kCaptionLabelBottomPadding],
            [self.captionBackgroundView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
        ];
    }
    
    if (self.captionRelatedConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.captionRelatedConstraints];
    }
    
    [NSLayoutConstraint activateConstraints:newConstraints];
    self.captionRelatedConstraints = newConstraints;
}

#pragma mark - Private — Notifications

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
    self.captionLabel.font = [[self class] defaultCaptionLabelFont];
}

#pragma mark - Private — Fonts

+ (UIFont *)defaultCaptionLabelFont {
    UIFont *font;
    
    if ([[UIFont class] respondsToSelector:@selector(preferredFontForTextStyle:)])
    {
        font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    }
    else {
        font = [UIFont systemFontOfSize:12.0f];
    }
    
    return font;
}

#pragma mark - Private — Tap Gesture Recognizer

- (void)attachTapGestureRecognizer {
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:gestureRecognizer];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.delegate carouselItemViewControllerDidReceiveTap:self];
    }
}

@end
