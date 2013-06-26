#import "MUKMediaThumbnailCell.h"
#import <QuartzCore/QuartzCore.h>

@interface MUKMediaThumbnailCell ()
@property (nonatomic, weak, readwrite) UIImageView *imageView;
@property (nonatomic, weak, readwrite) UIView *bottomView;
@property (nonatomic, weak, readwrite) UIImageView *bottomIconImageView;
@property (nonatomic, weak, readwrite) UILabel *captionLabel;
@end

@implementation MUKMediaThumbnailCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGRect rect = self.contentView.bounds;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeTopLeft;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        imageView.opaque = YES;
        [self.contentView addSubview:imageView];
        self.imageView = imageView;
        
        CGFloat const kBottomViewHeight = 17.0f;
        rect.origin.y = rect.size.height - kBottomViewHeight;
        rect.size.height = kBottomViewHeight;
        UIView *bottomView = [[UIView alloc] initWithFrame:rect];
        bottomView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
        bottomView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
        bottomView.userInteractionEnabled = NO;
        [self.contentView addSubview:bottomView];
        self.bottomView = bottomView;
        
        rect = bottomView.bounds;
        rect.origin.x = 6.0f;
        rect.size.width = 13.0f;
        UIImageView *bottomIconImageView = [[UIImageView alloc] initWithFrame:rect];
        bottomIconImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
        bottomIconImageView.contentMode = UIViewContentModeLeft;
        bottomIconImageView.backgroundColor = [UIColor clearColor];
        [bottomView addSubview:bottomIconImageView];
        self.bottomIconImageView = bottomIconImageView;
        
        rect = bottomView.bounds;
        rect.origin.x = CGRectGetMaxX(bottomIconImageView.frame) + 4.0f;
        rect.size.width -= rect.origin.x + 4.0f;
        UILabel *captionLabel = [[UILabel alloc] initWithFrame:rect];
        captionLabel.backgroundColor = [UIColor clearColor];
        captionLabel.textColor = [UIColor whiteColor];
        captionLabel.numberOfLines = 1;
        captionLabel.textAlignment = NSTextAlignmentRight;
        captionLabel.font = [UIFont boldSystemFontOfSize:11.0f];
        captionLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
        [bottomView addSubview:captionLabel];
        self.captionLabel = captionLabel;
    }
    
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.imageView.backgroundColor = backgroundColor;
}

- (void)drawRect:(CGRect)rect {
    // Draw border for empty cells
    // Borders for filled cells are drawn over resized thumbnails as a huge
    // optimization
    
    if (!self.imageView.image) {
        [[self class] drawBorderInsideRect:self.bounds context:UIGraphicsGetCurrentContext()];
    }
}

+ (void)drawBorderInsideRect:(CGRect)rect context:(CGContextRef)ctx {
    rect = CGRectInset(rect, 1.0f, 1.0f);
    
    CGContextSaveGState(ctx);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.0f alpha:0.05f].CGColor);
    CGContextStrokeRect(ctx, rect);
    CGContextRestoreGState(ctx);
}

@end
