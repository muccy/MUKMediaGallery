#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MUKMediaKind) {
    MUKMediaKindImage = 0,
    MUKMediaKindAudio,
    MUKMediaKindVideo,
    MUKMediaKindYouTubeVideo
};

/**
 Additional infos about a media item.
 */
@interface MUKMediaAttributes : NSObject
/**
 Kind of media.
 
 It could be an image (default), an audio, a video or a YouTube video (see MUKMediaKind
 enumeration).
 */
@property (nonatomic) MUKMediaKind kind;
/**
 Caption to show with a media item.
 
 In MUKMediaThumbnailsViewController caption should be short, like video duration.
 In MUKMediaCarouselViewController caption could be longer, like description of
 an image.
 */
@property (nonatomic, copy) NSString *caption;

/**
 Default initializer.
 
 @param kind Kind of media to initialize.
 @return A new instance.
 */
- (instancetype)initWithKind:(MUKMediaKind)kind;

/**
 Utility method to set caption formatting a time inteval.
 
 @param interval Time interval to format in `HH:mm:ss`.
 */
- (void)setCaptionWithTimeInterval:(NSTimeInterval)interval;

@end