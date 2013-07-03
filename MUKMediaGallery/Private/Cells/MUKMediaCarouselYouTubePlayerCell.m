#import "MUKMediaCarouselYouTubePlayerCell.h"

@interface MUKMediaCarouselYouTubePlayerCell () <UIGestureRecognizerDelegate>
@property (nonatomic, weak, readwrite) UIWebView *webView;
@property (nonatomic) CGRect lastWebViewBounds;
@end

@implementation MUKMediaCarouselYouTubePlayerCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createThumbnailImageViewIfNeededInSuperview:self.contentView belowSubview:self.overlayView];
        _lastWebViewBounds = CGRectNull;
    }
    
    return self;
}

- (void)dealloc {
    [self disposeWebView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Do the best to resize web view embed
    if (self.webView.superview != nil) {
        if (!CGRectIsNull(self.lastWebViewBounds)) {
            if (!CGSizeEqualToSize(self.lastWebViewBounds.size, self.webView.bounds.size))
            {
                [self updateYouTubeEmbedInWebView:self.webView toSize:self.webView.bounds.size];
            }
        }
        
        self.lastWebViewBounds = self.webView.bounds;
    }
}

#pragma mark - Methods

- (void)setYouTubeURL:(NSURL *)youTubeURL {
    if (youTubeURL == nil) {
        [self disposeWebView];
        return;
    }
    
    // Create web view if needed
    if (self.webView == nil) {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:self.contentView.bounds];
        webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        webView.allowsInlineMediaPlayback = YES;
        webView.mediaPlaybackRequiresUserAction = YES;
        webView.opaque = NO;
        webView.backgroundColor = [UIColor clearColor];
        webView.multipleTouchEnabled = NO;

        [self.contentView insertSubview:webView belowSubview:self.overlayView];
        self.webView = webView;
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleWebViewTap:)];
        tapGestureRecognizer.delegate = self;
        [webView addGestureRecognizer:tapGestureRecognizer];
    }
    
    self.lastWebViewBounds = self.webView.bounds;
    
    // Remove thumbnail image
    self.thumbnailImageView.image = nil;
    
    // Load HTML embed
    NSString *html = [self youTubeEmbedForURL:youTubeURL size:self.contentView.bounds.size];
    [self.webView loadHTMLString:html baseURL:nil];
}

#pragma mark - Overrides

- (void)setMediaURL:(NSURL *)mediaURL {
    // Keep a strong reference to current thumbnail
    UIImage *thumbnail = self.thumbnailImageView.image;
    
    // This recreates thumnail image view in correct position
    [super setMediaURL:mediaURL];
    
    // Restore past thumbnail
    self.thumbnailImageView.image = thumbnail;
    
    // Remove web view
    [self disposeWebView];
}

#pragma mark - Private

- (void)disposeWebView {
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
    [self.webView removeFromSuperview];
    self.webView = nil;
}

- (NSString *)youTubeEmbedForURL:(NSURL *)url size:(CGSize)size {
    static NSString *const kEmbedHTMLMask = @"<html><head><style type=\"text/css\"> \
    body {background-color:transparent;color:white;}</style> \
    </head><body style=\"margin:0\"> \
    <embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \
    width=\"%0.0f\" height=\"%0.0f\"></embed></body></html>";
    
    NSString *URLString = [[url absoluteString] stringByReplacingOccurrencesOfString:@"watch?v=" withString:@"v/"];
    return [NSString stringWithFormat:kEmbedHTMLMask, URLString, size.width, size.height];
}

- (void)updateYouTubeEmbedInWebView:(UIWebView *)webView toSize:(CGSize)size {
    static NSString *const kJSCommandMask = @"\
        (function (width, height) {\
            var embeds = document.getElementsByTagName('embed');\
            if (embeds.length == 0) return;\
            var embed = embeds[0];\
            embed.width = width;\
            embed.height = height;\
        })(%.0f, %.0f);\
    ";
    
    NSString *command = [[NSString alloc] initWithFormat:kJSCommandMask, size.width, size.height];
    [webView stringByEvaluatingJavaScriptFromString:command];
}

#pragma mark - Private — Gesture Recognizers

- (void)handleWebViewTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.delegate carouselYouTubePlayerCell:self webView:self.webView didReceiveTapWithGestureRecognizer:recognizer];
    }
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
