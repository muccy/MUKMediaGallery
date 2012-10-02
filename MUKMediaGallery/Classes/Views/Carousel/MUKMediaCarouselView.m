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

#import "MUKMediaCarouselView.h"
#import "MUKMediaCarouselView_Thumbnails.h"

#import <MUKScrolling/MUKScrolling.h>
#import <MUKNetworking/MUKNetworking.h>

#import "MUKMediaGalleryUtils_.h"
#import "MUKMediaGalleryImageFetcher_.h"
#import "LBYouTubeExtractor.h"

#import "MUKMediaCarouselImageCellView_.h"
#import "MUKMediaCarouselPlayerCellView_.h"
#import "MUKMediaCarouselYouTubeCellView_.h"

#import "MUKMediaImageAssetProtocol.h"

#define DEBUG_FAKE_NO_NATIVE_YT     0

@interface MUKMediaCarouselView ()
@property (nonatomic, strong) MUKGridView *gridView_;
@property (nonatomic, strong) NSMutableIndexSet *loadedMediaIndexes_;
@property (nonatomic, strong) LBYouTubeExtractor *youTubeExtractor_;
@property (nonatomic) BOOL needsLoadingVisibleMedias_, notAnimatedScrolling_, overlayViewHidden_;
@property (nonatomic) UIEdgeInsets overlayViewInsets_;

- (void)commonInitialization_;
- (void)attachGridHandlers_;

- (CGRect)gridFrame_;
@end

@implementation MUKMediaCarouselView
@synthesize mediaAssets = mediaAssets_;
@synthesize thumbnailsFetcher = thumbnailsFetcher_;
@synthesize imagesFetcher = imagesFetcher_;
@synthesize usesImageMemoryCache = usesImageMemoryCache_;
@synthesize usesImageFileCache = usesImageFileCache_;
@synthesize purgesImagesMemoryCacheWhenReloading = purgesImagesMemoryCacheWhenReloading_;
@synthesize mediaOffset = mediaOffset_;
@synthesize imageMinimumZoomScale = imageMinimumZoomScale_, imageMaximumZoomScale = imageMaximumZoomScale_;
@synthesize autoplaysMedias = autoplaysMedias_;
@synthesize togglesOverlayViewOnUserTouch = togglesOverlayViewOnUserTouch_;

@synthesize scrollHandler = scrollHandler_;
@synthesize scrollCompletionHandler = scrollCompletionHandler_;
@synthesize mediaAssetTappedHandler = mediaAssetTappedHandler_;
@synthesize mediaAssetZoomedHandler = mediaAssetZoomedHandler_;
@synthesize imageConnectionHandler = imageConnectionHandler_;
@synthesize mediaAssetDisplayedHandler = mediaAssetDisplayedHandler_;

@synthesize gridView_ = gridView__;
@synthesize loadedMediaIndexes_ = loadedMediaIndexes__;
@synthesize youTubeExtractor_ = youTubeExtractor__;
@synthesize needsLoadingVisibleMedias_ = needsLoadingVisibleMedias__, notAnimatedScrolling_ = notAnimatedScrolling__, overlayViewHidden_ = overlayViewHidden__;
@synthesize overlayViewInsets_ = overlayViewInsets__;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitialization_];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInitialization_];
    }
    return self;
}

- (void)dealloc {
    [thumbnailsFetcher_.connectionQueue cancelAllConnections];
    [(MUKMediaGalleryImageFetcher_ *)thumbnailsFetcher_ setBlockHandlers:NO];
    thumbnailsFetcher_.shouldStartConnectionHandler = nil;
    
    [imagesFetcher_.connectionQueue cancelAllConnections];
    [(MUKMediaGalleryImageFetcher_ *)imagesFetcher_ setBlockHandlers:NO];
    imagesFetcher_.shouldStartConnectionHandler = nil;
    
    [self.gridView_ removeAllHandlers];
    
    self.youTubeExtractor_.completionHandler = nil;
    [self.youTubeExtractor_ cancel];
    
    // Clean all cells for prudence
    [[self.gridView_ visibleViews] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) 
    {
        [self cleanHiddenCell_:obj];
    }];
    
    [[self.gridView_ enqueuedViews] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) 
    {
        [self cleanHiddenCell_:obj];
    }];
}

#pragma mark - Overrides

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.gridView_.backgroundColor = backgroundColor;
}

#pragma mark - Accessors

