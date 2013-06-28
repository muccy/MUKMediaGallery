#import "MUKMediaCarouselCell.h"
#import "MUKMediaImageKind.h"

@interface MUKMediaCarouselFullImageCell : MUKMediaCarouselCell
@property (nonatomic, weak, readonly) UIImageView *imageView;
@property (nonatomic, readonly) MUKMediaImageKind imageKind;

- (void)setImage:(UIImage *)image ofKind:(MUKMediaImageKind)kind;
@end
