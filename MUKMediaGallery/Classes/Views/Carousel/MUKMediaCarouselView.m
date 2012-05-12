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
#import "MUKMediaGalleryUtils_.h"
#import "MUKMediaGalleryImageFetcher_.h"
#import "MUKMediaCarouselImageCellView_.h"

@interface MUKMediaCarouselView ()
@property (nonatomic, strong) MUKGridView *gridView_;

- (void)commonInitialization_;
- (void)attachGridHandlers_;

- (CGRect)gridFrame_;
@end

@implementation MUKMediaCarouselView
@synthesize mediaAssets = mediaAssets_;
@synthesize thumbnailsFetcher = thumbnailsFetcher_;
@synthesize usesThumbnailImageFileCache = usesThumbnailImageFileCache_;
@synthesize purgesThumbnailsMemoryCacheWhenReloading = purgesThumbnailsMemoryCacheWhenReloading_;
@synthesize imagesFetcher = imagesFetcher_;
@synthesize usesImageMemoryCache = usesImageMemoryCache_;
@synthesize usesImageFileCache = usesImageFileCache_;
@synthesize purgesImagesMemoryCacheWhenReloading = purgesImagesMemoryCacheWhenReloading_;
@synthesize mediaOffset = mediaOffset_;
@synthesize imageMinimumZoomScale = imageMinimumZoomScale_, imageMaximumZoomScale = imageMaximumZoomScale_;

@synthesize gridView_ = gridView__;

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
    [(MUKMediaGalleryImageFetcher_ *)thumbnailsFetcher_ setBlockHandlers:NO];
    thumbnailsFetcher_.shouldStartConnectionHandler = nil;
    
    [(MUKMediaGalleryImageFetcher_ *)imagesFetcher_ setBlockHandlers:NO];
    imagesFetcher_.shouldStartConnectionHandler = nil;
    
    [self.gridView_ removeAllHandlers];
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
            NSInteger assetIndex = [weakSelf.mediaAssets indexOfObject:mediaAsset];
            
            NSIndexSet *visibleAssetsIndexes = [weakSelf.gridView_ indexesOfVisibleCells];
            BOOL assetVisible = [visibleAssetsIndexes containsIndex:assetIndex];
            
            if (!assetVisible) {
                // If asset is hidden, cancel download
                return NO;
            }
            
            return YES;
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
            NSInteger assetIndex = [weakSelf.mediaAssets indexOfObject:mediaAsset];
            
            NSIndexSet *visibleAssetsIndexes = [weakSelf.gridView_ indexesOfVisibleCells];
            BOOL assetVisible = [visibleAssetsIndexes containsIndex:assetIndex];
            
            if (!assetVisible) {
                // If asset is hidden, cancel download
                return NO;
            }
            
            return YES;
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
    if (self.purgesThumbnailsMemoryCacheWhenReloading) {
        [thumbnailsFetcher_.cache cleanMemoryCache];
    }
    [thumbnailsFetcher_.connectionQueue cancelAllConnections];
    
    if (self.purgesImagesMemoryCacheWhenReloading) {
        [imagesFetcher_.cache cleanMemoryCache];
    }
    [imagesFetcher_.connectionQueue cancelAllConnections];
    
    // Reload grid
    [self.gridView_ reloadData];
    
    // Cells are layed out
    // Load thumbnails also from file
    [self loadVisibleThumbnails_];
    
    // TODO: load visible medias
}

#pragma mark - Private

