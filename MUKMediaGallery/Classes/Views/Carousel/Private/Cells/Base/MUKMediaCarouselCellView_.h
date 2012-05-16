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

#import <MUKScrolling/MUKScrolling.h>

@protocol MUKMediaAsset;
@interface MUKMediaCarouselCellView_ : MUKRecyclableView
/*
 Used for thumbnail
 */
@property (nonatomic, strong) UIImageView *imageView;
/*
 Spinner
 */
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
/*
 Overlay view (under the spinner)
 */
@property (nonatomic, strong) UIView *overlayView;
/*
 Caption label (into overlay view)
 */
@property (nonatomic, strong) UIView *captionLabelContainer;
@property (nonatomic, strong) UILabel *captionLabel;

@property (nonatomic) UIEdgeInsets insets;
@property (nonatomic, readonly) UIEdgeInsets overlayViewInsets;

@property (nonatomic, strong) id<MUKMediaAsset> mediaAsset;

/*
 Set image and calls setNeedsImageCentering
 */
- (void)setCenteredImage:(UIImage *)image;

/*
 Frame used to center image
 */
- (CGRect)centeredImageFrame;

/*
 Applies centeredImageFrame immediately
 */
- (void)centerImage;

/*
 Centers at next layout
 */
- (void)setNeedsImageCentering;

@end


@interface MUKMediaCarouselCellView_ (Overlay)
- (CGRect)overlayViewFrame;
- (void)setOverlayViewInsets:(UIEdgeInsets)insets animated:(BOOL)animated;

- (BOOL)isOverlayViewHidden;
- (void)setOverlayViewHidden:(BOOL)hidden animated:(BOOL)animated;
@end


@interface MUKMediaCarouselCellView_ (Caption)
- (CGRect)captionLabelContainerFrameWithText:(NSString *)text;
- (void)setCaptionText:(NSString *)text;
- (UIFont *)captionFont;
- (UILineBreakMode)captionLineBreakMode;
@end

