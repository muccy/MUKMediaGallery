#import "MUKMediaCarouselCell.h"
#import <MediaPlayer/MediaPlayer.h>

@class MUKMediaCarouselPlayerCell;
@protocol MUKMediaCarouselPlayerCellDelegate <NSObject>
- (void)carouselPlayerCellDidChangeNowPlayingMovie:(MUKMediaCarouselPlayerCell *)cell;
- (void)carouselPlayerCellDidChangePlaybackState:(MUKMediaCarouselPlayerCell *)cell;
@end

@interface MUKMediaCarouselPlayerCell : MUKMediaCarouselCell
@property (nonatomic, weak) id<MUKMediaCarouselPlayerCellDelegate> delegate;
@property (nonatomic, readonly) MPMoviePlayerController *moviePlayerController;

- (void)setMediaURL:(NSURL *)mediaURL;
- (void)setPlayerControlsHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completionHandler;
@end
