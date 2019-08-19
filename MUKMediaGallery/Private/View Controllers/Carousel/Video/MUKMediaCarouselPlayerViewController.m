#import "MUKMediaCarouselPlayerViewController.h"
#import "MUKMediaCarouselPlayerControlsView.h"

@interface MUKMediaCarouselPlayerViewController ()
@property (nonatomic, readwrite, weak) MUKMediaPlayerView *playerView;
@property (nonatomic, getter = isRegisteredToMoviePlayerControllerNotifications) BOOL registeredToMoviePlayerControllerNotifications;
@end

@implementation MUKMediaCarouselPlayerViewController
@dynamic delegate;

#pragma mark - Methods

- (void)setMediaURL:(NSURL *)mediaURL {
    if (mediaURL == nil) {
        [self stop];
        [self removePlayerView];
        return;
    }
    
    if (self.playerView == nil) {
        [self insertPlayerView];
        
        // Create room for thumbnail
        [self createThumbnailImageViewIfNeededInSuperview:self.playerView belowSubview:self.playerView.controlsView];
    }

    // Set media URL
    AVPlayerItem *const item = [[AVPlayerItem alloc] initWithURL:mediaURL];
    
    if (self.playerView.player) {
        [self.playerView.player replaceCurrentItemWithPlayerItem:item];
    }
    else {
        self.playerView.player = [[AVPlayer alloc] initWithPlayerItem:item];
    }
    
    // Show
    [self.playerView setPlayerControlsHidden:NO animated:NO completion:nil];
}

#pragma mark - Private — Player

- (void)insertPlayerView {
    MUKMediaPlayerView *playerView = [[MUKMediaPlayerView alloc] initWithFrame:self.view.bounds];
    playerView.delegate = self;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:playerView belowSubview:self.overlayView];
    
    NSLayoutConstraint *const bottomConstraint = [playerView.controlsView.bottomAnchor constraintEqualToAnchor:self.captionBackgroundView.topAnchor constant:-1.0f/UIScreen.mainScreen.scale];
    bottomConstraint.priority = UILayoutPriorityDefaultHigh;
    
    [NSLayoutConstraint activateConstraints:@[
        [playerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [playerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [playerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [playerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        
        bottomConstraint
    ]];
    
    self.playerView = playerView;
}

- (void)removePlayerView {
    [self stop];
    [self.playerView removeFromSuperview];
}

- (void)stop {
    self.playerView.player.rate = 0;
}

#pragma mark - <MUKMediaPlayerViewDelegate>

- (void)playerViewDidChangeRate:(MUKMediaPlayerView *)view {
    [self.delegate carouselPlayerViewControllerDidChangePlaybackState:self];
}

@end
