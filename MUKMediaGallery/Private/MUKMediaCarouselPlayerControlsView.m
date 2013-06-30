#import "MUKMediaCarouselPlayerControlsView.h"
#import "MUKMediaGalleryToolbar.h"
#import "MUKMediaGalleryUtils.h"
#import "MUKMediaGallerySlider.h"
#import <MUKToolkit/MUK+String.h>

static CGFloat const kToolbarHeight = 44.0f;

@interface MUKMediaCarouselPlayerControlsView () <UIToolbarDelegate>
@property (nonatomic, weak) UIView *backgroundView;
@property (nonatomic, weak) UIButton *playPauseButton, *fullscreenButton;
@property (nonatomic, weak) UISlider *slider;
@property (nonatomic, weak) UILabel *timeLabel;
@end

@implementation MUKMediaCarouselPlayerControlsView

- (id)initWithFrame:(CGRect)frame
{
    frame.size.height = kToolbarHeight;
    
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        self.tintColor = [UIColor whiteColor];
        
        UIView *backgroundView = [self newBackgroundViewInSuperview:self];
        _backgroundView = backgroundView;
        
        UIButton *playPauseButton = [self newPlayPauseButtonInSuperview:self];
        _playPauseButton = playPauseButton;
        [self showPauseIcon:NO];
        
        UISlider *slider = [self newSliderInSuperview:self afterPlayPauseButton:playPauseButton];
        _slider = slider;
        
        UILabel *timeLabel = [self newTimeLabelInSuperview:self afterSlider:slider];
        _timeLabel = timeLabel;
        [self showTime:-1.0];
        
        UIButton *fullscreenButton = [self newFullscreenButtonInSuperview:self afterTimeLabel:timeLabel];
        _fullscreenButton = fullscreenButton;
        [self showFullscreenIcon:YES];
    }
    return self;
}

#pragma mark - Overrides

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.frame.size.height);
}

#pragma mark - Private — Views

- (UIView *)newBackgroundViewInSuperview:(UIView *)superview {
    MUKMediaGalleryToolbar *toolbar = [[MUKMediaGalleryToolbar alloc] initWithFrame:superview.bounds];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.delegate = self;
    [superview addSubview:toolbar];

    return toolbar;
}

- (UIButton *)newPlayPauseButtonInSuperview:(UIView *)superview {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.showsTouchWhenHighlighted = YES;
    [superview addSubview:button];
    
    CGSize const kMaxButtonSize = CGSizeMake(19.0f, 23.0f);
    
    NSDictionary *const viewsDict = NSDictionaryOfVariableBindings(button);    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[button(==w)]" options:0 metrics:@{ @"w" : @(kMaxButtonSize.width) } views:viewsDict];
    [superview addConstraints:constraints];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f];
    [superview addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0f constant:kMaxButtonSize.height];
    [superview addConstraint:constraint];
    
    return button;
}

- (UISlider *)newSliderInSuperview:(UIView *)superview afterPlayPauseButton:(UIButton *)playPauseButton
{
    MUKMediaGallerySlider *slider = [[MUKMediaGallerySlider alloc] init];
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *thumbImage = [MUKMediaGalleryUtils imageNamed:@"mediaPlayer_sliderThumb"];
    [slider setThumbImage:thumbImage forState:UIControlStateNormal];
    slider.thumbOffset = CGSizeMake(0.0f, 2.0f);
    [slider setMaximumTrackTintColor:[UIColor colorWithWhite:1.0f alpha:0.5f]];
    [superview addSubview:slider];
    
    NSDictionary *const viewsDict = NSDictionaryOfVariableBindings(slider, playPauseButton);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[playPauseButton]-(12)-[slider(>=100)]" options:0 metrics:nil views:viewsDict];
    [superview addConstraints:constraints];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:slider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:playPauseButton attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:-2.0f];
    [superview addConstraint:constraint];
    
    return slider;
}

- (UILabel *)newTimeLabelInSuperview:(UIView *)superview afterSlider:(UISlider *)slider
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 40.0f)];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:10.0f];
    [superview addSubview:label];
    
    NSDictionary *const viewsDict = NSDictionaryOfVariableBindings(slider, label);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[slider]-(6)-[label(>=20)]" options:0 metrics:nil views:viewsDict];
    [superview addConstraints:constraints];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:slider attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:2.0f];
    [superview addConstraint:constraint];
    
    return label;
}

- (UIButton *)newFullscreenButtonInSuperview:(UIView *)superview afterTimeLabel:(UILabel *)timeLabel
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.showsTouchWhenHighlighted = YES;
    [superview addSubview:button];
    
    CGSize const kMaxButtonSize = CGSizeMake(32.0f, 31.0f);
    
    NSDictionary *const viewsDict = NSDictionaryOfVariableBindings(button, timeLabel);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[timeLabel]-(>=5)-[button(==w)]-(6)-|" options:0 metrics:@{ @"w" : @(kMaxButtonSize.width) } views:viewsDict];
    [superview addConstraints:constraints];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f];
    [superview addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0f constant:kMaxButtonSize.height];
    [superview addConstraint:constraint];
    
    return button;
}

#pragma mark - Private — Play/Pause

- (void)showPauseIcon:(BOOL)showsPauseIcon {
    UIImage *icon;
    if (showsPauseIcon) {
        icon = [MUKMediaGalleryUtils imageNamed:@"mediaPlayer_pause"];
    }
    else {
        icon = [MUKMediaGalleryUtils imageNamed:@"mediaPlayer_play"];
    }
    
    [self.playPauseButton setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
}

#pragma mark - Private — Time

- (void)showTime:(NSTimeInterval)interval {
    NSString *string;
    
    if (interval >= 0.0) {
        string = [MUK stringRepresentationOfTimeInterval:interval];
    }
    else {
        string = @"--:--";
    }
    
    self.timeLabel.text = string;
}

#pragma mark - Private — Fullscreen

- (void)showFullscreenIcon:(BOOL)showsFullscreenIcon {
    UIImage *icon;
    if (showsFullscreenIcon) {
        icon = [MUKMediaGalleryUtils imageNamed:@"mediaPlayer_scaleToFill"];
    }
    else {
        icon = [MUKMediaGalleryUtils imageNamed:@"mediaPlayer_scaleToFit"];
    }
    
    [self.fullscreenButton setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionBottom;
}

@end
