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

#import "MUKMediaCarouselViewController.h"
#import "MUKMediaGalleryUtils_.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MUKMediaCarouselViewController ()
@property (nonatomic, copy) void (^completionHandler_)(MUKMediaCarouselViewController *);

- (NSString *)localizedTitle_;
- (void)setBarsHidden_:(BOOL)hidden animated_:(BOOL)animated;
- (BOOL)areBarsHidden_;

- (UIEdgeInsets)carouselInset_;
- (UIEdgeInsets)carouselInsetWithHiddenBars_:(BOOL)hiddenBars;

- (void)registerToMoviePlayerNotifications_;
- (void)unregisterFromMoviePlayerNotifications_;
- (void)moviePlayerWillEnterFullscreenNotification_:(NSNotification *)notification;
- (void)moviePlayerDidExitFullscreenNotification_:(NSNotification *)notification;
@end

@implementation MUKMediaCarouselViewController {
    UIStatusBarStyle prevStatusBarStyle_;
    UIBarStyle prevNavBarStyle_;
    BOOL viewWillAppearCalled_, isRotating_, fullscreenMoviePlayer_;
    NSInteger mediaAssetIndexAfterCompletion_;
}
@synthesize carouselView = carouselView_;
@synthesize managesBarsTransparency = managesBarsTransparency_;
@synthesize completionHandler_ = completionHandler__;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil completion:(void (^)(MUKMediaCarouselViewController *))completionHandler
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self registerToMoviePlayerNotifications_];
        managesBarsTransparency_ = YES;
        self.wantsFullScreenLayout = YES;
        self.completionHandler_ = completionHandler;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil completion:nil];
}

- (void)dealloc {
    [self unregisterFromMoviePlayerNotifications_];
    [self detachHandlersFromCarouselView:self.carouselView];
}