- (MUKImageFetcher *)thumbnailsFetcher {
    if (thumbnailsFetcher_ == nil) {
        thumbnailsFetcher_ = [[MUKMediaGalleryImageFetcher_ alloc] init];
        
        __unsafe_unretained MUKMediaCarouselView *weakSelf = self;
        thumbnailsFetcher_.shouldStartConnectionHandler = ^(MUKURLConnection *connection)
        {
            // Do not start hidden asset
                        
            id<MUKMediaAsset> mediaAsset = connection.userInfo;
            BOOL assetVisible = [MUKMediaGalleryUtils_ isVisibleMediaAsset:mediaAsset fromMediaAssets:weakSelf.mediaAssets inGridView:weakSelf.gridView_];
            return assetVisible;
        };
        
        [(MUKMediaGalleryImageFetcher_ *)thumbnailsFetcher_ setBlockHandlers:YES];
    }
    
    return thumbnailsFetcher_;
}

- (MUKImageFetcher *)imagesFetcher {
    if (imagesFetcher_ == nil) {
        imagesFetcher_ = [[MUKMediaGalleryImageFetcher_ alloc] init];
        
        __unsafe_unretained MUKMediaCarouselView *weakSelf = self;
        imagesFetcher_.shouldStartConnectionHandler = ^(MUKURLConnection *connection)
        {
            // Do not start hidden asset
            
            id<MUKMediaAsset> mediaAsset = connection.userInfo;
            BOOL assetVisible = [MUKMediaGalleryUtils_ isVisibleMediaAsset:mediaAsset fromMediaAssets:weakSelf.mediaAssets inGridView:weakSelf.gridView_];
            return assetVisible;
        };
        
        [(MUKMediaGalleryImageFetcher_ *)imagesFetcher_ setBlockHandlers:YES];
    }
    
    return imagesFetcher_;
}

- (void)setMediaOffset:(CGFloat)mediaOffset {
    if (mediaOffset != mediaOffset_) {
        mediaOffset_ = mediaOffset;
        self.gridView_.frame = [self gridFrame_];
    }
}

- (void)setMediaAssets:(NSArray *)mediaAssets {
    if (mediaAssets != mediaAssets_) {
        mediaAssets_ = mediaAssets;
        self.gridView_.numberOfCells = [mediaAssets count];
    }
}

#pragma mark - Methods

- (void)reloadMedias {
    // Clean fetchers
    [thumbnailsFetcher_.connectionQueue cancelAllConnections];
    
    if (self.purgesImagesMemoryCacheWhenReloading) {
        [imagesFetcher_.cache cleanMemoryCache];
    }
    [imagesFetcher_.connectionQueue cancelAllConnections];
    
    // Clean loaded medias
    [self.loadedMediaIndexes_ removeAllIndexes];
    
    // Reload grid
    [self.gridView_ reloadData];
    
    // Cells are layed out
    // Thumbnails are already loaded
    [self loadCurrentMedia_];
}

- (NSInteger)currentMediaAssetIndex {
    float f = self.gridView_.contentOffset.x/self.gridView_.bounds.size.width;
    NSInteger index = floorf(f);
    
    if (index >= 0 && index < [self.mediaAssets count]) {
        return index;
    }
    
    return NSNotFound;
}

- (void)scrollToMediaAssetAtIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index >= 0 && index < [self.mediaAssets count]) {
        self.notAnimatedScrolling_ = !animated;
        
        [self.gridView_ scrollToCellAtIndex:index position:MUKGridScrollPositionHead animated:animated];
        
        if (!animated) {            
            [self didScrollToMediaAssetAtIndex:index animated:NO];
        }
    }
}

#pragma mark - Callbacks

- (void)didTapMediaAssetAtIndex:(NSInteger)index {
    if (self.mediaAssetTappedHandler) {
        self.mediaAssetTappedHandler(index);
    }
    
    // Adjust overlay view visibility
    if (self.togglesOverlayViewOnUserTouch) {
        if ([self shouldShowOverlayViewAtIndex:index]) {
            if ([self isOverlayViewHidden]) {
                [self setOverlayViewHidden:NO animated:YES];
            }
        }
        else {
            if (![self isOverlayViewHidden]) {
                if ([self canHideOverlayViewAtIndex:index]) {
                    [self setOverlayViewHidden:YES animated:YES];
                }
            }
        }
    }
}

