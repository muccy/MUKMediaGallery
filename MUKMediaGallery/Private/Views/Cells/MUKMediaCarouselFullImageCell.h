#import "MUKMediaCarouselCell.h"
#import "MUKMediaImageKind.h"

@class MUKMediaImageScrollView;
@class MUKMediaCarouselFullImageCell;
@protocol MUKMediaCarouselFullImageCellDelegate <NSObject>
- (void)carouselFullImageCell:(MUKMediaCarouselFullImageCell *)cell imageScrollViewDidReceiveTapWithGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer;
@end

@interface MUKMediaCarouselFullImageCell : MUKMediaCarouselCell
@property (nonatomic, weak) id<MUKMediaCarouselFullImageCellDelegate>delegate;

@property (nonatomic, weak, readonly) MUKMediaImageScrollView *imageScrollView;
@property (nonatomic, readonly) MUKMediaImageKind imageKind;

- (void)setImage:(UIImage *)image ofKind:(MUKMediaImageKind)kind;
@end
