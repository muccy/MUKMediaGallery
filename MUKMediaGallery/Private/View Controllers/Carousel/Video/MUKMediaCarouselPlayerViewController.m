#import "MUKMediaCarouselPlayerViewController.h"
#import "MUKMediaCarouselPlayerControlsView.h"

@interface MUKMediaCarouselPlayerViewController ()
@property (nonatomic, readwrite) MPMoviePlayerController *moviePlayerController;
@property (nonatomic, weak) MUKMediaCarouselPlayerControlsView *playerControlsView;
@property (nonatomic, getter = isRegisteredToMoviePlayerControllerNotifications) BOOL registeredToMoviePlayerControllerNotifications;
@property (nonatomic) NSTimer *playerControlsHideTimer;
@end

@implementation MUKMediaCarouselPlayerViewController
@dynamic delegate;

- (void)dealloc {
    [self cancelPlayerControlsHideTimer];
    [self unregisterFromMoviePlayerControllerNotifications];
}

#pragma mark - Methods

- (void)setMediaURL:(NSURL *)mediaURL {
    if (mediaURL == nil) {
        [self.moviePlayerController stop];
        [self.moviePlayerController.view removeFromSuperview];
        self.moviePlayerController = nil;
        return;
    }
    
    if (self.moviePlayerController == nil) {
        self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:mediaURL];
        self.moviePlayerController.shouldAutoplay = NO;
        self.moviePlayerController.controlStyle = MPMovieControlStyleNone;
        
        self.moviePlayerController.view.frame = self.view.bounds;
        self.moviePlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.view insertSubview:self.moviePlayerController.view belowSubview:self.overlayView];
        
        // This disables two finger gesture to enter fullscreen
        UIView *coverView = [[UIView alloc] initWithFrame:self.moviePlayerController.view.bounds];
        coverView.backgroundColor = [UIColor clearColor];
        coverView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.moviePlayerController.view addSubview:coverView];
        
        // Create custom controls
        MUKMediaCarouselPlayerControlsView *controlsView = [[MUKMediaCarouselPlayerControlsView alloc] initWithMoviePlayerController:self.moviePlayerController];
        self.playerControlsView = controlsView;
        [self.moviePlayerController.view addSubview:controlsView];
        
        NSDictionary *viewsDict = @{
                                    @"controls" : controlsView,
                                    @"captionBackground" : self.captionBackgroundView
                                    };
        
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[controls]-(0)-|" options:0 metrics:nil views:viewsDict];
        [self.moviePlayerController.view addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[controls]-(0)-[captionBackground]" options:0 metrics:nil views:viewsDict];
        [self.view addConstraints:constraints];
        
        // Create room for thumbnail
        [self createThumbnailImageViewIfNeededInSuperview:self.moviePlayerController.view belowSubview:self.playerControlsView];
        
        // Register to notifications
        [self registerToMoviePlayerControllerNotifications:self.moviePlayerController];
    }
    else {
        self.moviePlayerController.contentURL = mediaURL;
    }
    
    // Show
    [self setPlayerControlsHidden:NO animated:NO completion:nil];
}

- (void)setPlayerControlsHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completionHandler
{
    // Requested action invalidates automatic one
    [self cancelPlayerControlsHideTimer];
    
    NSTimeInterval const kDuration = animated ? UINavigationControllerHideShowBarDuration : 0.0;
    
    [UIView animateWithDuration:kDuration animations:^{
        self.playerControlsView.alpha = (hidden ? 0.0f : 1.0f);
    } completion:completionHandler];
}

#pragma mark - Private — Player Controls

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

#pragma mark - Private — Movie Player Controller Notifications

- (void)registerToMoviePlayerControllerNotifications:(MPMoviePlayerController *)moviePlayerController
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(moviePlayerControllerNowPlayingMovieChangedNotification:) name:MPMoviePlayerNowPlayingMovieDidChangeNotification object:moviePlayerController];
    [nc addObserver:self selector:@selector(moviePlayerControllerPlaybackStateDidChangeNotification:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:moviePlayerController];
    
    self.registeredToMoviePlayerControllerNotifications = YES;
}

- (void)unregisterFromMoviePlayerControllerNotifications {
    if (self.isRegisteredToMoviePlayerControllerNotifications) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:MPMoviePlayerNowPlayingMovieDidChangeNotification object:nil];
        [nc removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
        
        self.registeredToMoviePlayerControllerNotifications = NO;
    }
}

- (void)moviePlayerControllerNowPlayingMovieChangedNotification:(NSNotification *)notification
{
    [self.delegate carouselPlayerViewControllerDidChangeNowPlayingMovie:self];
}

- (void)moviePlayerControllerPlaybackStateDidChangeNotification:(NSNotification *)notifcation
{
    [self.delegate carouselPlayerViewControllerDidChangePlaybackState:self];
    
    // When media starts playing, hide controls after a while
    if (self.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying)
    {
        [self startPlayerControlsHideTimer];
    }
    else {
        [self cancelPlayerControlsHideTimer];
    }
}

@end
