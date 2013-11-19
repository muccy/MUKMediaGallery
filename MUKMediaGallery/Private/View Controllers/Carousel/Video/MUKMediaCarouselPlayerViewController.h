#import "MUKMediaCarouselItemViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@class MUKMediaCarouselPlayerViewController;
@protocol MUKMediaCarouselPlayerViewControllerDelegate <NSObject>
- (void)carouselPlayerViewControllerDidChangeNowPlayingMovie:(MUKMediaCarouselPlayerViewController *)viewController;
- (void)carouselPlayerViewControllerDidChangePlaybackState:(MUKMediaCarouselPlayerViewController *)viewController;
@end


@interface MUKMediaCarouselPlayerViewController : MUKMediaCarouselItemViewController
@property (nonatomic, weak) id<MUKMediaCarouselPlayerViewControllerDelegate> delegate;
@property (nonatomic, readonly) MPMoviePlayerController *moviePlayerController;

- (void)setMediaURL:(NSURL *)mediaURL;
- (void)setPlayerControlsHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completionHandler;
@end
