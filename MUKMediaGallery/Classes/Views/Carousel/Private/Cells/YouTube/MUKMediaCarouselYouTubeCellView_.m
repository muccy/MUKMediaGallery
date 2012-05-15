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

#import "MUKMediaCarouselYouTubeCellView_.h"

@interface MUKMediaCarouselYouTubeCellView_ ()
- (CGRect)youTubeFrame_;
@end

@implementation MUKMediaCarouselYouTubeCellView_ {
    CGRect lastYouTubeFrame_;
    BOOL usingWebView_;
    NSURL *lastURL_;
}
@synthesize webView = webView_;

- (id)initWithFrame:(CGRect)frame recycleIdentifier:(NSString *)recycleIdentifier 
{
    self = [super initWithFrame:frame recycleIdentifier:recycleIdentifier];
    
    if (self) {
        lastYouTubeFrame_ = [self youTubeFrame_];
    }
    
    return self;
}

#pragma mark - Overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /*
     Do the best to resize web view embed
     */
    if (usingWebView_) {
        // Using web view
        
        CGRect currentYouTubeFrame = [self youTubeFrame_];
        if (!CGRectEqualToRect(lastYouTubeFrame_, currentYouTubeFrame))
        {
            // Frame changed
            lastYouTubeFrame_ = currentYouTubeFrame;
            
            static NSString *const kJSCommandMask = @"\
                (function (width, height) {\
                    var embed = document.getElementsByTagName('embed')[0];\
                    embed.width = width;\
                    embed.height = height;\
                })(%.0f, %.0f);\
            ";
            
            NSString *command = [[NSString alloc] initWithFormat:kJSCommandMask, currentYouTubeFrame.size.width, currentYouTubeFrame.size.height];
            [self.webView stringByEvaluatingJavaScriptFromString:command];
        }
    }
}

- (void)setInsets:(UIEdgeInsets)insets {
    [super setInsets:insets];
    
    if (usingWebView_) {
        self.webView.frame = [self youTubeFrame_];
        [self setNeedsLayout];
    }
}

- (void)cleanup {
    [super cleanup];
    
    usingWebView_ = NO;
    lastYouTubeFrame_ = CGRectZero;
    lastURL_ = nil;
    
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
    [self.webView removeFromSuperview];
    self.webView = nil;
}

#pragma mark - Methods

- (void)setMediaURL:(NSURL *)mediaURL inWebView:(BOOL)useWebView {
    if (mediaURL == nil) return;
    
    usingWebView_ = useWebView;
    
    if (!useWebView) {
        // Play asset in movie player
        self.hacksTouchesManagement = YES;
        [super setMediaURL:mediaURL kind:MUKMediaAssetKindYouTubeVideo];
        
        [self.webView removeFromSuperview];
        self.webView = nil;
    }
    else {
        // Play asset in web view
        self.hacksTouchesManagement = NO;
        
        if (![lastURL_ isEqual:mediaURL]) {
            // Prevent reloading
                
            CGRect frame = [self youTubeFrame_];
            
            if (webView_ == nil) {
                // Create web view
                webView_ = [[UIWebView alloc] initWithFrame:frame];
                webView_.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
                webView_.opaque = NO;
                webView_.backgroundColor = [UIColor clearColor];
                
                // Dismiss movie player
                [self.moviePlayer.view removeFromSuperview];
                self.moviePlayer = nil;
                
                // Insert web view
                [self insertSubview:webView_ belowSubview:self.activityIndicator];
            }
            else {
                self.webView.frame = frame;
            }
            
            lastYouTubeFrame_ = frame;
            
            // Dismiss thumbnail
            self.imageView.image = nil;
            
            // Load YouTube in embed
            static NSString *const kEmbedHTMLMask = @"<html><head><style type=\"text/css\"> \
            body {background-color:transparent;color:white;}</style> \
            </head><body style=\"margin:0\"> \
            <embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \
            width=\"%0.0f\" height=\"%0.0f\"></embed></body></html>";
            NSString *html = [[NSString alloc] initWithFormat:kEmbedHTMLMask, [mediaURL absoluteString], frame.size.width, frame.size.height]; 
            [self.webView loadHTMLString:html baseURL:nil];
        }
    }
    
    lastURL_ = mediaURL;
}

#pragma mark - Private

- (CGRect)youTubeFrame_ {
    return UIEdgeInsetsInsetRect(self.bounds, self.insets);
}

@end
