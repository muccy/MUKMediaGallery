#import <UIKit/UIKit.h>

@class MUKMediaCarouselItemViewController;
@protocol MUKMediaCarouselItemViewControllerDelegate <NSObject>
- (void)carouselItemViewControllerDidReceiveTap:(MUKMediaCarouselItemViewController *)viewController;
@end

// A page of carousel
@interface MUKMediaCarouselItemViewController : UIViewController
@property (nonatomic, weak) id<MUKMediaCarouselItemViewControllerDelegate> delegate;
@property (nonatomic, readonly) NSInteger mediaIndex;
@property (nonatomic, weak, readonly) UIView *overlayView;
@property (nonatomic, weak, readonly) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak, readonly) UILabel *captionLabel;
@property (nonatomic, weak, readonly) UIView *captionBackgroundView;
@property (nonatomic, weak, readonly) UIImageView *thumbnailImageView;

- (instancetype)initWithMediaIndex:(NSInteger)idx;
@end


@interface MUKMediaCarouselItemViewController (Caption)
- (BOOL)isCaptionHidden;
- (void)setCaptionHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completionHandler;
@end


@interface MUKMediaCarouselItemViewController (Thumbnail)
- (void)createThumbnailImageViewIfNeededInSuperview:(UIView *)superview belowSubview:(UIView *)subview;
@end