- (void)didScrollToMediaAssetAtIndex:(NSInteger)index animated:(BOOL)animated
{
    if (animated) {
        // Animated
        // Thumbnails already loaded from memory
        [self loadCurrentMedia_];
        
        if (self.scrollCompletionHandler) {
            self.scrollCompletionHandler();
        }
    }
    else {
        // Not animated
        self.needsLoadingVisibleMedias_ = YES;
        [self setNeedsLayout];
    }
    
    // Overlay could not be hidden?
    if (![self canHideOverlayViewAtIndex:index]) {
        [self setOverlayViewHidden:NO animated:animated];
    }
}

#pragma mark - Overlay View

- (BOOL)shouldShowOverlayViewAtIndex:(NSInteger)index {
    float zoomScale = [self.gridView_ zoomScaleOfCellAtIndex:index];
    if (ABS(zoomScale - 1.0f) > 0.0001f) {
        // Zoomed 
        return NO;
    }
    
    if (![self isOverlayViewHidden]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)canHideOverlayViewAtIndex:(NSInteger)index {
    BOOL canHide;
    
    MUKMediaCarouselCellView_ *cellView = (MUKMediaCarouselCellView_ *)[self.gridView_ cellViewAtIndex:index];
    
    if (cellView) {
        /*
         Disable possibility of hiding YouTube overlay if video is shown with
         web view.
         */
        if ([cellView isKindOfClass:[MUKMediaCarouselYouTubeCellView_ class]]) {
            MUKMediaCarouselYouTubeCellView_ *ytCellView = (MUKMediaCarouselYouTubeCellView_ *)cellView;
            canHide = !ytCellView.usingWebView;
        }
        else {
            canHide = YES;
        }
    }
    else {
        // No cell view
        canHide = NO;
    }
    
    return canHide;
}

- (BOOL)isOverlayViewHidden {
    return self.overlayViewHidden_;
}

- (void)setOverlayViewHidden:(BOOL)hidden animated:(BOOL)animated {
    self.overlayViewHidden_ = hidden;
    
    MUKMediaCarouselCellView_ *cellView = (MUKMediaCarouselCellView_ *)[self.gridView_ cellViewAtIndex:[self currentMediaAssetIndex]];
    [cellView setOverlayViewHidden:hidden animated:animated];
}

- (UIEdgeInsets)overlayViewInsets {
    return self.overlayViewInsets_;
}

- (void)setOverlayViewInsets:(UIEdgeInsets)insets animated:(BOOL)animated
{
    if (!UIEdgeInsetsEqualToEdgeInsets(self.overlayViewInsets_, insets))
    {
        self.overlayViewInsets_ = insets;
        
        MUKMediaCarouselCellView_ *cellView = (MUKMediaCarouselCellView_ *)[self.gridView_ cellViewAtIndex:[self currentMediaAssetIndex]];
        [cellView setOverlayViewInsets:[self cellOverlayViewInsets_] animated:animated];
    }
}

#pragma mark - Private

- (void)commonInitialization_ {
    mediaOffset_ = 20.0f;
    usesImageFileCache_ = YES;
    purgesImagesMemoryCacheWhenReloading_ = YES;
    imageMinimumZoomScale_ = 1.0f;
    imageMaximumZoomScale_ = 3.0f;
    togglesOverlayViewOnUserTouch_ = YES;
    
    loadedMediaIndexes__ = [[NSMutableIndexSet alloc] init];
    gridView__ = [[MUKGridView alloc] initWithFrame:[self gridFrame_]];
    overlayViewInsets__ = UIEdgeInsetsZero;
    
    self.gridView_.cellSize = [[MUKGridCellSize alloc] initWithSizeHandler:^ (CGSize containerSize)
    {
        // Full page
        return containerSize;
    }];
    
    self.gridView_.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.gridView_.backgroundColor = self.backgroundColor;
    self.gridView_.direction = MUKGridDirectionHorizontal;
    self.gridView_.pagingEnabled = YES;
    self.gridView_.showsVerticalScrollIndicator = NO;
    self.gridView_.showsHorizontalScrollIndicator = NO;
    self.gridView_.detectsDoubleTapGesture = YES;
    self.gridView_.detectsLongPressGesture = NO;
    
    [self attachGridHandlers_];
    
    [self addSubview:self.gridView_];
}

- (void)attachGridHandlers_ {
    __unsafe_unretained MUKGridView *weakGridView = self.gridView_;
    __unsafe_unretained MUKMediaCarouselView *weakSelf = self;
    
    self.gridView_.didLayoutSubviewsHandler = ^{
        if (weakSelf.needsLoadingVisibleMedias_) {
            weakSelf.needsLoadingVisibleMedias_ = NO;
            [weakSelf loadCurrentMedia_];
        }
    };
    
    self.gridView_.cellCreationHandler = ^UIView<MUKRecyclable>* (NSInteger cellIndex) 
    {
        // Take media asset
        id<MUKMediaAsset> mediaAsset = (weakSelf.mediaAssets)[cellIndex];
        
        // Create or dequeue cell for this media asset
        MUKMediaCarouselCellView_ *cellView = [weakSelf createOrDequeueCellForMediaAsset_:mediaAsset];
        
        // Configure
        [weakSelf configureCellView_:cellView withMediaAsset_:mediaAsset atIndex_:cellIndex];

        return cellView;
    };
    
    self.gridView_.cellEnqueuedHandler = ^(UIView<MUKRecyclable> *cellView, NSInteger index)
    {
        // Clean hidden cells
        [weakSelf cleanHiddenCell_:(MUKMediaCarouselCellView_ *)cellView];
        
        // Set media as unloaded
        [weakSelf.loadedMediaIndexes_ removeIndex:index];
    };
    
    self.gridView_.cellOptionsHandler = ^(NSInteger index) {
        // Take media asset
        id<MUKMediaAsset> mediaAsset = (weakSelf.mediaAssets)[index];
        
        BOOL mediaLoaded = [weakSelf isLoadedMediaAssetAtIndex_:index];
        MUKGridCellOptions *options = [weakSelf cellOptionsForMediaAsset_:mediaAsset permitsZoomIfRequested_:mediaLoaded];
        
        return options;
    };
    
    self.gridView_.scrollHandler = ^{
        if (weakSelf.notAnimatedScrolling_ == NO) {
            /*
             Call handler only if scrolling is generated by an animation.
             */
            if (weakSelf.scrollHandler) {
                weakSelf.scrollHandler();
            }
        }
        else {
            weakSelf.notAnimatedScrolling_ = NO;
        }
    };
    
    self.gridView_.scrollCompletionHandler = ^(MUKGridScrollKind scrollKind)
    {
        [weakSelf didScrollToMediaAssetAtIndex:[weakSelf currentMediaAssetIndex] animated:YES];
    };
    
    self.gridView_.cellTappedHandler = ^(NSInteger cellIndex) {
        [weakSelf didTapMediaAssetAtIndex:cellIndex];
    };
    
    self.gridView_.cellZoomHandler = ^(UIView<MUKRecyclable> *cellView, UIView *zoomedView, NSInteger cellIndex, float scale)
    {
        if (weakSelf.mediaAssetZoomedHandler) {
            weakSelf.mediaAssetZoomedHandler(cellIndex, scale);
        }
        
        // Adjust overlay view visibility
        if (weakSelf.togglesOverlayViewOnUserTouch) {
            if ([weakSelf shouldShowOverlayViewAtIndex:cellIndex]) {
                if ([weakSelf isOverlayViewHidden]) {
                    [weakSelf setOverlayViewHidden:NO animated:YES];
                }
            }
            else {
                if (![weakSelf isOverlayViewHidden]) {
                    if ([weakSelf canHideOverlayViewAtIndex:cellIndex]) {
                        [weakSelf setOverlayViewHidden:YES animated:YES];
                    }
                }
            }
        }
    };
 
    self.gridView_.cellZoomViewHandler = ^UIView* (UIView<MUKRecyclable> *cellView, NSInteger index)
    {
        MUKMediaCarouselCellView_ *view = (MUKMediaCarouselCellView_ *)cellView;
        return view.imageView;
    };
    
    self.gridView_.cellZoomedViewFrameHandler = ^(UIView<MUKRecyclable> *cellView, UIView *zoomedView, NSInteger cellIndex, float scale, CGSize boundsSize)
    {
        CGRect rect;
        if (ABS(scale - 1.0f) > 0.00001f) {
            // Zoomed
            // Pay attention to offset: don't show left black space
            boundsSize.width -= weakSelf.mediaOffset;
            rect = [MUKGridView centeredZoomedViewFrame:zoomedView.frame boundsSize:boundsSize];
            rect.origin.x += weakSelf.mediaOffset/2;          
        }
        else {
            // Not zoomed
            MUKMediaCarouselCellView_ *view = (MUKMediaCarouselCellView_ *)cellView;
            rect = [view centeredImageFrame];
        }
        
        return rect;
    };
    
    self.gridView_.cellZoomedViewContentSizeHandler = ^(UIView<MUKRecyclable> *cellView, UIView *zoomedView, NSInteger cellIndex, float scale, CGSize boundsSize)
    {
        // Pay attention to offset: compensate origin shifting
        CGSize size = zoomedView.frame.size;
        size.width += weakSelf.mediaOffset;
        return size;
    };
    
    self.gridView_.cellDidLayoutSubviewsHandler = ^(UIView<MUKRecyclable> *cellView, NSInteger index)
    {
        MUKMediaCarouselImageCellView_ *view = (MUKMediaCarouselImageCellView_ *)cellView;
        float scale = [weakGridView zoomScaleOfCellAtIndex:index];
        
        if (ABS(scale - 1.0f) < 0.00001f) {
            // Not zoomed
            [view centerImage];
        }
    };
}

- (CGRect)gridFrame_ {
    CGRect frame = [self bounds];
    frame.origin.x -= self.mediaOffset/2;
    frame.size.width += self.mediaOffset;
    return frame;
}

#pragma mark - Private: Cells

- (MUKMediaCarouselCellView_ *)createOrDequeueCellForMediaAsset_:(id<MUKMediaAsset>)mediaAsset
{
    NSString *identifier = nil;
    Class cellClass = nil;
    
    switch ([mediaAsset mediaKind]) {
        case MUKMediaAssetKindImage:
            identifier = @"MUKMediaCarouselImageCellView_";
            cellClass = [MUKMediaCarouselImageCellView_ class];
            break;
            
        case MUKMediaAssetKindVideo:
        case MUKMediaAssetKindAudio:
            identifier = @"MUKMediaCarouselPlayerCellView_";
            cellClass = [MUKMediaCarouselPlayerCellView_ class];
            break;
            
        case MUKMediaAssetKindYouTubeVideo:
            identifier = @"MUKMediaCarouselYouTubeCellView_";
            cellClass = [MUKMediaCarouselYouTubeCellView_ class];
            break;
            
        default:
            identifier = @"MUKMediaCarouselCellView_";
            cellClass = [MUKMediaCarouselCellView_ class];
            break;
    }
    
    MUKMediaCarouselCellView_ *cellView = (MUKMediaCarouselCellView_ *)[self.gridView_ dequeueViewWithIdentifier:identifier];
    
    if (cellView == nil) {
        cellView = [[cellClass alloc] initWithFrame:CGRectMake(0, 0, 200, 200) recycleIdentifier:identifier];
    }
    
    return cellView;
}

- (void)configureCellView_:(MUKMediaCarouselCellView_ *)cellView withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index
{
    // Clean cell
    cellView.backgroundColor = self.backgroundColor;
    cellView.insets = [self cellViewInsets_];
    
    // Associate with this media asset
    id<MUKMediaAsset> prevMediaAsset = cellView.mediaAsset;
    cellView.mediaAsset = mediaAsset;
    
    // Adjust overlay view
    [cellView setOverlayViewHidden:[self isOverlayViewHidden] animated:NO];
    [cellView setOverlayViewInsets:[self cellOverlayViewInsets_] animated:NO];
    
    // Set caption
    if ([mediaAsset respondsToSelector:@selector(mediaCaption)]) {
        [cellView setCaptionText:[mediaAsset mediaCaption]];
    }
    
    // Set tap handler if needed
    if ([cellView isKindOfClass:[MUKMediaCarouselPlayerCellView_ class]]) {
        __unsafe_unretained MUKMediaCarouselView *weakSelf = self;
        [(MUKMediaCarouselPlayerCellView_ *)cellView setTapHandler:^{
            // Get media asset index
            NSInteger mediaAssetIndex = [weakSelf.mediaAssets indexOfObject:cellView.mediaAsset];
            if (mediaAssetIndex != NSNotFound) {
                [weakSelf didTapMediaAssetAtIndex:mediaAssetIndex];
            }
        }];
    }
    
    if (![self isLoadedMediaAssetAtIndex_:index]) {
        // Media is not loaded
        [self loadMediaForMediaAsset_:mediaAsset atIndex_:index onlyFromMemory_:YES inCell_:cellView whichHadMediaAsset_:prevMediaAsset];
        
        // Load thumbnail from memory if needed
        if (![self isLoadedMediaAssetAtIndex_:index]) {
            // Start spinner
            [cellView.activityIndicator startAnimating];
            
            // Set thumbnail
            [self configureThumbnailInCell_:cellView withMediaAsset_:mediaAsset atIndex_:index];
        }
    }
}

- (void)loadMediaForMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index onlyFromMemory_:(BOOL)onlyFromMemory inCell_:(MUKMediaCarouselCellView_ *)cellView whichHadMediaAsset_:(id<MUKMediaAsset>)prevMediaAsset
{    
    // Configure by types
    if (MUKMediaAssetKindImage == [mediaAsset mediaKind]) {
        // It's an image
        id<MUKMediaImageAsset> mediaImageAsset = (id<MUKMediaImageAsset>)mediaAsset;
        MUKMediaCarouselImageCellView_ *imageCell = (MUKMediaCarouselImageCellView_ *)cellView;
        
        // Load full image
        [self loadFullImageForMediaImageAsset_:mediaImageAsset onlyFromMemory_:onlyFromMemory atIndex_:index inCell_:imageCell];
    } // if image
    
    else if (MUKMediaAssetKindAudio == [mediaAsset mediaKind] ||
        MUKMediaAssetKindVideo == [mediaAsset mediaKind])
    {
        // It's an audio
        // It's a video
        if (onlyFromMemory == NO) {
            if ([mediaAsset respondsToSelector:@selector(mediaURL)])
            {
                NSURL *mediaURL = [mediaAsset mediaURL];
                
                if (mediaURL) {
                    MUKMediaCarouselPlayerCellView_ *mpCell = (MUKMediaCarouselPlayerCellView_ *)cellView;
                    
                    // Clean thumbnail
                    mpCell.imageView.image = nil;
                    
                    // Load media
                    [mpCell setMediaURL:mediaURL kind:[mediaAsset mediaKind]];
                    mpCell.moviePlayer.shouldAutoplay = self.autoplaysMedias;
                    
                    [self didLoadMediaAsset_:mediaAsset atIndex_:index inCell_:mpCell];
                }
            }
        }
    } // if video or audio
    
    else if (MUKMediaAssetKindYouTubeVideo == [mediaAsset mediaKind])
    {
        // It's YouTube
        if (onlyFromMemory == NO) {
            if ([mediaAsset respondsToSelector:@selector(mediaURL)])
            {
                NSURL *mediaURL = [mediaAsset mediaURL];
                
                if (mediaURL) {
                    if (![mediaURL isEqual:self.youTubeExtractor_.youTubeURL])
                    {
                        // Not processing same YouTube URL
                        
                        // Execute new extraction
                        MUKMediaCarouselYouTubeCellView_ *ytCell = (MUKMediaCarouselYouTubeCellView_ *)cellView;
                        
                        if (self.youTubeExtractor_ == nil) {
                            self.youTubeExtractor_ = [[LBYouTubeExtractor alloc] init];
                            
                            __unsafe_unretained MUKMediaCarouselView *weakSelf = self;
                            self.youTubeExtractor_.completionHandler = ^(NSURL *URL, NSError *error)
                            {
                                if (URL) {
                                    // Found movie URL
                                    // Load in movie player
                                    if (ytCell.mediaAsset == mediaAsset) {
#if DEBUG_FAKE_NO_NATIVE_YT
                                        [ytCell setMediaURL:mediaURL inWebView:YES];
#else
                                        [ytCell setMediaURL:URL inWebView:NO];
#endif
                                        
                                        [weakSelf didLoadMediaAsset_:mediaAsset atIndex_:index inCell_:ytCell];
                                    }
                                }
                                else {
                                    // Not found movie URL
                                    // Load in web view
                                    if (ytCell.mediaAsset == mediaAsset) {
                                        [ytCell setMediaURL:mediaURL inWebView:YES];
                                        
                                        [weakSelf didLoadMediaAsset_:mediaAsset atIndex_:index inCell_:ytCell];
                                    }
                                }
                            };
                        }
                        else {
                            // Cancel previous extractor instance
                            [self.youTubeExtractor_ cancel];
                        }

                        // Fire extraction
                        self.youTubeExtractor_.youTubeURL = mediaURL;
                        [self.youTubeExtractor_ start];
                    } // if different URL
                } // if mediaURL
            }
        } // if !onlyFromMemory
    } // if MUKMediaAssetKindYouTubeVideo
}

- (BOOL)isLoadedMediaAssetAtIndex_:(NSInteger)index {
    return [self.loadedMediaIndexes_ containsIndex:index];
}

- (void)didLoadMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index inCell_:(MUKMediaCarouselCellView_ *)cellView
{
    [self.loadedMediaIndexes_ addIndex:index];
 
    [cellView.activityIndicator stopAnimating];
    
    if (MUKMediaAssetKindImage == [mediaAsset mediaKind]) {
        MUKGridCellOptions *options = [self cellOptionsForMediaAsset_:mediaAsset permitsZoomIfRequested_:YES];
        [self.gridView_ setOptions:options forCellAtIndex:index];
    }
    
    // Overlay could not be hidden?
    if (![self canHideOverlayViewAtIndex:index]) {
        [self setOverlayViewHidden:NO animated:YES];
    }
    
    // Notify completion
    if (self.mediaAssetDisplayedHandler) {
        self.mediaAssetDisplayedHandler(mediaAsset, index);
    }
}

- (void)loadVisibleMedias_ {
    [[self.gridView_ indexesOfVisibleCells] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) 
     {
         MUKMediaCarouselCellView_ *cell = (MUKMediaCarouselCellView_ *)[self.gridView_ cellViewAtIndex:idx];
         id<MUKMediaAsset> mediaAsset = cell.mediaAsset;
         
         [self loadMediaForMediaAsset_:mediaAsset atIndex_:idx onlyFromMemory_:NO inCell_:cell whichHadMediaAsset_:mediaAsset];
     }]; // enumerate indexesOfVisibleCells
}

