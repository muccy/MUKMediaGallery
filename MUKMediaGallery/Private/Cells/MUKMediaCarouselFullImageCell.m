#import "MUKMediaCarouselFullImageCell.h"

@interface MUKMediaCarouselFullImageCell ()
@property (nonatomic, readwrite) MUKMediaImageKind imageKind;
@end

@implementation MUKMediaCarouselFullImageCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageKind = MUKMediaImageKindNone;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.contentView insertSubview:imageView belowSubview:self.overlayView];
        _imageView = imageView;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark - Methods

- (void)setImage:(UIImage *)image ofKind:(MUKMediaImageKind)kind {
    self.imageView.image = image;
    self.imageKind = kind;
}

@end
