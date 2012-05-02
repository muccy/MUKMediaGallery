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

@implementation MUKMediaThumbnailView_
@synthesize imageView = imageView_, mediaKindImageView = mediaKindImageView_;
@synthesize bottomView = bottomView_;
@synthesize durationLabel = durationLabel_;
@synthesize imageOffset = imageOffset_;

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.imageView.layer.borderWidth = 1.0f;
        self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    }
    return self;
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