- (void)loadCurrentMedia_ {
    NSInteger currentMediaIndex = [self currentMediaAssetIndex];
    
    if (NSNotFound != currentMediaIndex) {
        MUKMediaCarouselCellView_ *cell = (MUKMediaCarouselCellView_ *)[self.gridView_ cellViewAtIndex:currentMediaIndex];
        id<MUKMediaAsset> mediaAsset = cell.mediaAsset;
        
        [self loadMediaForMediaAsset_:mediaAsset atIndex_:currentMediaIndex onlyFromMemory_:NO inCell_:cell whichHadMediaAsset_:mediaAsset];
    }
}

- (MUKGridCellOptions *)cellOptionsForMediaAsset_:(id<MUKMediaAsset>)mediaAsset permitsZoomIfRequested_:(BOOL)permitsZoom
{
    MUKGridCellOptions *options = [[MUKGridCellOptions alloc] init];
    options.showsVerticalScrollIndicator = NO;
    options.showsHorizontalScrollIndicator = NO;
    options.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.mediaOffset/2, 0, self.mediaOffset/2);
    
    if (permitsZoom && 
        MUKMediaAssetKindImage == [mediaAsset mediaKind])
    {
        options.minimumZoomScale = self.imageMinimumZoomScale;
        options.maximumZoomScale = self.imageMaximumZoomScale;
    }
    
    return options;
}