- (void)commonInitialization_ {
    mediaOffset_ = 20.0f;
    usesImageFileCache_ = YES;
    purgesImagesMemoryCacheWhenReloading_ = YES;
    imageMinimumZoomScale_ = 1.0f;
    imageMaximumZoomScale_ = 3.0f;
    
    gridView__ = [[MUKGridView alloc] initWithFrame:[self gridFrame_]];
    
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
    
    self.gridView_.cellCreationHandler = ^UIView<MUKRecyclable>* (NSInteger cellIndex) 
    {
        // TODO: distinguish reuse identifiers
        MUKMediaCarouselImageCellView_ *cellView = (MUKMediaCarouselImageCellView_ *)[weakGridView dequeueViewWithIdentifier:@"Cell"];
        
        if (cellView == nil) {
            cellView = [[MUKMediaCarouselImageCellView_ alloc] initWithFrame:CGRectMake(0, 0, 200, 200) recycleIdentifier:@"Cell"];
        }
        
        // Set view attributes
        cellView.backgroundColor = weakSelf.backgroundColor;
        cellView.insets = UIEdgeInsetsMake(0, weakSelf.mediaOffset/2, 0, weakSelf.mediaOffset/2);
        
        // Associate with this media asset
        id<MUKMediaAsset> mediaAsset = [weakSelf.mediaAssets objectAtIndex:cellIndex];
        cellView.mediaAsset = mediaAsset;
        
        // Configure
        [cellView.activityIndicator startAnimating];
        
        [weakSelf configureThumbnailInCell_:cellView withMediaAsset_:mediaAsset atIndex_:cellIndex];

        return cellView;
    };
    
    self.gridView_.cellOptionsHandler = ^(NSInteger index) {
        MUKGridCellOptions *options = [[MUKGridCellOptions alloc] init];
        // TODO: set zoom if media is image and full image is loaded
        options.minimumZoomScale = weakSelf.imageMinimumZoomScale;
        options.maximumZoomScale = weakSelf.imageMaximumZoomScale;
        options.scrollIndicatorInsets = UIEdgeInsetsMake(0, weakSelf.mediaOffset/2, 0, weakSelf.mediaOffset/2);
        return options;
    };
    
    self.gridView_.scrollHandler = ^{
        // Hide nav bar when scrolling starts
    };
    
    self.gridView_.scrollCompletionHandler = ^(MUKGridScrollKind scrollKind)
    {
        [weakSelf loadVisibleThumbnails_];
        
        // Update page number
    };
    
    self.gridView_.cellTappedHandler = ^(NSInteger cellIndex) {
        // Hide nav bar
    };
    
    self.gridView_.cellDoubleTappedHandler = ^(NSInteger cellIndex) {
        // Zoom in
    };
    
    self.gridView_.cellZoomViewHandler = ^UIView* (UIView<MUKRecyclable> *cellView, NSInteger index)
    {
        // Enable zoom if full image is loaded
        return nil;
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
    frame.size.width += self.mediaOffset * 2;
    return frame;
}
         
#pragma mark - Private: Thumbnails
 
- (void)configureThumbnailInCell_:(MUKMediaCarouselImageCellView_ *)cell withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index
{
    // Clean
    [cell setCenteredImage:nil];
    
    // Search for thumbnail in cache
    // Only from memory, because async loading is done when view is idle
    [self loadThumbnailForMediaAsset_:mediaAsset onlyFromMemory_:YES atIndex_:index inCell_:cell]; 
}

- (void)loadThumbnailForMediaAsset_:(id<MUKMediaAsset>)mediaAsset onlyFromMemory_:(BOOL)onlyFromMemory atIndex_:(NSInteger)index inCell_:(MUKMediaCarouselImageCellView_ *)cell
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
        MUKImageFetcherSearchDomain searchDomains = [MUKMediaGalleryUtils_ thumbnailSearchDomainsForMediaAsset:mediaAsset memoryCache:YES fileCache:!onlyFromMemory file:!onlyFromMemory remote:NO];
        MUKObjectCacheLocation cacheLocations = [MUKMediaGalleryUtils_ thumbnailCacheLocationsForMediaAsset_:mediaAsset memoryCache:YES fileCache:self.usesThumbnailImageFileCache];
        
        MUKURLConnection *connection = nil;
        if (!onlyFromMemory) {
            connection = [MUKMediaGalleryUtils_ thumbnailConnectionForMediaAsset:mediaAsset];
        }
        
        __unsafe_unretained MUKMediaCarouselView *weakSelf = self;
        
        [self.thumbnailsFetcher loadImageForURL:thumbnailURL searchDomains:searchDomains cacheToLocations:cacheLocations connection:connection completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomains) 
         {
             // Insert in right cell at this time
             if (mediaAsset == cell.mediaAsset) {
                 [cell setCenteredImage:image];
             }
             else {
                 MUKMediaCarouselImageCellView_ *rightCell = (MUKMediaCarouselImageCellView_ *)[weakSelf.gridView_ cellViewAtIndex:index];
                 [rightCell setCenteredImage:image];
             }
         }];
    }
}

- (void)loadVisibleThumbnails_ {
    [self loadThumbnailsInCells_:[self.gridView_ visibleViews]];
}

- (void)loadThumbnailsInCells_:(NSSet *)cells {
    [cells enumerateObjectsUsingBlock:^(id obj, BOOL *stop) 
     {
         MUKMediaCarouselImageCellView_ *cell = obj;
         
         // Image is cleared in cellCreationHandler
         // If cell has not an image it should be loaded from any source
         if (!cell.imageView.image) {
             id<MUKMediaAsset> mediaAsset = cell.mediaAsset;
             if (mediaAsset) {
                 NSInteger mediaAssetIndex = [self.mediaAssets indexOfObject:mediaAsset];
                 if (NSNotFound != mediaAssetIndex) {
                     [self loadThumbnailForMediaAsset_:mediaAsset onlyFromMemory_:NO atIndex_:mediaAssetIndex inCell_:cell];
                 } // if media asset index
             } // if media asset
         } // if image == nil
     }];
}

@end
