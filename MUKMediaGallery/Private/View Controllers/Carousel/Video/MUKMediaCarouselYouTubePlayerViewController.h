#import "MUKMediaCarouselPlayerViewController.h"

@class MUKMediaCarouselYouTubePlayerViewController;
@protocol MUKMediaCarouselYouTubePlayerViewControllerDelegate <MUKMediaCarouselPlayerViewControllerDelegate>
- (void)carouselYouTubePlayerViewController:(MUKMediaCarouselYouTubePlayerViewController *)viewController webView:(UIWebView *)webView didReceiveTapWithGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer;
- (void)carouselYouTubePlayerViewController:(MUKMediaCarouselYouTubePlayerViewController *)viewController didFinishLoadingWebView:(UIWebView *)webView error:(NSError *)error;
@end


@interface MUKMediaCarouselYouTubePlayerViewController : MUKMediaCarouselPlayerViewController
@property (nonatomic, weak) id<MUKMediaCarouselYouTubePlayerViewControllerDelegate> delegate;

- (void)setYouTubeURL:(NSURL *)youTubeURL;
@end
