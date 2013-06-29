#import <UIKit/UIKit.h>

@interface MUKMediaCarouselCell : UICollectionViewCell
@property (nonatomic, weak, readonly) UIView *overlayView;
@property (nonatomic, weak, readonly) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak, readonly) UILabel *captionLabel;
@property (nonatomic, weak, readonly) UIView *captionBackgroundView;
@end

@interface MUKMediaCarouselCell (Caption)
- (void)setCaptionHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completionHandler;
@end
