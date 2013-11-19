#import "MUKMediaCarouselItemViewController.h"
#import "MUKMediaImageKind.h"

@class MUKMediaImageScrollView;
@class MUKMediaCarouselFullImageViewController;
@protocol MUKMediaCarouselFullImageViewControllerDelegate <MUKMediaCarouselItemViewControllerDelegate>
- (void)carouselFullImageViewController:(MUKMediaCarouselFullImageViewController *)viewController imageScrollViewDidReceiveTapWithGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer;
@end


@interface MUKMediaCarouselFullImageViewController : MUKMediaCarouselItemViewController
@property (nonatomic, weak) id<MUKMediaCarouselFullImageViewControllerDelegate>delegate;

@property (nonatomic, weak, readonly) MUKMediaImageScrollView *imageScrollView;
@property (nonatomic, readonly) MUKMediaImageKind imageKind;

- (void)setImage:(UIImage *)image ofKind:(MUKMediaImageKind)kind;
@end
