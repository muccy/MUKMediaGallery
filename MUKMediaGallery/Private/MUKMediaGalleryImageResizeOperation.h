#import <Foundation/Foundation.h>

@class MUKMediaGalleryImageResizeOperation;
@protocol MUKMediaGalleryImageResizeOperationDrawingDelegate <NSObject>
@required
- (void)imageResizeOperation:(MUKMediaGalleryImageResizeOperation *)op drawOverResizedImageInContext:(CGContextRef)ctx;
@end

@interface MUKMediaGalleryImageResizeOperation : NSOperation
// Input
@property (nonatomic) UIImage *sourceImage;
@property (nonatomic) CGSize boundingSize;
@property (nonatomic) id userInfo;
@property (nonatomic, weak) id<MUKMediaGalleryImageResizeOperationDrawingDelegate> drawingDelegate;

// Output
@property (nonatomic, readonly) UIImage *resizedImage;
@end
