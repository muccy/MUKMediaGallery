#import "MUKMediaCarouselPlayerControlsView.h"
#import "MUKMediaGalleryToolbar.h"
#import "MUKMediaGalleryUtils.h"
#import "MUKMediaGallerySlider.h"
#import <MUKToolkit/MUK+String.h>
#import <MUKSignal/MUKSignal.h>

static CGFloat const kToolbarHeight = 44.0f;

@interface MUKMediaCarouselPlayerControlsView () <UIToolbarDelegate>
@property (nonatomic, weak) UIView *backgroundView;
@property (nonatomic, weak) UIButton *playPauseButton;
@property (nonatomic, weak) UISlider *slider;
@property (nonatomic, weak) UILabel *timeLabel;
@property (nonatomic) BOOL isTouchingSlider;
@property (nonatomic) id timeObserver;
@property (nonatomic) MUKSignalObservation<MUKKVOSignal *> *rateObservation, *durationObservation;
@end

@implementation MUKMediaCarouselPlayerControlsView

- (void)dealloc {
    [self stopObservingPlayer];
}

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, kToolbarHeight)];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self insertSubviews];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self insertSubviews];
    }
    
    return self;
}

#pragma mark - Overrides

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.frame.size.height);
}

#pragma mark - Accessors

- (void)setPlayer:(AVPlayer *)player {
    if (player != _player) {
        [self stopObservingPlayer];
        
        _player = player;
        
        [self showPauseIconForPlayer:player];
        [self showSliderProgressForPlayer:player];
        [self showPlaybackTimeAndDurationForPlayer:player];
        
        if (player) {
            [self startObservingPlayer:player];
        }
    }
}

#pragma mark - Private — View Building

- (void)insertSubviews {
    UIView *backgroundView = [self newBackgroundViewInSuperview:self];
    _backgroundView = backgroundView;
    
    UIButton *playPauseButton = [self newPlayPauseButtonInSuperview:self];
    _playPauseButton = playPauseButton;
    
    UISlider *slider = [self newSliderInSuperview:self afterPlayPauseButton:playPauseButton];
    _slider = slider;

    UILabel *timeLabel = [self newTimeLabelInSuperview:self afterSlider:slider];
    _timeLabel = timeLabel;

    // Blank value
    [self showPauseIconForPlayer:nil];
    [self showSliderProgressForPlayer:nil];
    [self showPlaybackTimeAndDurationForPlayer:nil];
}

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
    
    CGFloat offset = 2.0f;
    if ([MUKMediaGalleryUtils defaultUIParadigm] == MUKMediaGalleryUIParadigmGlossy)
    {
        offset = 1.0f;
    }
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:slider attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:offset];
    [superview addConstraint:constraint];
    
    return label;
}

#pragma mark - Private — Play/Pause

- (BOOL)isPausedPlayer:(AVPlayer *)player {
    return ABS(player.rate - 1.0f) < FLT_EPSILON;
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

- (void)showPauseIconForPlayer:(nullable AVPlayer *)player {
    if (player) {
        [self showPauseIcon:[self isPausedPlayer:player]];
    }
    else {
        [self showPauseIcon:NO];
    }
}

- (void)playPauseButtonPressed:(id)sender {
    [self.delegate carouselPlayerControlsViewDidPressPlayPauseButton:self];
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

- (void)showPlaybackTimeAndDurationForPlayer:(nullable AVPlayer *)player {
    if (player) {
        NSTimeInterval const currentTime = CMTimeGetSeconds(player.currentItem.currentTime);
        NSTimeInterval const duration = CMTimeGetSeconds(player.currentItem.duration);
        [self showPlaybackTime:currentTime duration:duration];
    }
    else {
        [self showPlaybackTime:0 duration:0];
    }
}

#pragma mark - Private — Slider

- (void)sliderTouchedDown:(id)sender {
    self.isTouchingSlider = YES;
    [self.delegate carouselPlayerControlsViewDidStartTouchingSlider:self];
}

- (void)sliderBecameUntouched:(id)sender {
    self.isTouchingSlider = NO;
    [self.delegate carouselPlayerControlsViewDidFinishTouchingSlider:self];
}

- (void)sliderValueChanged:(id)sender {
    if (self.isTouchingSlider == NO) {
        self.isTouchingSlider = YES;
        [self.delegate carouselPlayerControlsViewDidStartTouchingSlider:self];
    }
    
    [self.delegate carouselPlayerControlsView:self didChangeSliderValue:self.slider.value];
}

#pragma mark - Private — Playback Progress

- (void)showSliderProgressForPlayer:(nullable AVPlayer *)player {
    if (player) {
        float progress = 0.0;
        
        NSTimeInterval const duration = CMTimeGetSeconds(player.currentItem.duration);
        if (duration > 0.0) {
            NSTimeInterval const currentTime = CMTimeGetSeconds(player.currentItem.currentTime);
            progress = currentTime/duration;
        }
        
        [self.slider setValue:progress animated:NO];
    }
    else {
        [self.slider setValue:0 animated:NO];
    }
}

#pragma mark - Private — Observations

- (void)startObservingPlayer:(AVPlayer *)player {
    [self addProgressUpdateObserverToPlayer:player];
    [self observeRateOfPlayer:player];
    [self observeDurationOfPlayer:player];
}

- (void)stopObservingPlayer {
    [self removeProgressUpdateObserver];
    [self stopObservingRate];
    [self stopObservingDuration];
}

- (void)addProgressUpdateObserverToPlayer:(AVPlayer *)player {
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 2) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        typeof(weakSelf) const strongSelf = weakSelf;
        if (strongSelf.isTouchingSlider == NO) {
            [strongSelf showPlaybackTimeAndDurationForPlayer:strongSelf.player];
            [strongSelf showSliderProgressForPlayer:strongSelf.player];
        }
    }];
}

- (void)removeProgressUpdateObserver {
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
    }
}

- (void)observeRateOfPlayer:(AVPlayer *)player {
    MUKKVOSignal *const signal = [[MUKKVOSignal alloc] initWithObject:player keyPath:NSStringFromSelector(@selector(rate))];
    self.rateObservation = [MUKSignalObservation observationWithSignal:signal token:[signal subscribeWithTarget:self action:@selector(rateDidChange:)]];
}

- (void)stopObservingRate {
    self.rateObservation = nil;
}

- (void)rateDidChange:(MUKKVOSignalChange<NSNumber *> *)change {
    if (!self.isTouchingSlider) {
        [self showPauseIconForPlayer:self.player];
        [self showPlaybackTimeAndDurationForPlayer:self.player];
    }
}

- (void)observeDurationOfPlayer:(AVPlayer *)player {
    MUKKVOSignal *const signal = [[MUKKVOSignal alloc] initWithObject:player keyPath:@"currentItem.duration"];
    self.durationObservation = [MUKSignalObservation observationWithSignal:signal token:[signal subscribeWithTarget:self action:@selector(durationDidChange:)]];
}

- (void)stopObservingDuration {
    self.durationObservation = nil;
}

- (void)durationDidChange:(MUKKVOSignalChange<NSValue *> *)change {
    if (CMTIME_IS_VALID(self.player.currentItem.duration)) {
        [self showSliderProgressForPlayer:self.player];
    }
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionBottom;
}

@end
