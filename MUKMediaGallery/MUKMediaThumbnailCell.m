#import "MUKMediaThumbnailCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation MUKMediaThumbnailCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:imageView];
        self.imageView = imageView;
        
        CGFloat const border = 1.0f;
        CGRect rect = CGRectInset(imageView.frame, border, border);
        UIView *borderView = [[UIView alloc] initWithFrame:imageView.frame];
        borderView.autoresizingMask = imageView.autoresizingMask;
        borderView.userInteractionEnabled = NO;
        borderView.backgroundColor = [UIColor clearColor];
        borderView.layer.borderWidth = border;
        borderView.layer.borderColor = [UIColor colorWithWhite:0.0f alpha:0.05f].CGColor;
        [self.contentView addSubview:borderView];
    }
    return self;
}

@end
