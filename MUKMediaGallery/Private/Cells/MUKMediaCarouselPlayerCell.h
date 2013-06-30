#import "MUKMediaCarouselCell.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MUKMediaCarouselPlayerCell : MUKMediaCarouselCell
@property (nonatomic, readonly) MPMoviePlayerController *moviePlayerController;

- (void)setMediaURL:(NSURL *)mediaURL;



@end
