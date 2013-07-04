#import "MUKMediaCarouselPlayerCell.h"

@class MUKMediaCarouselYouTubePlayerCell;
@protocol MUKMediaCarouselYouTubePlayerCellDelegate <MUKMediaCarouselPlayerCellDelegate>
- (void)carouselYouTubePlayerCell:(MUKMediaCarouselYouTubePlayerCell *)cell webView:(UIWebView *)webView didReceiveTapWithGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer;
- (void)carouselYouTubePlayerCell:(MUKMediaCarouselYouTubePlayerCell *)cell didFinishLoadingWebView:(UIWebView *)webView error:(NSError *)error;
@end

@interface MUKMediaCarouselYouTubePlayerCell : MUKMediaCarouselPlayerCell
@property (nonatomic, weak) id<MUKMediaCarouselYouTubePlayerCellDelegate> delegate;

- (void)setYouTubeURL:(NSURL *)youTubeURL;
@end
