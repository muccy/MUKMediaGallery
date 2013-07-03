#import "MUKMediaCarouselPlayerControlsView.h"
#import "MUKMediaGalleryToolbar.h"
#import "MUKMediaGalleryUtils.h"
#import "MUKMediaGallerySlider.h"
#import <MUKToolkit/MUK+String.h>

static CGFloat const kToolbarHeight = 44.0f;

@interface MUKMediaCarouselPlayerControlsView () <UIToolbarDelegate>
@property (nonatomic, weak) MPMoviePlayerController *moviePlayerController;
@property (nonatomic, weak) UIView *backgroundView;
@property (nonatomic, weak) UIButton *playPauseButton;
@property (nonatomic, weak) UISlider *slider;
@property (nonatomic, weak) UILabel *timeLabel;
@property (nonatomic) NSTimer *playbackProgressUpdateTimer;
@property (nonatomic) BOOL isTouchingSlider;
@property (nonatomic) MPMoviePlaybackState playbackStateBeforeSliderTouches;
@end

@implementation MUKMediaCarouselPlayerControlsView

- (instancetype)initWithMoviePlayerController:(MPMoviePlayerController *)moviePlayerController
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, kToolbarHeight)];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];

        _moviePlayerController = moviePlayerController;
        
        UIView *backgroundView = [self newBackgroundViewInSuperview:self];
        _backgroundView = backgroundView;
        
        UIButton *playPauseButton = [self newPlayPauseButtonInSuperview:self];
        _playPauseButton = playPauseButton;
        [self showPauseIconForMoviePlayerController:moviePlayerController];
        
        UISlider *slider = [self newSliderInSuperview:self afterPlayPauseButton:playPauseButton];
        _slider = slider;
        [self showSliderProgressForMoviePlayerController:moviePlayerController];
        [self managePlaybackProgressUpdateTimerForMoviePlayerController:moviePlayerController];
        
        UILabel *timeLabel = [self newTimeLabelInSuperview:self afterSlider:slider];
        _timeLabel = timeLabel;
        [self showPlaybackTimeAndDurationForMoviePlayerController:self.moviePlayerController];

        [self registerToMediaPlayerControllerNotifications];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithMoviePlayerController:nil];
}

- (void)dealloc {
    [self unregisterFromMediaPlayerControllerNotifications];
}

#pragma mark - Overrides

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.frame.size.height);
}

#pragma mark - Private — View Building

- (UIView *)newBackgroundViewInSuperview:(UIView *)superview {
    UIView *view;
    if ([MUKMediaGalleryUtils defaultUIParadigm] == MUKMediaGalleryUIParadigmLayered)
    {
        // A toolbar gives live blurry effect on iOS 7
        MUKMediaGalleryToolbar *toolbar = [[MUKMediaGalleryToolbar alloc] initWithFrame:superview.bounds];
        toolbar.barStyle = UIBarStyleBlack;
        toolbar.delegate = self;
        
        view = toolbar;
    }
    else {
        view = [[UIView alloc] initWithFrame:superview.bounds];
        view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    }
    
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [superview addSubview:view];

    return view;
}

