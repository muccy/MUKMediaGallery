#import "MUKMediaGalleryImageResizeOperation.h"
#import <MUKToolkit/MUK+Geometry.h>

@interface MUKMediaGalleryImageResizeOperation ()
@property (nonatomic, readwrite) UIImage *resizedImage;
@end

@implementation MUKMediaGalleryImageResizeOperation

- (void)main {
    if ([self isCancelled] || self.sourceImage == nil || CGSizeEqualToSize(self.boundingSize, CGSizeZero))
    {
        return;
    }
    
    // Calculate max size
    CGRect imageRect = CGRectZero;
    imageRect.size = self.sourceImage.size;

    CGRect boundingRect = CGRectZero;
    boundingRect.size = self.boundingSize;
    
    imageRect = [MUK rect:imageRect transform:MUKGeometryTransformScaleAspectFill respectToRect:boundingRect];
    
    if ([self isCancelled]) {
        return;
    }
    
    UIGraphicsBeginImageContextWithOptions(self.boundingSize, NO, 0.0f);
    
    // Draw image 
    [self.sourceImage drawInRect:imageRect];
    
    // Delegate could draw over image
    if (![self isCancelled] && [self.drawingDelegate respondsToSelector:@selector(imageResizeOperation:drawOverResizedImageInContext:)])
    {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [self.drawingDelegate imageResizeOperation:self drawOverResizedImageInContext:ctx];
    }
    
    // Capture composed image
    self.resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}

@end
