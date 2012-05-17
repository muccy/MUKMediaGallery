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

#import "MUKMediaThumbnailsViewController.h"

@interface MUKMediaThumbnailsViewController ()
@property (nonatomic, copy) void (^completionHandler_)(MUKMediaThumbnailsViewController *);

- (CGFloat)topPadding_;
@end

@implementation MUKMediaThumbnailsViewController {
    UIStatusBarStyle prevStatusBarStyle_;
    UIBarStyle prevNavBarStyle_;
    BOOL viewWillAppearCalled_, isPushingCarousel_, hasTopPadding_;
}
@synthesize thumbnailsView = thumbnailsView_;
@synthesize managesBarsTransparency = managesBarsTransparency_;
@synthesize carouselConfigurator = carouselConfigurator_;

@synthesize completionHandler_ = completionHandler__;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil completion:(void (^)(MUKMediaThumbnailsViewController *))completionHandler
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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
    [self detachHandlersFromThumbnailsView:self.thumbnailsView];
}

#pragma mark - 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];

    if (self.thumbnailsView == nil) {
        self.thumbnailsView = [[MUKMediaThumbnailsView alloc] initWithFrame:self.view.bounds];
        self.thumbnailsView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.thumbnailsView.backgroundColor = self.view.backgroundColor;
        [self.view addSubview:self.thumbnailsView];
    }
    
    [self attachHandlersToThumbnailsView:self.thumbnailsView];
    
    if (self.completionHandler_) {
        self.completionHandler_(self);
        self.completionHandler_ = nil;
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.thumbnailsView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        return YES;
    }
    
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (hasTopPadding_) {
        self.thumbnailsView.topPadding = [self topPadding_];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    BOOL shouldScrollToTop = NO;
    
    if (viewWillAppearCalled_ == NO) {
        viewWillAppearCalled_ = YES;
        
        prevStatusBarStyle_ = [[UIApplication sharedApplication] statusBarStyle];
        prevNavBarStyle_ = self.navigationController.navigationBar.barStyle;
        
        if (self.managesBarsTransparency) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
            self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
            hasTopPadding_ = YES;
        }
        else {
            hasTopPadding_ = (prevStatusBarStyle_ == UIStatusBarStyleBlackTranslucent && prevNavBarStyle_ == UIBarStyleBlackTranslucent);
        }
        
        shouldScrollToTop = hasTopPadding_;
    }
    
    if (hasTopPadding_) {
        self.thumbnailsView.topPadding = [self topPadding_];
        
        if (shouldScrollToTop) {
            [self.thumbnailsView scrollToTopAnimated:NO];
        }
    } 
    
    [self.thumbnailsView deselectSelectedMediaAsset];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.managesBarsTransparency && !isPushingCarousel_)
    {
        // Going back
        [[UIApplication sharedApplication] setStatusBarStyle:prevStatusBarStyle_ animated:YES];
        self.navigationController.navigationBar.barStyle = prevNavBarStyle_;
    }
    else {
        isPushingCarousel_ = NO;
    }
}

#pragma mark - Methods

- (void)attachHandlersToThumbnailsView:(MUKMediaThumbnailsView *)thumbnailsView
{
    __unsafe_unretained MUKMediaThumbnailsViewController *weakSelf = self;
    
    thumbnailsView.thumbnailSelectionHandler = ^(NSInteger index)
    {
        // Push carousel
        isPushingCarousel_ = YES;
        
        MUKMediaCarouselViewController *viewController = [weakSelf newCarouselViewControllerToShowMediaAssetAtIndex:index];
        
        [weakSelf.navigationController pushViewController:viewController animated:YES];
    };
}

- (void)detachHandlersFromThumbnailsView:(MUKMediaThumbnailsView *)thumbnailsView
{
    thumbnailsView.thumbnailSelectionHandler = nil;
}

- (MUKMediaCarouselViewController *)newCarouselViewControllerToShowMediaAssetAtIndex:(NSInteger)index
{
    MUKMediaCarouselViewController *viewController = [[MUKMediaCarouselViewController alloc] initWithNibName:nil bundle:nil completion:^(MUKMediaCarouselViewController *vc) 
    {
        [self configureCarouselViewController:vc toShowMediaAssetAtIndex:index]; 
    }];
    
    return viewController;
}

- (void)configureCarouselViewController:(MUKMediaCarouselViewController *)carouselViewController toShowMediaAssetAtIndex:(NSInteger)index
{
    carouselViewController.carouselView.mediaAssets = self.thumbnailsView.mediaAssets;
    carouselViewController.carouselView.thumbnailsFetcher.cache = self.thumbnailsView.thumbnailsFetcher.cache;
    
    [carouselViewController.carouselView scrollToMediaAssetAtIndex:index animated:NO];
    [carouselViewController updateTitle];
    
    if (self.carouselConfigurator) {
        self.carouselConfigurator(carouselViewController, index);
    }
}

#pragma mark - Private

- (CGFloat)topPadding_ {
    CGFloat statusBarHeight;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) 
    {
        statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
    else {
        statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.width;
    }
    
    CGFloat topPadding = statusBarHeight + self.navigationController.navigationBar.frame.size.height;
    return topPadding;
}

@end