#pragma mark - 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    if (self.carouselView == nil) {
        self.carouselView = [[MUKMediaCarouselView alloc] initWithFrame:self.view.bounds];
        self.carouselView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.carouselView.backgroundColor = self.view.backgroundColor;
        self.carouselView.togglesOverlayViewOnUserTouch = NO;
        
        [self.view addSubview:self.carouselView];
    }
    
    [self attachHandlersToCarouselView:self.carouselView];
    
    if (self.completionHandler_) {
        self.completionHandler_(self);
        self.completionHandler_ = nil;
    }
    
    mediaAssetIndexAfterCompletion_ = [self.carouselView currentMediaAssetIndex];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.carouselView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        return YES;
    }
    
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (viewWillAppearCalled_ == NO) {
        viewWillAppearCalled_ = YES;
                
        prevStatusBarStyle_ = [[UIApplication sharedApplication] statusBarStyle];
        prevNavBarStyle_ = self.navigationController.navigationBar.barStyle;
        
        if (self.managesBarsTransparency) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
            self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        }      
        
        // Adjust inset
        [self.carouselView setOverlayViewInsets:[self carouselInset_] animated:NO];
        
        // Scroll again, if not portrait
        // Landscape is not detected in viewDidLoad
        [self.carouselView scrollToMediaAssetAtIndex:mediaAssetIndexAfterCompletion_ animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.managesBarsTransparency) {
        // Going back
        [[UIApplication sharedApplication] setStatusBarStyle:prevStatusBarStyle_ animated:YES];
        self.navigationController.navigationBar.barStyle = prevNavBarStyle_;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    isRotating_ = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
    
    [self.carouselView setOverlayViewInsets:[self carouselInset_] animated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    isRotating_ = NO;
}

#pragma mark - Methods

- (void)attachHandlersToCarouselView:(MUKMediaCarouselView *)carouselView
{
    __unsafe_unretained MUKMediaCarouselViewController *weakSelf = self;
    __unsafe_unretained MUKMediaCarouselView *weakCarouselView = carouselView;
    
    carouselView.scrollHandler = ^{
        // Hide bars
        // Ignore during rotations
        // Ignore during fullscreen
        if (!weakSelf->isRotating_ && !weakSelf->fullscreenMoviePlayer_)
        {
            if ([weakCarouselView canHideOverlayViewAtIndex:[weakCarouselView currentMediaAssetIndex]])
            {
                [weakSelf setBarsHidden_:YES animated_:YES];
            }
        }
    };
    
    carouselView.scrollCompletionHandler = ^{
        // Update title
        weakSelf.title = [weakSelf localizedTitle_];
    };
    
    carouselView.mediaAssetTappedHandler = ^(NSInteger index) {
        // Toggle bars
        BOOL barsHidden = [weakSelf areBarsHidden_];
        BOOL barsWillBeHidden = !barsHidden;
        
        BOOL toggleBarsVisibility = YES;
        if (barsWillBeHidden) {
            toggleBarsVisibility = [weakCarouselView canHideOverlayViewAtIndex:index];
        }
        
        if (toggleBarsVisibility) {
            [weakSelf setBarsHidden_:barsWillBeHidden animated_:YES];
        }
    };
    
    carouselView.mediaAssetZoomedHandler = ^(NSInteger index, float scale)
    {
        // Adjust overlay view visibility
        if ([weakCarouselView shouldShowOverlayViewAtIndex:index]) {
            // Overlay should be visibile
            if (![weakSelf areBarsHidden_]) {
                // Show if bar are visible
                if ([weakCarouselView isOverlayViewHidden]) {
                    // Show if currently hidden
                    [weakCarouselView setOverlayViewHidden:NO animated:YES];
                }
            }
        }
        else {
            // Overlay should be hidden
            if (![weakCarouselView isOverlayViewHidden]) {
                // Hide if currently not hidden
                if ([weakCarouselView canHideOverlayViewAtIndex:index]) {
                    // ...and can be hidden
                    [weakCarouselView setOverlayViewHidden:YES animated:YES];
                }
            }
        }
    };
    
    carouselView.mediaAssetDisplayedHandler = ^(id<MUKMediaAsset> mediaAsset, NSInteger index)
    {
        // Adapt bars visiblity (YouTube video may have forced overlay view to
        // visible)
        [weakSelf setBarsHidden_:[weakCarouselView isOverlayViewHidden] animated_:YES];
    };
}

- (void)detachHandlersFromCarouselView:(MUKMediaCarouselView *)carouselView
{
    carouselView.scrollCompletionHandler = nil;
    carouselView.scrollHandler = nil;
    carouselView.mediaAssetTappedHandler = nil;
    carouselView.mediaAssetZoomedHandler = nil;
    carouselView.mediaAssetDisplayedHandler = nil;
}

- (void)updateTitle {
    self.title = [self localizedTitle_];
}

#pragma mark - Private

- (NSString *)localizedTitle_ {
    NSInteger currentMediaAssetIndex = [self.carouselView currentMediaAssetIndex];
    if (currentMediaAssetIndex == NSNotFound) return nil;
    
    NSInteger mediaAssetsCount = [self.carouselView.mediaAssets count];
    
    NSString *mask = [MUKMediaGalleryUtils_ localizedStringForKey:@"MEDIA_ASSET_NUMBER_OF_MEDIA_ASSETS_TOTAL_MASK" comment:@"Media Asset Number"];
    NSString *title = [NSString stringWithFormat:mask, currentMediaAssetIndex+1, mediaAssetsCount];
    
    return title;
}

- (void)setBarsHidden_:(BOOL)hidden animated_:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:(animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];
    
    // Fade navigation bar instead of sliding
    [UIView animateWithDuration:(animated ? 0.3f : -1.0f) animations:^{
        self.navigationController.navigationBar.alpha = (hidden ? 0.0f : 1.0f);
    } completion:^(BOOL finished) {
        self.navigationController.navigationBarHidden = hidden;
    }];
    
    // Hide/Show overlay view
    if (hidden) {
        if ([self.carouselView canHideOverlayViewAtIndex:[self.carouselView currentMediaAssetIndex]])
        {
            [self.carouselView setOverlayViewHidden:YES animated:animated];
        }
    }
    else {
        if ([self.carouselView shouldShowOverlayViewAtIndex:[self.carouselView currentMediaAssetIndex]])
        {
            [self.carouselView setOverlayViewInsets:[self carouselInsetWithHiddenBars_:NO] animated:NO];
            [self.carouselView setOverlayViewHidden:NO animated:animated];
        }
    }
}

- (BOOL)areBarsHidden_ {
    BOOL navBarHidden = [self.navigationController isNavigationBarHidden];
    BOOL statusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    
    return (navBarHidden && statusBarHidden);
}

- (UIEdgeInsets)carouselInset_ {
    return [self carouselInsetWithHiddenBars_:[self areBarsHidden_]];
}

- (UIEdgeInsets)carouselInsetWithHiddenBars_:(BOOL)hiddenBars
{
    UIEdgeInsets inset = UIEdgeInsetsZero;
    
    if (!hiddenBars) {
        CGFloat statusBarHeight;
        if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) 
        {
            statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        }
        else {
            statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.width;
        }
        
        inset.top = statusBarHeight + self.navigationController.navigationBar.frame.size.height;
    }
    
    return inset;
}

- (void)registerToMoviePlayerNotifications_ {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(moviePlayerWillEnterFullscreenNotification_:) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
    [nc addObserver:self selector:@selector(moviePlayerDidExitFullscreenNotification_:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
}

- (void)unregisterFromMoviePlayerNotifications_ {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
    [nc removeObserver:self name:MPMoviePlayerDidExitFullscreenNotification object:nil];
}

- (void)moviePlayerWillEnterFullscreenNotification_:(NSNotification *)notification
{
    fullscreenMoviePlayer_ = YES;
    
    [self setBarsHidden_:YES animated_:YES];
}

- (void)moviePlayerDidExitFullscreenNotification_:(NSNotification *)notification
{
    fullscreenMoviePlayer_ = NO;
    
    [self setBarsHidden_:NO animated_:YES];
}

@end
