#import "MUKMediaCarouselItemViewController.h"
#import "MUKMediaPlayerView.h"

@class MUKMediaCarouselPlayerViewController;
@protocol MUKMediaCarouselPlayerViewControllerDelegate <MUKMediaCarouselItemViewControllerDelegate>
- (void)carouselPlayerViewControllerDidChangePlaybackState:(MUKMediaCarouselPlayerViewController *)viewController;
@end


@interface MUKMediaCarouselPlayerViewController : MUKMediaCarouselItemViewController <MUKMediaPlayerViewDelegate>
@property (nonatomic, weak) id<MUKMediaCarouselPlayerViewControllerDelegate> delegate;
@property (nonatomic, readonly, weak) MUKMediaPlayerView *playerView;

- (void)setMediaURL:(NSURL *)mediaURL;
@end
