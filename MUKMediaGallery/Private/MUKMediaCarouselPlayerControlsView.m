#import "MUKMediaCarouselPlayerControlsView.h"
#import "MUKMediaGalleryToolbar.h"

static CGFloat const kToolbarHeight = 30.0f;

@interface MUKMediaCarouselPlayerControlsView () <UIToolbarDelegate>
@property (nonatomic, weak) UIView *backgroundView;
@end

@implementation MUKMediaCarouselPlayerControlsView

- (id)initWithFrame:(CGRect)frame
{
    frame.size.height = kToolbarHeight;
    
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        
        UIView *backgroundView = [self newBackgroundViewInSuperview:self];
        _backgroundView = backgroundView;
    }
    return self;
}

#pragma mark - Overrides

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.frame.size.height);
}

#pragma mark - Private

- (UIView *)newBackgroundViewInSuperview:(UIView *)superview {
    MUKMediaGalleryToolbar *toolbar = [[MUKMediaGalleryToolbar alloc] initWithFrame:superview.bounds];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.delegate = self;
    [superview addSubview:toolbar];

    return toolbar;
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionBottom;
}

@end