- (void)cleanHiddenCell_:(MUKMediaCarouselCellView_ *)cellView
{
    MUKMediaCarouselCellView_ *view = (MUKMediaCarouselCellView_ *)cellView;
    view.imageView.image = nil;
    
    if ([view isKindOfClass:[MUKMediaCarouselPlayerCellView_ class]])
    {        
        // Clean movie player
        MUKMediaCarouselPlayerCellView_ *mpCell = (MUKMediaCarouselPlayerCellView_ *)view;
        [mpCell cleanup];
        
        if ([view isKindOfClass:[MUKMediaCarouselYouTubeCellView_ class]])
        {
            // Web view has been cleaned by -cleanup
            
            // Clean extractor if there aren't visible YT cells
            NSSet *set = [[self.gridView_ visibleViews] objectsPassingTest:^BOOL(id obj, BOOL *stop)
            {
                if ([obj isKindOfClass:[MUKMediaCarouselYouTubeCellView_ class]])
                {
                    *stop = YES;
                    return YES;
                }
              
                return NO;
            }];
            
            if ([set count] == 0) {
                self.youTubeExtractor_.completionHandler = nil;
                [self.youTubeExtractor_ cancel];
                self.youTubeExtractor_ = nil;
            }
        }
    }
}

- (UIEdgeInsets)cellViewInsets_ {
    return UIEdgeInsetsMake(0, self.mediaOffset/2, 0, self.mediaOffset/2);
}

