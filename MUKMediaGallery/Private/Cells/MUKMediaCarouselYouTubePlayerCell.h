#import "MUKMediaCarouselPlayerCell.h"

@class MUKMediaCarouselYouTubePlayerCell;
@protocol MUKMediaCarouselYouTubePlayerCellDelegate <MUKMediaCarouselPlayerCellDelegate>
- (void)carouselYouTubePlayerCell:(MUKMediaCarouselYouTubePlayerCell *)cell webView:(UIWebView *)webView didReceiveTapWithGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer;
@end

@interface MUKMediaCarouselYouTubePlayerCell : MUKMediaCarouselPlayerCell
@property (nonatomic, weak) id<MUKMediaCarouselYouTubePlayerCellDelegate> delegate;

- (void)setYouTubeURL:(NSURL *)youTubeURL;
@end
