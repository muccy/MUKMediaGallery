#import "MUKMediaGallerySlider.h"

@implementation MUKMediaGallerySlider

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
    CGRect thumbRect = [super thumbRectForBounds:bounds trackRect:rect value:value];
    return CGRectOffset(thumbRect, self.thumbOffset.width, self.thumbOffset.height);
}

@end
