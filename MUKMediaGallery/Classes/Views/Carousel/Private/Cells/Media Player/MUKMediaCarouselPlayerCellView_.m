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

#define TAP_MAX_DURATION        0.9f

@interface MUKMediaCarouselPlayerCellView_ ()
@property (nonatomic, strong) NSDate *touchesBeganDate_;
@property (nonatomic) BOOL touchesMoved_, touchesCancelled_;
@property (nonatomic) MUKMediaAssetKind lastKind_;

- (CGRect)playerFrameForKind_:(MUKMediaAssetKind)kind;
- (MPMovieSourceType)movieSourceTypeFromMediaURL_:(NSURL *)mediaURL;
@end

@implementation MUKMediaCarouselPlayerCellView_
@synthesize moviePlayer = moviePlayer_;
@synthesize tapHandler = tapHandler_;

@synthesize lastKind_ = lastKind__;
@synthesize touchesBeganDate_ = touchesBeganDate__;
@synthesize touchesMoved_ = touchesMoved__, touchesCancelled_ = touchesCancelled__;

#pragma mark - Accessors

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

- (void)setInsets:(UIEdgeInsets)insets {
    [super setInsets:insets];
    
    self.moviePlayer.view.frame = [self playerFrameForKind_:self.lastKind_];
}

#pragma mark - Methods

- (void)cleanup {
    self.lastKind_ = MUKMediaAssetKindNone;
    
    [self.moviePlayer stop];
    [self.moviePlayer.view removeFromSuperview];
    self.moviePlayer = nil;
    
    self.tapHandler = nil;
}

- (void)didTapCell {
    if (self.tapHandler) {
        self.tapHandler();
    }
}

#pragma mark - Touches Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {    
    if ([touches count] == 1) {
        self.touchesMoved_ = NO;
        self.touchesCancelled_ = NO;
        self.touchesBeganDate_ = [NSDate date];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self.touchesMoved_ = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {    
    if (self.touchesCancelled_ == NO &&
        self.touchesMoved_ == NO)
    {
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.touchesBeganDate_];
        
        if (interval < TAP_MAX_DURATION) {
            [self didTapCell];
        }
    }   
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.touchesCancelled_ = YES;
}

#pragma mark - Overrides

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

@end
