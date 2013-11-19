#import "MUKMediaCarouselFullImageViewController.h"
#import "MUKMediaImageScrollView.h"

@interface MUKMediaCarouselFullImageViewController () <MUKMediaImageScrollViewDelegate>
@property (nonatomic, weak, readwrite) MUKMediaImageScrollView *imageScrollView;
@property (nonatomic, readwrite) MUKMediaImageKind imageKind;
@end

@implementation MUKMediaCarouselFullImageViewController

- (instancetype)initWithMediaIndex:(NSInteger)idx {
    self = [super initWithMediaIndex:idx];
    if (self) {
        _imageKind = MUKMediaImageKindNone;
    }
    
    return self;
}

#pragma mark - Methods

- (void)setImage:(UIImage *)image ofKind:(MUKMediaImageKind)kind {
    switch (kind) {
        case MUKMediaImageKindFullSize: {
            // Create scroll view if needed
            if (self.imageScrollView == nil) {
                MUKMediaImageScrollView *imageScrollView = [[MUKMediaImageScrollView alloc] initWithFrame:self.view.bounds];
                imageScrollView.imageDelegate = self;
                imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
                [self.view insertSubview:imageScrollView belowSubview:self.overlayView];
                self.imageScrollView = imageScrollView;
            }
            
            // Remove thumbnail
            self.thumbnailImageView.image = nil;
            
            // Display image
            [self.imageScrollView displayImage:image];
            
            break;
        }
            
        case MUKMediaImageKindThumbnail: {
            // Remove full image
            [self.imageScrollView removeFromSuperview];
            
            // Display image
            [self createThumbnailImageViewIfNeededInSuperview:self.view belowSubview:self.overlayView];
            self.thumbnailImageView.image = image;
            
            break;
        }
            
        default: {
            // Remove all
            [self.imageScrollView removeFromSuperview];
            self.thumbnailImageView.image = nil;
            break;
        }
    }
    
    self.imageKind = kind;
}

#pragma mark - <MUKMediaImageScrollViewDelegate>

- (void)imageScrollView:(MUKMediaImageScrollView *)imageScrollView didReceiveTaps:(NSInteger)tapCount withGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer
{
    if (tapCount == 1) {
        [self.delegate carouselFullImageViewController:self imageScrollViewDidReceiveTapWithGestureRecognizer:gestureRecognizer];
    }
}

@end
