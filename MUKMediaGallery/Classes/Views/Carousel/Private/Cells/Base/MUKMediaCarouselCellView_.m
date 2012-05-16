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

#import "MUKMediaCarouselCellView_.h"
#import <MUKToolkit/MUKToolkit.h>

@implementation MUKMediaCarouselCellView_ {
    BOOL needsToCenterImage_;
    BOOL overlayViewHidden_;
}
@synthesize imageView = imageView_;
@synthesize activityIndicator = activityIndicator_;
@synthesize overlayView = overlayView_;
@synthesize insets = insets_, overlayViewInsets = overlayViewInsets_;
@synthesize mediaAsset = mediaAsset_;

- (id)initWithFrame:(CGRect)frame recycleIdentifier:(NSString *)recycleIdentifier
{
    self = [super initWithFrame:frame recycleIdentifier:recycleIdentifier];
    
    if (self) {
        // Create image view
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.imageView];
        
        // Create overlay
        self.overlayView = [[UIView alloc] initWithFrame:[self overlayViewFrame]];
        self.overlayView.backgroundColor = [UIColor clearColor];
        self.overlayView.userInteractionEnabled = NO;
        self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.overlayView];
        
        // Create spinner
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activityIndicator.hidesWhenStopped = YES;
        [self.activityIndicator stopAnimating];
        
        // Keep centered
        CGRect activityIndicatorFrame = [MUK rect:self.activityIndicator.frame transform:MUKGeometryTransformCenter respectToRect:self.bounds];
        self.activityIndicator.frame = activityIndicatorFrame;
        self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        
        [self addSubview:self.activityIndicator];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (needsToCenterImage_) {
        needsToCenterImage_ = NO;
        [self centerImage];
    }
}

#pragma mark - Methods

- (void)setCenteredImage:(UIImage *)image {
    self.imageView.image = image;
    [self setNeedsImageCentering];
}

- (void)setNeedsImageCentering {
    needsToCenterImage_ = YES;
    [self setNeedsLayout];
}

- (CGRect)centeredImageFrame {
    CGRect imageRect = CGRectZero;
    imageRect.size = self.imageView.image.size;    
    
    if (CGRectEqualToRect(imageRect, CGRectZero)) {
        return CGRectZero;
    }
    
    CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, self.insets);
    
    CGRect fittedRect = [MUK rect:imageRect transform:MUKGeometryTransformScaleAspectFit respectToRect:bounds];
    return fittedRect;
}

- (void)centerImage {
    self.imageView.frame = [self centeredImageFrame];
}

#pragma mark - Overlay view

- (CGRect)overlayViewFrame {
    return UIEdgeInsetsInsetRect(self.bounds, self.overlayViewInsets);
}

- (void)setOverlayViewInsets:(UIEdgeInsets)insets animated:(BOOL)animated
{
    if (!UIEdgeInsetsEqualToEdgeInsets(insets, overlayViewInsets_)) {
        overlayViewInsets_ = insets;
        
        // Update overlay view frame
        [UIView animateWithDuration:(animated ? 0.3f : 0.0f)
                              delay:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.overlayView.frame = [self overlayViewFrame];
                         } 
                         completion:nil];
    }
}

- (BOOL)isOverlayViewHidden {
    return overlayViewHidden_;
}

- (void)setOverlayViewHidden:(BOOL)hidden animated:(BOOL)animated
{
    overlayViewHidden_ = hidden;
        
    [UIView animateWithDuration:(animated ? 0.3f : 0.0f)
                          delay:0.0f
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.overlayView.alpha = (hidden ? 0.0f : 1.0f);
                     } 
                     completion:nil];
}

@end
