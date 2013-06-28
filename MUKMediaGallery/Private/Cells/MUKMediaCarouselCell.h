#import <UIKit/UIKit.h>

@interface MUKMediaCarouselCell : UICollectionViewCell
@property (nonatomic, weak, readonly) UIView *overlayView;
@property (nonatomic, weak, readonly) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak, readonly) UILabel *captionLabel;
@property (nonatomic, weak, readonly) UIView *captionBackgroundView;

- (void)setCaption:(NSString *)caption;
@end
