#import "MUKMediaCarouselPlayerCell.h"

@interface MUKMediaCarouselPlayerCell ()
@property (nonatomic, readwrite) MPMoviePlayerController *moviePlayerController;
@end

@implementation MUKMediaCarouselPlayerCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
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
        
        self.moviePlayerController.view.frame = self.contentView.bounds;
        self.moviePlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.contentView insertSubview:self.moviePlayerController.view belowSubview:self.overlayView];
        
        UIButton *playButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [playButton setTitle:@"Play/Pause" forState:UIControlStateNormal];
        [playButton sizeToFit];
        [playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        playButton.center = self.moviePlayerController.view.center;
        playButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin;
        playButton.tintColor = [UIColor greenColor];
        [self.moviePlayerController.view addSubview:playButton];
    }
    else {
        self.moviePlayerController.contentURL = mediaURL;
    }
}

#pragma mark - Private

- (void)playButtonPressed:(id)sender {
    if (self.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying)
    {
        [self.moviePlayerController pause];
    }
    else {
        [self.moviePlayerController play];
    }
}

@end
