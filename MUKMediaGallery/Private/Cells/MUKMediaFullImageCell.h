#import <UIKit/UIKit.h>
#import <MUKMediaGallery/MUKMediaImageKind.h>

@interface MUKMediaFullImageCell : UICollectionViewCell
@property (nonatomic, weak, readonly) UIImageView *imageView;
@property (nonatomic, readonly) MUKMediaImageKind imageKind;

- (void)setImage:(UIImage *)image ofKind:(MUKMediaImageKind)kind;
@end
