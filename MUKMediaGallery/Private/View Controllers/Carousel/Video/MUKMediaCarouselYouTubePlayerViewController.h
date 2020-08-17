#import "MUKMediaCarouselPlayerViewController.h"
#import <WebKit/WebKit.h>

@class MUKMediaCarouselYouTubePlayerViewController;
@protocol MUKMediaCarouselYouTubePlayerViewControllerDelegate <MUKMediaCarouselPlayerViewControllerDelegate>
- (void)carouselYouTubePlayerViewController:(MUKMediaCarouselYouTubePlayerViewController *)viewController webView:(WKWebView *)webView didReceiveTapWithGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer;
- (void)carouselYouTubePlayerViewController:(MUKMediaCarouselYouTubePlayerViewController *)viewController didFinishLoadingWebView:(WKWebView *)webView error:(NSError *)error;
@end


@interface MUKMediaCarouselYouTubePlayerViewController : MUKMediaCarouselPlayerViewController
@property (nonatomic, weak) id<MUKMediaCarouselYouTubePlayerViewControllerDelegate> delegate;

- (void)setYouTubeURL:(NSURL *)youTubeURL;
@end
