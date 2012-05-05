// Copyright (c) 2012, Marco Muccinelli
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
// * Neither the name of the <organization> nor the
// names of its contributors may be used to endorse or promote products
// derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "MUKMediaThumbnailView_.h"
#import <QuartzCore/QuartzCore.h>

@interface MUKMediaThumbnailView_ ()
- (CGRect)containerViewFrame_;
@end

@implementation MUKMediaThumbnailView_ {
    BOOL containerViewSetUp_;
}
@synthesize imageView = imageView_, mediaKindImageView = mediaKindImageView_;
@synthesize containerView = containerView_, bottomView = bottomView_;
@synthesize durationLabel = durationLabel_;
@synthesize imageOffset = imageOffset_;
@synthesize mediaAsset = mediaAsset_;


- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (containerViewSetUp_ == NO) {        
        self.containerView.layer.borderWidth = 1.0f;
        self.containerView.layer.borderColor = [UIColor colorWithWhite:0.9f alpha:0.3f].CGColor;
        
        self.containerView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        
        containerViewSetUp_ = YES;
    }
}


#pragma mark - Accessors

- (void)setImageOffset:(CGSize)imageOffset {
    if (!CGSizeEqualToSize(imageOffset, imageOffset_)) {
        imageOffset_ = imageOffset;
        
        CGRect containerFrame = [self containerViewFrame_];
        if (!CGRectEqualToRect(containerFrame, self.containerView.frame)) {
            self.containerView.frame = containerFrame;
        }
    }
}

#pragma mark - Private

- (CGRect)containerViewFrame_ {    
    CGRect rect = self.bounds;
    rect.origin.x += self.imageOffset.width;
    rect.origin.y += self.imageOffset.height;
    rect.size.width -= self.imageOffset.width;
    rect.size.height -= self.imageOffset.width;
    return rect;
}


@end