- (UIEdgeInsets)cellOverlayViewInsets_ {
    UIEdgeInsets cellInsets = [self cellViewInsets_];
    
    UIEdgeInsets cellOverlayInsets = self.overlayViewInsets_;
    cellOverlayInsets.left += cellInsets.left;
    cellOverlayInsets.top += cellInsets.top;
    cellOverlayInsets.right += cellInsets.right;
    cellOverlayInsets.bottom += cellInsets.bottom;
    
    return cellOverlayInsets;
}

#pragma mark - Private: Thumbnails
 
- (void)configureThumbnailInCell_:(MUKMediaCarouselCellView_ *)cell withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index
{
    // Clean
    [cell setCenteredImage:nil];
    
    // Search for thumbnail in cache (only memory)
    [self loadThumbnailForMediaAsset_:mediaAsset atIndex_:index inCell_:cell]; 
}

- (void)loadThumbnailForMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index inCell_:(MUKMediaCarouselCellView_ *)cell
{
    BOOL userProvidesThumbnail = NO;
    UIImage *userProvidedThumbnail = [MUKMediaGalleryUtils_ userProvidedThumbnailForMediaAsset:mediaAsset provided:&userProvidesThumbnail];
    
    /*
     If user provides thumbnails, exclude automatic loading system.
     */
    if (YES == userProvidesThumbnail) {
        [cell setCenteredImage:userProvidedThumbnail];
        return;
    }
    
    /*
     If user does not provide thumbnails, begin with automatic loading.
     
     URL is essential...
     */
    NSURL *thumbnailURL = [MUKMediaGalleryUtils_ thumbnailURLForMediaAsset:mediaAsset];
    if (thumbnailURL) {        
        [self.thumbnailsFetcher loadImageForURL:thumbnailURL searchDomains:MUKImageFetcherSearchDomainMemoryCache cacheToLocations:MUKObjectCacheLocationNone connection:nil completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomains) 
         {
             // Called synchronously
             [cell setCenteredImage:image];
         }];
    }
}

