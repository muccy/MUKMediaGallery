#import <UIKit/UIKit.h>

@interface MUKMediaThumbnailCell : UICollectionViewCell
@property (nonatomic, weak, readonly) UIImageView *imageView;
@property (nonatomic, weak, readonly) UIView *bottomView;
@property (nonatomic, weak, readonly) UIImageView *bottomIconImageView;
@property (nonatomic, weak, readonly) UILabel *captionLabel;

+ (void)drawBorderInsideRect:(CGRect)rect context:(CGContextRef)ctx;
@end
