#import "MUKMediaImageScrollView.h"

@interface MUKMediaImageScrollView () <UIScrollViewDelegate>
@property (nonatomic, readwrite) UITapGestureRecognizer *tapGestureRecognizer, *doubleTapGestureRecognizer;

@property (nonatomic) UIImageView *zoomView;
@property (nonatomic) CGSize imageSize;
@property (nonatomic) CGPoint pointToCenterAfterResize;
@property (nonatomic) CGFloat scaleToRestoreAfterResize;
@end

@implementation MUKMediaImageScrollView
@dynamic image;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CommonInitialization(self);
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        CommonInitialization(self);
    }
    
    return self;
}

#pragma mark - Overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.zoomView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }
    else {
        frameToCenter.origin.x = 0.0f;
    }
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    }
    else {
        frameToCenter.origin.y = 0.0f;
    }
    
    self.zoomView.frame = frameToCenter;
}

- (void)setFrame:(CGRect)frame {
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    if (sizeChanging) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging) {
        [self recoverFromResizing];
    }
}

#pragma mark - Accessors 

- (void)setMaximumZoomFactor:(float)maximumZoomFactor {
    if (maximumZoomFactor != _maximumZoomFactor) {
        _maximumZoomFactor = maximumZoomFactor;
        [self setMaxMinZoomScalesForCurrentBounds];
    }
}

#pragma mark - Methods

- (void)displayImage:(UIImage *)image {
    // clear the previous image
    [self.zoomView removeFromSuperview];
    
    // reset our zoomScale to 1.0 before doing any further calculations
    self.zoomScale = 1.0;
    
    // make a new UIImageView for the new image
    self.zoomView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:self.zoomView];
    
    [self configureForImageSize:image.size];
}

- (UIImage *)image {
    return self.zoomView.image;
}

#pragma mark - Private

static void CommonInitialization(MUKMediaImageScrollView *view) {
    view.maximumZoomFactor = 3.0f;
    view.doubleTapZoomFactor = 2.0f;
    
    view.showsVerticalScrollIndicator = NO;
    view.showsHorizontalScrollIndicator = NO;
    view.bouncesZoom = YES;
    view.decelerationRate = UIScrollViewDecelerationRateFast;
    view.delegate = view;
    
    [view setupGestureRecognizers];
}

#pragma mark - Private — Layout

- (void)configureForImageSize:(CGSize)imageSize {
    self.imageSize = imageSize;
    self.contentSize = imageSize;
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    CGSize boundsSize = self.bounds.size;
    
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width  / self.imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / self.imageSize.height;   // the scale needed to perfectly fit the image height-wise

    CGFloat minScale = MIN(xScale, yScale);
    CGFloat maxScale = minScale * self.maximumZoomFactor;
    
    // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
    if (minScale > maxScale) {
        minScale = maxScale;
    }
    
    self.minimumZoomScale = minScale;
    self.maximumZoomScale = maxScale;
}

#pragma mark - Private: Resizing Support

- (void)prepareToResize {
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.pointToCenterAfterResize = [self convertPoint:boundsCenter toView:self.zoomView];
    
    self.scaleToRestoreAfterResize = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which
    // will be converted to the minimum allowable scale when the scale is restored.
    if (self.scaleToRestoreAfterResize <= self.minimumZoomScale + FLT_EPSILON) {
        self.scaleToRestoreAfterResize = 0.0f;
    }
}

- (void)recoverFromResizing {
    [self setMaxMinZoomScalesForCurrentBounds];
    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, self.scaleToRestoreAfterResize);
    self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:self.pointToCenterAfterResize fromView:self.zoomView];
    
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0f,
                                 boundsCenter.y - self.bounds.size.height / 2.0f);
    
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    
    CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
    offset.x = MAX(minOffset.x, realMaxOffset);
    
    realMaxOffset = MIN(maxOffset.y, offset.y);
    offset.y = MAX(minOffset.y, realMaxOffset);
    
    self.contentOffset = offset;
}

- (CGPoint)maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset {
    return CGPointZero;
}

#pragma mark - Private — Zoom

- (void)zoomToPoint:(CGPoint)point animated:(BOOL)animated {
    CGFloat newZoomScale = self.zoomScale * self.doubleTapZoomFactor;
    newZoomScale = MIN(newZoomScale, self.maximumZoomScale);
    
    CGSize scrollViewSize = self.bounds.size;
    
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = point.x - (w / 2.0f);
    CGFloat y = point.y - (h / 2.0f);
    
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    [self zoomToRect:rectToZoomTo animated:animated];
}

#pragma mark - Private — Gestures

- (void)setupGestureRecognizers {
    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [self.doubleTapGestureRecognizer setNumberOfTapsRequired:2];
    [self addGestureRecognizer:self.doubleTapGestureRecognizer];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.tapGestureRecognizer requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];
    [self addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.imageDelegate respondsToSelector:@selector(imageScrollView:didReceiveTaps:withGestureRecognizer:)])
        {
            [self.imageDelegate imageScrollView:self didReceiveTaps:1 withGestureRecognizer:recognizer];
        }
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // Zoom to point in not already zoomed in
        // Otherwise zoom back
        if (self.zoomScale > self.minimumZoomScale) {
            [self setZoomScale:self.minimumZoomScale animated:YES];
        }
        else {
            CGPoint pointInView = [recognizer locationInView:self.zoomView];
            [self zoomToPoint:pointInView animated:YES];
        }
        
        // Inform delegate
        if ([self.imageDelegate respondsToSelector:@selector(imageScrollView:didReceiveTaps:withGestureRecognizer:)])
        {
            [self.imageDelegate imageScrollView:self didReceiveTaps:2 withGestureRecognizer:recognizer];
        }
    }
}

#pragma mark - <UIScrollViewDelegate>

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.zoomView;
}

@end