#pragma mark - Private: Full Image

- (void)loadFullImageForMediaImageAsset_:(id<MUKMediaImageAsset>)mediaImageAsset onlyFromMemory_:(BOOL)onlyFromMemory atIndex_:(NSInteger)index inCell_:(MUKMediaCarouselImageCellView_ *)cell
{
    BOOL userProvidesFullImage = NO;
    UIImage *userProvidedFullImage = [MUKMediaGalleryUtils_ userProvidedFullImageForMediaImageAsset:mediaImageAsset provided:&userProvidesFullImage];
    /*
     If user provides full image, exclude automatic loading system.
     */
    if (YES == userProvidesFullImage) {
        [cell setCenteredImage:userProvidedFullImage];
        [self didLoadMediaAsset_:mediaImageAsset atIndex_:index inCell_:cell];
        
        return;
    }
    
    /*
     If user does not provide images, begin with automatic loading.
     
     URL is essential...
     */
    NSURL *imageURL = [MUKMediaGalleryUtils_ fullImageURLForMediaImageAsset:mediaImageAsset];
    if (imageURL) {
        BOOL searchInFileCache = (self.usesImageFileCache && !onlyFromMemory);
        
        MUKImageFetcherSearchDomain searchDomains = [MUKMediaGalleryUtils_ fullImageSearchDomainsForMediaImageAsset:mediaImageAsset memoryCache:self.usesImageMemoryCache fileCache:searchInFileCache file:!onlyFromMemory remote:!onlyFromMemory];
        MUKObjectCacheLocation cacheLocations = [MUKMediaGalleryUtils_ fullImageCacheLocationsForMediaImageAsset:mediaImageAsset memoryCache:self.usesImageFileCache fileCache:self.usesImageFileCache];
        
        MUKURLConnection *connection = nil;
        if (!onlyFromMemory) {
            if (self.imageConnectionHandler) {
                connection = self.imageConnectionHandler(mediaImageAsset, index);
            }
            
            if (connection == nil) {
                connection = [MUKImageFetcher standardConnectionForImageAtURL:imageURL];
            }
            
            connection.userInfo = mediaImageAsset;
        }
                
        [self.imagesFetcher loadImageForURL:imageURL searchDomains:searchDomains cacheToLocations:cacheLocations connection:connection completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomains) 
         {             
             // Insert in right cell at this time
             MUKMediaCarouselImageCellView_ *rightCell;
             
             if (mediaImageAsset == cell.mediaAsset) {
                 rightCell = cell;
             }
             else {
                 rightCell = (MUKMediaCarouselImageCellView_ *)[self.gridView_ cellViewAtIndex:index];
             }
             
             if (mediaImageAsset == rightCell.mediaAsset) {
                 [rightCell setCenteredImage:image];
                 
                 if (image) {
                     [self didLoadMediaAsset_:mediaImageAsset atIndex_:index inCell_:rightCell];
                 }
             }
         }];
    }
}

@end
