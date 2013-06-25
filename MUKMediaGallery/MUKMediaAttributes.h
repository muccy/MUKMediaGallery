#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MUKMediaKind) {
    MUKMediaKindImage = 0,
    MUKMediaKindAudio,
    MUKMediaKindVideo,
    MUKMediaKindYouTubeVideo
};

@interface MUKMediaAttributes : NSObject
@property (nonatomic) MUKMediaKind kind;
@property (nonatomic, copy) NSString *caption;

- (instancetype)initWithKind:(MUKMediaKind)kind;

@end