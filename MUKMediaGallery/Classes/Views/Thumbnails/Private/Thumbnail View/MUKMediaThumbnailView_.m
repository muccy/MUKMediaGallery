//
//  MUKMediaThumbnailView_.m
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 28/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKMediaThumbnailView_.h"
#import <QuartzCore/QuartzCore.h>

@interface MUKMediaThumbnailView_ ()
- (CGRect)imageViewFrame_;
@end

@implementation MUKMediaThumbnailView_ {
    BOOL imageViewSetUp_;
}
@synthesize imageView = imageView_, mediaKindImageView = mediaKindImageView_;
@synthesize bottomView = bottomView_;
@synthesize durationLabel = durationLabel_;
@synthesize imageOffset = imageOffset_;
@synthesize mediaAsset = mediaAsset_;


- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (imageViewSetUp_ == NO) {        
        self.imageView.layer.borderWidth = 1.0f;
        self.imageView.layer.borderColor = [UIColor colorWithWhite:0.9f alpha:0.3f].CGColor;
        
        self.imageView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        
        imageViewSetUp_ = YES;
    }
}


#pragma mark - Accessors

- (void)setImageOffset:(CGSize)imageOffset {
    if (!CGSizeEqualToSize(imageOffset, imageOffset_)) {
        imageOffset_ = imageOffset;
        
        CGRect imageFrame = [self imageViewFrame_];
        if (!CGRectEqualToRect(imageFrame, self.imageView.frame)) {
            self.imageView.frame = imageFrame;
        }
    }
}

#pragma mark - Private

- (CGRect)imageViewFrame_ {    
    CGRect rect = self.bounds;
    rect.origin.x += self.imageOffset.width;
    rect.origin.y += self.imageOffset.height;
    rect.size.width -= self.imageOffset.width;
    rect.size.height -= self.imageOffset.width;
    return rect;
}


@end
