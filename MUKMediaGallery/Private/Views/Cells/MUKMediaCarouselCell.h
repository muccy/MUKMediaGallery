#import <UIKit/UIKit.h>

@interface MUKMediaCarouselCell : UICollectionViewCell
@property (nonatomic, weak, readonly) UIView *overlayView;
@property (nonatomic, weak, readonly) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak, readonly) UILabel *captionLabel;
@property (nonatomic, weak, readonly) UIView *captionBackgroundView;
@property (nonatomic, weak, readonly) UIImageView *thumbnailImageView;

@end

@interface MUKMediaCarouselCell (Caption)
- (BOOL)isCaptionHidden;
- (void)setCaptionHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completionHandler;
@end


@interface MUKMediaCarouselCell (Thumbnail)
- (void)createThumbnailImageViewIfNeededInSuperview:(UIView *)superview belowSubview:(UIView *)subview;
@end