- (UIButton *)newPlayPauseButtonInSuperview:(UIView *)superview {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.showsTouchWhenHighlighted = YES;
    [button addTarget:self action:@selector(playPauseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
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
    
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(sliderTouchedDown:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(sliderBecameUntouched:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    
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
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[slider]-(6)-[label(>=20)]-(6)-|" options:0 metrics:nil views:viewsDict];
    [superview addConstraints:constraints];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:slider attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:2.0f];
    [superview addConstraint:constraint];
    
    return label;
}

#pragma mark - Private — Play/Pause

- (BOOL)isPausedMoviePlayerController:(MPMoviePlayerController *)moviePlayerController
{
    return (moviePlayerController.playbackState == MPMoviePlaybackStatePaused ||
            moviePlayerController.playbackState == MPMoviePlaybackStateStopped ||
            moviePlayerController.playbackState == MPMoviePlaybackStateInterrupted);
}

- (void)showPauseIcon:(BOOL)showsPauseIcon {
    UIImage *icon;
    if (showsPauseIcon) {
        icon = [MUKMediaGalleryUtils imageNamed:@"mediaPlayer_pause"];
    }
    else {
        icon = [MUKMediaGalleryUtils imageNamed:@"mediaPlayer_play"];
    }

    [self.playPauseButton setImage:icon forState:UIControlStateNormal];
}

- (void)showPauseIconForMoviePlayerController:(MPMoviePlayerController *)moviePlayerController
{
    [self showPauseIcon:![self isPausedMoviePlayerController:moviePlayerController]];
}

- (void)playPauseButtonPressed:(id)sender {
    if ([self isPausedMoviePlayerController:self.moviePlayerController])
    {
        [self.moviePlayerController play];
    }
    else {
        [self.moviePlayerController pause];
    }
}

#pragma mark - Private — Time

- (void)showPlaybackTime:(NSTimeInterval)playbackTime duration:(NSTimeInterval)duration
{
    NSMutableAttributedString *fullAttributedString = [[NSMutableAttributedString alloc] init];
    
    // First part: playback time
    NSString *string;
    if (playbackTime >= 0.0) {
        string = [MUK stringRepresentationOfTimeInterval:playbackTime];
    }
    else {
        string = @"--:--";
    }
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    [fullAttributedString appendAttributedString:attributedString];
    
    // Second part: duration
    if (duration > 0.0) {
        string = [@"/" stringByAppendingString:[MUK stringRepresentationOfTimeInterval:duration]];
        attributedString = [[NSAttributedString alloc] initWithString:string attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:0.5f] }];
        [fullAttributedString appendAttributedString:attributedString];
    }
    
    self.timeLabel.attributedText = fullAttributedString;
}

- (void)showPlaybackTimeAndDurationForMoviePlayerController:(MPMoviePlayerController *)moviePlayerController
{
    [self showPlaybackTime:moviePlayerController.currentPlaybackTime duration:moviePlayerController.duration];
}

#pragma mark - Private — Slider

- (void)sliderTouchedDown:(id)sender {
    if (self.isTouchingSlider == NO) {
        self.isTouchingSlider = YES;
        [self rememberPlaybackStateBeforeSliderTouchesAndPause];
    }
}

- (void)sliderBecameUntouched:(id)sender {
    self.isTouchingSlider = NO;
    [self attemptToRestorePlaybackStateBeforeSliderTouches];
}

- (void)sliderValueChanged:(id)sender {
    if (self.isTouchingSlider == NO) {
        self.isTouchingSlider = YES;
        [self rememberPlaybackStateBeforeSliderTouchesAndPause];
    }
    
    [self setPlaybackForSliderProgress:self.slider.value];
}

- (void)rememberPlaybackStateBeforeSliderTouchesAndPause {
    self.playbackStateBeforeSliderTouches = self.moviePlayerController.playbackState;
    [self.moviePlayerController pause];
}

- (void)attemptToRestorePlaybackStateBeforeSliderTouches {
    BOOL canRestorePastPlaybackState = YES;
    if (self.playbackStateBeforeSliderTouches == MPMoviePlaybackStatePlaying &&
        self.moviePlayerController.currentPlaybackTime >= self.moviePlayerController.duration)
    {
        canRestorePastPlaybackState = NO;
    }
    
    if (canRestorePastPlaybackState) {
        if (self.playbackStateBeforeSliderTouches == MPMoviePlaybackStatePlaying)
        {
            [self.moviePlayerController play];
        }
        else {
            [self.moviePlayerController pause];
        }
    }
}

#pragma mark - Private — Playback Progress

- (void)showSliderProgressForMoviePlayerController:(MPMoviePlayerController *)moviePlayerController
{
    float progress = 0.0f;
    
    if (moviePlayerController.duration > 0.0){
        progress = moviePlayerController.currentPlaybackTime/moviePlayerController.duration;
    }
    
    [self.slider setValue:progress animated:NO];
}

- (void)setPlaybackForSliderProgress:(float)progress {
    NSTimeInterval playbackTime = 0.0;
    
    if (self.moviePlayerController.duration > 0.0) {
        playbackTime = self.moviePlayerController.duration * progress;
    }
    
    self.moviePlayerController.currentPlaybackTime = playbackTime;
    [self showPlaybackTimeAndDurationForMoviePlayerController:self.moviePlayerController];
}

- (void)startPlackbackProgressUpdateTimer {
    if (![self.playbackProgressUpdateTimer isValid]) {
        self.playbackProgressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(playbackProgressUpdateTimerFired:) userInfo:nil repeats:YES];
    }
}

- (void)stopPlaybackProgressUpdateTimer {
    if ([self.playbackProgressUpdateTimer isValid]) {
        [self.playbackProgressUpdateTimer invalidate];
        self.playbackProgressUpdateTimer = nil;
    }
}

- (void)managePlaybackProgressUpdateTimerForMoviePlayerController:(MPMoviePlayerController *)moviePlayerController
{
    if ([self isPausedMoviePlayerController:moviePlayerController]) {
        [self stopPlaybackProgressUpdateTimer];
    }
    else {
        [self startPlackbackProgressUpdateTimer];
    }
}

- (void)playbackProgressUpdateTimerFired:(NSTimer *)timer {
    if (self.isTouchingSlider == NO) {
        [self showPlaybackTimeAndDurationForMoviePlayerController:self.moviePlayerController];
        [self showSliderProgressForMoviePlayerController:self.moviePlayerController];
    }
}

#pragma mark - Private — Notifications

- (void)registerToMediaPlayerControllerNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(playbackStateDidChangeNotification:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayerController];
    [nc addObserver:self selector:@selector(durationAvailableNotification:) name:MPMovieDurationAvailableNotification object:self.moviePlayerController];
}

- (void)unregisterFromMediaPlayerControllerNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [nc removeObserver:self name:MPMovieDurationAvailableNotification object:nil];
}

- (void)playbackStateDidChangeNotification:(NSNotification *)notification {
    if (!self.isTouchingSlider) {
        [self showPauseIconForMoviePlayerController:self.moviePlayerController];
        [self showPlaybackTimeAndDurationForMoviePlayerController:self.moviePlayerController];
        [self managePlaybackProgressUpdateTimerForMoviePlayerController:self.moviePlayerController];
    }
}

- (void)durationAvailableNotification:(NSNotification *)notification {
    [self showSliderProgressForMoviePlayerController:self.moviePlayerController];
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionBottom;
}

@end
