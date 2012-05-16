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

#import "MUKMediaCarouselPlayerCellView_.h"
#import <MUKToolkit/MUKToolkit.h>

@interface MUKMediaCarouselPlayerCellView_ ()
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer_;

@property (nonatomic) MUKMediaAssetKind lastKind_;

- (CGRect)playerFrameForKind_:(MUKMediaAssetKind)kind;
- (MPMovieSourceType)movieSourceTypeFromMediaURL_:(NSURL *)mediaURL;
@end

@interface MUKMediaCarouselPlayerCellView_ (LocalGestures_)
- (void)handlePinch_:(UIPinchGestureRecognizer *)recognizer;
@end

@implementation MUKMediaCarouselPlayerCellView_ {
    BOOL replicatingTouch_;
}
@synthesize moviePlayer = moviePlayer_;
@synthesize lastKind_ = lastKind__;
@synthesize pinchGestureRecognizer_ = pinchGestureRecognizer__;
@synthesize hacksTouchesManagement = hacksTouchesManagement_;

- (id)initWithFrame:(CGRect)frame recycleIdentifier:(NSString *)recycleIdentifier
{
    self = [super initWithFrame:frame recycleIdentifier:recycleIdentifier];
    
    if (self) {
        hacksTouchesManagement_ = YES;
        self.pinchGestureRecognizer_ = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch_:)];
        [self addGestureRecognizer:self.pinchGestureRecognizer_];
    }
    
    return self;
}

- (void)setMediaURL:(NSURL *)mediaURL kind:(MUKMediaAssetKind)kind {
    if (mediaURL == nil) return;
    
    self.lastKind_ = kind;
    
    if (moviePlayer_ == nil) {
        moviePlayer_ = [[MPMoviePlayerController alloc] initWithContentURL:mediaURL];
        moviePlayer_.shouldAutoplay = NO;
        moviePlayer_.controlStyle = MPMovieControlStyleEmbedded;
        
        moviePlayer_.view.clipsToBounds = NO;
        moviePlayer_.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        [self insertSubview:moviePlayer_.view belowSubview:self.overlayView];
    }
    else {
        if (![self.moviePlayer.contentURL isEqual:mediaURL]) {
            // Prevent reloading
            self.moviePlayer.contentURL = mediaURL;
        }
    }
    
    self.moviePlayer.view.frame = [self playerFrameForKind_:kind];
    self.moviePlayer.movieSourceType = [self movieSourceTypeFromMediaURL_:mediaURL];
    
    [self.moviePlayer prepareToPlay];
}

- (void)cleanup {
    self.lastKind_ = MUKMediaAssetKindNone;
    
    [self.moviePlayer stop];
    [self.moviePlayer.view removeFromSuperview];
    self.moviePlayer = nil;
}

- (void)setInsets:(UIEdgeInsets)insets {
    [super setInsets:insets];
    
    self.moviePlayer.view.frame = [self playerFrameForKind_:self.lastKind_];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view;
    
    if (self.hacksTouchesManagement) {
        if (self.lastKind_ == MUKMediaAssetKindAudio) {
            view = [super hitTest:point withEvent:event];
        }
        else {
            // Pass touches to movie player only on the bottom
            static CGFloat const kControlsHeight = 40.0f;
            
            if (point.y > self.bounds.size.height - kControlsHeight)
            {
                view = [super hitTest:point withEvent:event];
            }
            else {
                view = self;
            }
        }
    }
    else {
        view = [super hitTest:point withEvent:event];
    }
    
    return view;
}

- (CGRect)captionLabelContainerFrameWithText:(NSString *)text
{
    CGRect frame = [super captionLabelContainerFrameWithText:text];
    
    // Put on top not to cover movie player commands
    frame.origin = CGPointZero;
    
    return frame;
}

- (UIViewAutoresizing)captionLabelContainerAutoresizingMask {
    return UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
}

//  Can't toggle programmatically commands
//
//- (void)reactToCellTap {
//    MPMovieControlStyle mode = self.moviePlayer.controlStyle;
//    
//    // Toggle embedded <--> none
//    if (mode == MPMovieControlStyleNone) {
//        mode = MPMovieControlStyleEmbedded;
//    }
//    else {
//        mode = MPMovieControlStyleNone;
//    }
//    
//    self.moviePlayer.controlStyle = mode;
//}

#pragma mark - Private

- (CGRect)playerFrameForKind_:(MUKMediaAssetKind)kind {
    CGRect frame = UIEdgeInsetsInsetRect(self.bounds, self.insets);
    /*
     If it's an audio player reduce frame.
     Audio player capture touches and a full frame disable
     carousel scrolling
     */
    if (MUKMediaAssetKindAudio == kind) {
        static CGFloat const kPlayerHeight = 40.0f;
        CGFloat diff = frame.size.height - kPlayerHeight;
        frame = CGRectInset(frame, 0.0f, diff/2);
    }
    
    return frame;
}

- (MPMovieSourceType)movieSourceTypeFromMediaURL_:(NSURL *)mediaURL
{
    if ([mediaURL isFileURL]) {
        return MPMovieSourceTypeFile;
    }
    
    return MPMovieSourceTypeUnknown; // downloadable or streaming?
}  

#pragma mark - Private: Local Gestures

- (void)handlePinch_:(UIPinchGestureRecognizer *)recognizer {
    if (self.hacksTouchesManagement) {
        if (self.lastKind_ != MUKMediaAssetKindAudio) {
            [self.moviePlayer setFullscreen:YES animated:YES];
        }
    }
}

@end
