#import "MUKMediaCarouselPlayerCell.h"
#import "MUKMediaCarouselPlayerControlsView.h"

@interface MUKMediaCarouselPlayerCell ()
@property (nonatomic, readwrite) MPMoviePlayerController *moviePlayerController;
@property (nonatomic, weak) MUKMediaCarouselPlayerControlsView *playerControlsView;
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
        [self.contentView addConstraints:constraints];
    }
    else {
        self.moviePlayerController.contentURL = mediaURL;
    }
    
    // Show
    [self setPlayerControlsHidden:NO animated:NO completion:nil];
}

- (void)setPlayerControlsHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completionHandler
{
    NSTimeInterval const kDuration = animated ? UINavigationControllerHideShowBarDuration : 0.0;
    
    [UIView animateWithDuration:kDuration animations:^{
        self.playerControlsView.alpha = (hidden ? 0.0f : 1.0f);
    } completion:^(BOOL finished) {
        //
        
        if (completionHandler) {
            completionHandler(finished);
        }
    }];
}

@end
