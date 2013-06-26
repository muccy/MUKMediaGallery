#import <Foundation/Foundation.h>

@interface MUKMediaGalleryImageResizeOperation : NSOperation
// Input
@property (nonatomic) UIImage *sourceImage;
@property (nonatomic) CGSize boundingSize;
@property (nonatomic) id userInfo;

// Output
@property (nonatomic, readonly) UIImage *resizedImage;
@end
