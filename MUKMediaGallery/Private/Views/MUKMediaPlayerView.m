//
//  MUKMediaPlayerView.m
//  
//
//  Created by Marco Muccinelli on 14/08/2019.
//

#import "MUKMediaPlayerView.h"
#import <MUKSignal/MUKSignal.h>

@interface MUKMediaPlayerView () 
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic) float rateBeforeSliderTouches;
@property (nonatomic, nullable) NSTimer *playerControlsHideTimer;
@property (nonatomic, nullable) MUKSignalObservation *rateObservation;
@end

@implementation MUKMediaPlayerView
@dynamic player, playerLayer;

- (void)dealloc {
    [self cancelPlayerControlsHideTimer];
    [self stopPlayerObservations];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self insertSubviews];
    }
    return self;
}

#pragma mark - Accessors

- (AVPlayer *)player {
    return self.playerLayer.player;
}
 
- (void)setPlayer:(AVPlayer *)player {
    if (player != self.player) {
        [self stopPlayerObservations];
        self.playerLayer.player = player;
        self.controlsView.player = player;
        [self startPlayerObservations];
    }
}
 
// Override UIView method
+ (Class)layerClass {
    return [AVPlayerLayer class];
}
 
- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

#pragma mark - Methods

- (void)setPlayerControlsHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completionHandler
{
    // Requested action invalidates automatic one
    [self cancelPlayerControlsHideTimer];
    
    NSTimeInterval const kDuration = animated ? UINavigationControllerHideShowBarDuration : 0.0;
    
    [UIView animateWithDuration:kDuration animations:^{
        self.controlsView.alpha = (hidden ? 0.0f : 1.0f);
    } completion:completionHandler];
}

#pragma mark - Private

- (void)insertSubviews {
    MUKMediaCarouselPlayerControlsView *const controlsView = [[MUKMediaCarouselPlayerControlsView alloc] init];
    controlsView.translatesAutoresizingMaskIntoConstraints = NO;
    controlsView.delegate = self;
    [self addSubview:controlsView];
    _controlsView = controlsView;
    
    NSLayoutAnchor *bottomAnchor;
    if (@available(iOS 11.0, *)) {
        bottomAnchor = self.safeAreaLayoutGuide.bottomAnchor;
    } else {
        bottomAnchor = self.layoutMarginsGuide.bottomAnchor;
    }
    NSLayoutConstraint *const bottomConstraint = [controlsView.bottomAnchor constraintLessThanOrEqualToAnchor:bottomAnchor];
    
    [NSLayoutConstraint activateConstraints:@[
        [controlsView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [controlsView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        bottomConstraint
    ]];
}

#pragma mark - Private — Playback

- (void)suspendPlaybackForScrubbing {
    self.rateBeforeSliderTouches = self.player.rate;
    self.player.rate = 0;
}

- (void)restorePlaybackAfterScrubbing {
    if (!self.player) {
        return;
    }
    
    if (self.rateBeforeSliderTouches < FLT_EPSILON) {
        return;
    }
    
    if (CMTimeCompare(self.player.currentTime, self.player.currentItem.duration) == 1) { // greater
        return;
    }
    
    self.player.rate = self.rateBeforeSliderTouches;
}

- (void)seekToFraction:(float)fraction {
    if (!self.player) {
        return;
    }
    
    NSTimeInterval playbackTime = 0.0;
    
    NSTimeInterval const duration = CMTimeGetSeconds(self.player.currentItem.duration);
    if (duration > 0.0) {
        playbackTime = duration * fraction;
    }
    
    CMTime const time = CMTimeMake(playbackTime, 1);
    [self.player seekToTime:time];
}

#pragma mark - Private — Hide

- (void)startPlayerControlsHideTimer {
    [self cancelPlayerControlsHideTimer];
    self.playerControlsHideTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(playerControlsHideTimerFired:) userInfo:nil repeats:NO];
}

- (void)cancelPlayerControlsHideTimer {
    if ([self.playerControlsHideTimer isValid]) {
        [self.playerControlsHideTimer invalidate];
        self.playerControlsHideTimer = nil;
    }
}

- (void)playerControlsHideTimerFired:(NSTimer *)timer {
    [self setPlayerControlsHidden:YES animated:YES completion:nil];
}

#pragma mark - Private — Observations

- (void)startPlayerObservations {
    MUKKVOSignal *signal = [[MUKKVOSignal alloc] initWithObject:self.player keyPath:NSStringFromSelector(@selector(rate))];
    self.rateObservation = [MUKSignalObservation observationWithSignal:signal token:[signal subscribeWithTarget:self action:@selector(rateDidChange)]];
}

- (void)stopPlayerObservations {
    self.rateObservation = nil;
}

- (void)rateDidChange {
    // When media starts playing, hide controls after a while
    if (self.player.rate > 0.0) {
        [self startPlayerControlsHideTimer];
    }
    else {
        [self cancelPlayerControlsHideTimer];
    }
    
    [self.delegate playerViewDidChangeRate:self];
}

#pragma mark - <MUKMediaCarouselPlayerControlsViewDelegate>

- (void)carouselPlayerControlsViewDidPressPlayPauseButton:(MUKMediaCarouselPlayerControlsView *)controlsView {
    if (self.player) {
        if (self.player.rate > 0.0f) {
            self.player.rate = 0;
        }
        else {
            [self.player play];
        }
    }
}

- (void)carouselPlayerControlsViewDidStartTouchingSlider:(MUKMediaCarouselPlayerControlsView *)controlsView {
    [self suspendPlaybackForScrubbing];
}

- (void)carouselPlayerControlsViewDidFinishTouchingSlider:(MUKMediaCarouselPlayerControlsView *)controlsView {
    [self restorePlaybackAfterScrubbing];
}

- (void)carouselPlayerControlsView:(MUKMediaCarouselPlayerControlsView *)controlsView didChangeSliderValue:(float)newValue {
    [self seekToFraction:newValue];
}

@end
