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

#import "MUKMediaThumbnailsView.h"
#import "MUKMediaThumbnailsView_MediaAssetsCountView.h"
#import "MUKMediaThumbnailsView_Layout.h"
#import "MUKMediaThumbnailsView_Cells.h"
#import "MUKMediaThumbnailsView_Thumbnails.h"
#import "MUKMediaThumbnailsView_Selection.h"

#import <MUKScrolling/MUKScrolling.h>
#import <MUKToolkit/MUKToolkit.h>
#import "MUKMediaGalleryUtils_.h"
#import "MUKMediaVideoAssetProtocol.h"
#import "MUKMediaGalleryImageFetcher_.h"

@interface MUKMediaThumbnailsView ()
@property (nonatomic, strong) MUKGridView *gridView_;
@property (nonatomic, strong) UIImage *videoCellImage_, *audioCellImage_;

- (void)commonInitialization_;
- (void)attachGridHandlers_;
@end

@implementation MUKMediaThumbnailsView
@synthesize mediaAssets = mediaAssets_;
@synthesize thumbnailsFetcher = thumbnailsFetcher_;
@synthesize usesThumbnailImageFileCache = usesThumbnailImageFileCache_;
@synthesize purgesThumbnailsMemoryCacheWhenReloading = purgesThumbnailsMemoryCacheWhenReloading_;
@synthesize thumbnailSize = thumbnailSize_;
@synthesize thumbnailOffset = thumbnailOffset_;
@synthesize displaysMediaAssetsCount = displaysMediaAssetsCount_;
@synthesize topPadding = topPadding_;
@synthesize showsSelection = showsSelection_;

@synthesize thumbnailSelectionHandler = thumbnailSelectionHandler_;

@synthesize mediaAssetsCountView_ = mediaAssetsCountView__;
@synthesize gridView_ = gridView__;
@synthesize videoCellImage_ = videoCellImage__, audioCellImage_ = audioCellImage__;
@synthesize selectedCellIndex_ = selectedCellIndex__;

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
    
    [self.gridView_ removeAllHandlers];
}

#pragma mark - Overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    [self adjustGridView_];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.gridView_.backgroundColor = backgroundColor;
}

#pragma mark - Accessors

- (MUKImageFetcher *)thumbnailsFetcher {
    if (thumbnailsFetcher_ == nil) {
        thumbnailsFetcher_ = [[MUKMediaGalleryImageFetcher_ alloc] init];
        
        __unsafe_unretained MUKMediaThumbnailsView *weakSelf = self;
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

- (void)setMediaAssets:(NSArray *)mediaAssets {
    if (mediaAssets != mediaAssets_) {
        mediaAssets_ = mediaAssets;
        
        self.gridView_.numberOfCells = [mediaAssets count];
        
        // Insert and update assets count (if needed)
        [self toggleMediaAssetsCountViewIfNeeded_];
        [self updateMediaAssetsCountViewWithMediaAssets_:self.mediaAssets];
    }
}

- (void)setThumbnailSize:(CGSize)thumbnailSize {
    if (!CGSizeEqualToSize(thumbnailSize, self.thumbnailSize)) {
        thumbnailSize_ = thumbnailSize;
        
        self.gridView_.cellSize = [[MUKGridCellFixedSize alloc] initWithSize:thumbnailSize];
        [self adjustGridView_];
    }
}

- (void)setDisplaysMediaAssetsCount:(BOOL)displaysMediaAssetsCount {
    if (displaysMediaAssetsCount != displaysMediaAssetsCount_) {
        displaysMediaAssetsCount_ = displaysMediaAssetsCount;
        
        // Insert and update assets count (if needed)
        [self toggleMediaAssetsCountViewIfNeeded_];
        [self updateMediaAssetsCountViewWithMediaAssets_:self.mediaAssets];
    }
}

- (void)setTopPadding:(CGFloat)topPadding {
    if (topPadding != topPadding_) {
        topPadding_ = topPadding;
        [self adjustGridView_];
    }
}

- (void)setThumbnailOffset:(CGSize)thumbnailOffset {
    if (!CGSizeEqualToSize(thumbnailOffset, thumbnailOffset_)) {
        thumbnailOffset_ = thumbnailOffset;
        [self adjustGridView_];
    }
}

#pragma mark - Methods

- (void)reloadThumbnails {
    // Clean fetcher
    if (self.purgesThumbnailsMemoryCacheWhenReloading) {
        [thumbnailsFetcher_.cache cleanMemoryCache];
    }
    [thumbnailsFetcher_.connectionQueue cancelAllConnections];
    
    // Reload grid
    [self.gridView_ reloadData];
    
    // Add cells are layed out
    // Load thumbnails also from file or from network
    [self loadVisibleThumbnails_];
}

#pragma mark - Selection

- (NSInteger)selectedMediaAsset {
    if (self.selectedCellIndex_ >= 0 && self.selectedCellIndex_ < [self.mediaAssets count])
    {
        // In bounds
        return self.selectedCellIndex_;
    }

    return NSNotFound;
}

- (void)deselectSelectedMediaAsset {
    if (self.selectedCellIndex_ >= 0) {
        [self deselectCellAtIndex_:self.selectedCellIndex_];
    }
}

- (void)didSelectMediaAssetAtIndex:(NSInteger)index {    
    // Call handler
    if (self.thumbnailSelectionHandler) {
        self.thumbnailSelectionHandler(index);
    }
}

#pragma mark - Private

- (void)commonInitialization_ {
    selectedCellIndex__ = -1;
    showsSelection_ = YES;
    
    thumbnailSize_ = CGSizeMake(79, 79);
    thumbnailOffset_ = CGSizeMake(4, 4);
    
    CGRect gridFrame = [[self class] gridFrameForBounds_:self.bounds cellSize_:thumbnailSize_ imageOffset_:thumbnailOffset_];
    self.gridView_ = [[MUKGridView alloc] initWithFrame:gridFrame];
    
    self.gridView_.alwaysBounceVertical = YES;
    self.gridView_.clipsToBounds = NO;
    self.gridView_.backgroundColor = self.backgroundColor;
    self.gridView_.direction = MUKGridDirectionVertical;
    self.gridView_.detectsDoubleTapGesture = NO;
    self.gridView_.detectsLongPressGesture = NO;
    
    self.gridView_.cellSize = [[MUKGridCellFixedSize alloc] initWithSize:thumbnailSize_];
        
    displaysMediaAssetsCount_ = YES;
    // Don't insert here, because we have 0 assets
    
    [self attachGridHandlers_];
    
    [self addSubview:self.gridView_];

}

- (void)attachGridHandlers_ {
    __unsafe_unretained MUKGridView *weakGridView = self.gridView_;
    __unsafe_unretained MUKMediaThumbnailsView *weakSelf = self;
    
    self.gridView_.cellCreationHandler = ^(NSInteger cellIndex) {
        static NSString *const kIdentifier = @"MUKMediaThumbnailView_";
        // Dequeue
        MUKMediaThumbnailView_ *cellView = (MUKMediaThumbnailView_ *)[weakGridView dequeueViewWithIdentifier:kIdentifier];
        
        // Create if does not exist
        if (cellView == nil) {
            cellView = [weakSelf createThumbnailCell_];
            cellView.recycleIdentifier = kIdentifier;
        }
        
        // Configure
        id<MUKMediaAsset> mediaAsset = [self.mediaAssets objectAtIndex:cellIndex];
        cellView.mediaAsset = mediaAsset;
        [weakSelf configureThumbnailCell_:cellView withMediaAsset_:mediaAsset atIndex_:cellIndex];
        
        return cellView;
    };
    
    self.gridView_.scrollHandler = ^{
        // No selection during scroll
        
        if (weakSelf.selectedCellIndex_ >= 0) {
            [weakSelf deselectCellAtIndex_:weakSelf.selectedCellIndex_];
        }
    };
    
    self.gridView_.cellTouchedHandler = ^(NSInteger cellIndex, NSSet *touches)
    {
        // Touch began
        if (weakSelf.showsSelection == NO) return;
        
        // If grid is moving abort touch handling immediately
        if (weakGridView.dragging || weakGridView.decelerating) {
            // Remove past selection
            if (weakSelf.selectedCellIndex_ >= 0) {
                [weakSelf deselectCellAtIndex_:weakSelf.selectedCellIndex_];
            }
            
            return;
        }
        
        // If grid view is not moving, look at grid after a while, to see
        // if it is a real tap, or if it is a touch in order to move the grid
        MUKGridView *strongGridView = weakGridView;
        MUKMediaThumbnailsView *strongSelf = weakSelf;
        
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (strongGridView.dragging == NO && strongGridView.decelerating == NO)
            {
                // Grid is not moving again
                
                // Remove past selection
                if (strongSelf.selectedCellIndex_ >= 0) {
                    [strongSelf deselectCellAtIndex_:strongSelf.selectedCellIndex_];
                }
                
                // Show selection
                [strongSelf selectCellAtIndex_:cellIndex];
            }
        });
    };
    
    self.gridView_.cellTappedHandler = ^(NSInteger cellIndex) {
        [weakSelf didSelectMediaAssetAtIndex:cellIndex];
    };
    
    self.gridView_.scrollCompletionHandler = ^(MUKGridScrollKind scrollKind)
    {
        [weakSelf loadVisibleThumbnails_];
    };
}

#pragma mark - Private: Accessors

- (UIImage *)videoCellImage_ {
    if (videoCellImage__ == nil) {
        NSURL *imageURL = [MUK URLForImageFileNamed:@"MUKMediaThumbnailView_video.png" bundle:[MUKMediaGalleryUtils_ frameworkBundle]];
        videoCellImage__  = [[UIImage alloc] initWithContentsOfFile:[imageURL path]];
    }
    
    return videoCellImage__;
}

- (UIImage *)audioCellImage_ {
    if (audioCellImage__ == nil) {
        NSURL *imageURL = [MUK URLForImageFileNamed:@"MUKMediaThumbnailView_audio.png" bundle:[MUKMediaGalleryUtils_ frameworkBundle]];
        audioCellImage__  = [[UIImage alloc] initWithContentsOfFile:[imageURL path]];
    }
    
    return audioCellImage__;
}

#pragma mark - Private: Thumbnails

- (UIImage *)userProvidedThumbnailForMediaAsset_:(id<MUKMediaAsset>)mediaAsset provided_:(BOOL *)provided
{
    UIImage *image = nil;
    if ([mediaAsset respondsToSelector:@selector(mediaThumbnail)]) {
        image = [mediaAsset mediaThumbnail];
        
        if (provided != NULL) {
            *provided = YES;
        }
    }
    else {
        if (provided != NULL) {
            *provided = NO;
        }
    }
    
    return image;
}

- (NSURL *)thumbnailURLForMediaAsset_:(id<MUKMediaAsset>)mediaAsset {
    NSURL *url = nil;
    if ([mediaAsset respondsToSelector:@selector(mediaThumbnailURL)]) {
        url = [mediaAsset mediaThumbnailURL];
    }
    
    return url;
}

- (BOOL)thumbnailIsInFileForMediaAsset_:(id<MUKMediaAsset>)mediaAsset {
    return [[self thumbnailURLForMediaAsset_:mediaAsset] isFileURL];
}

- (MUKImageFetcherSearchDomain)searchDomainsForMediaAsset_:(id<MUKMediaAsset>)mediaAsset onlyFromMemory_:(BOOL)onlyFromMemory
{
    // Always search in memory
    MUKImageFetcherSearchDomain searchDomains = MUKImageFetcherSearchDomainMemoryCache;
    
    if (!onlyFromMemory) {
        // Not only memory
        
        if ([self thumbnailIsInFileForMediaAsset_:mediaAsset]) {
            // Thumbnail already on file
            searchDomains |= MUKImageFetcherSearchDomainFile;
        }
        else {
            // Remote thumbnail
            searchDomains |= MUKImageFetcherSearchDomainRemote;
            
            if (self.usesThumbnailImageFileCache) {
                searchDomains |= MUKImageFetcherSearchDomainFileCache;
            }
        }
    }
    
    return searchDomains;
}

- (MUKObjectCacheLocation)cacheLocationsForMediaAsset_:(id<MUKMediaAsset>)mediaAsset
{
    MUKObjectCacheLocation locations = MUKObjectCacheLocationMemory;
    
    if (self.usesThumbnailImageFileCache) {
        // Don't cache to file images which are already in a file
        if (![self thumbnailIsInFileForMediaAsset_:mediaAsset]) {
            locations = locations|MUKObjectCacheLocationFile;
        }
    }
    
    return locations;
}

- (MUKURLConnection *)connectionForMediaAsset_:(id<MUKMediaAsset>)mediaAsset
{
    NSURL *thumbnailURL = [self thumbnailURLForMediaAsset_:mediaAsset];
    if (!thumbnailURL) return nil;
    
    MUKURLConnection *connection = [MUKImageFetcher standardConnectionForImageAtURL:thumbnailURL];
    connection.userInfo = mediaAsset;
    
    return connection;
}

- (void)loadThumbnailForMediaAsset_:(id<MUKMediaAsset>)mediaAsset onlyFromMemory_:(BOOL)onlyFromMemory atIndex_:(NSInteger)index inCell_:(MUKMediaThumbnailView_ *)cell
{
    BOOL userProvidesThumbnail = NO;
    UIImage *userProvidedThumbnail = [self userProvidedThumbnailForMediaAsset_:mediaAsset provided_:&userProvidesThumbnail];
    
    /*
     If user provides thumbnails, exclude automatic loading system.
     */
    if (YES == userProvidesThumbnail) {
        [self setImage:userProvidedThumbnail inCell_:cell];
        return;
    }
    
    /*
     If user does not provide thumbnails, begin with automatic loading.
     
     URL is essential...
     */
    NSURL *thumbnailURL = [self thumbnailURLForMediaAsset_:mediaAsset];
    if (thumbnailURL) {
        MUKImageFetcherSearchDomain searchDomains = [self searchDomainsForMediaAsset_:mediaAsset onlyFromMemory_:onlyFromMemory];
        MUKObjectCacheLocation cacheLocations = [self cacheLocationsForMediaAsset_:mediaAsset];
        
        MUKURLConnection *connection = nil;
        if (!onlyFromMemory) {
            connection = [self connectionForMediaAsset_:mediaAsset];
        }
        
        [self.thumbnailsFetcher loadImageForURL:thumbnailURL searchDomains:searchDomains cacheToLocations:cacheLocations connection:connection completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomains) 
        {
            if (image) {
                // Thumbnail found
                // Insert in right cell at this time
                if (mediaAsset == cell.mediaAsset) {
                    [self setImage:image inCell_:cell];
                }
                else {
                    [self setImage:image inCellAtIndex_:index];
                }
            }
            else {
                [self setImage:nil inCell_:cell];
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
         MUKMediaThumbnailView_ *cell = obj;
         
         // Image is cleared in cellCreationHandler
         // If cell has not an image it should be loaded from any source
         if (![self hasThumbnailInCell_:cell]) {
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

#pragma mark - Private: Media Assets Count View

- (BOOL)shouldShowMediaAssetsCountView_ {
    return (self.displaysMediaAssetsCount && [self.mediaAssets count] > 0);
}

- (void)toggleMediaAssetsCountViewIfNeeded_ {
    if ([self shouldShowMediaAssetsCountView_]) {
        if (self.mediaAssetsCountView_ == nil) {
            self.mediaAssetsCountView_ = [[MUKMediaThumbnailsCountView_ alloc] initWithFrame:CGRectMake(0, 0, 200, kMediaAssetsCountViewHeight)];
        } // if mediaAssetsCountView_ == nil
        
        self.mediaAssetsCountView_.backgroundColor = self.backgroundColor;
        self.gridView_.tailView = self.mediaAssetsCountView_;
    } 
    
    else {
        self.mediaAssetsCountView_ = nil;
        self.gridView_.tailView = nil;
    } // if shouldShowMediaAssetsCountView_
}

- (void)updateMediaAssetsCountViewWithMediaAssets_:(NSArray *)mediaAssets {
    if (self.mediaAssetsCountView_) {
        self.mediaAssetsCountView_.label.text = [self mediaAssetsCountStringForMediaAssets_:mediaAssets];
    }
}

- (NSString *)mediaAssetsCountStringForMediaAssets_:(NSArray *)mediaAssets 
{
    __block NSInteger photosCount = 0, videosCount = 0, audiosCount = 0;
    [mediaAssets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        switch ([(id<MUKMediaAsset>)obj mediaKind]) {
            case MUKMediaAssetKindImage:
                photosCount++;
                break;
            
            case MUKMediaAssetKindVideo:
            case MUKMediaAssetKindYouTubeVideo:
                videosCount++;
                break;
                
            case MUKMediaAssetKindAudio:
                audiosCount++;
                break;
                
            default:
                break;
        }
    }];
    
    NSString* (^stringProducer)(NSInteger, NSString*, NSString *);
    stringProducer = ^(NSInteger count, NSString *singularKey, NSString *pluralKey)
    {
        NSString *string;
        
        if (count == 0) {
            string = nil;
        }
        
        else {
            NSString *suffix;
            
            if (count == 1) {
                suffix = [MUKMediaGalleryUtils_ localizedStringForKey:singularKey comment:singularKey];
            }
            else {
                suffix = [MUKMediaGalleryUtils_ localizedStringForKey:pluralKey comment:pluralKey];
            }
            
            string = [NSString stringWithFormat:@"%i %@",
                      count, [suffix lowercaseString]];
        }

        return string;
    };
    
    // Create chunks
    NSString *photosString = stringProducer(photosCount, @"PHOTO", @"PHOTOS");
    NSString *videosString = stringProducer(videosCount, @"VIDEO", @"VIDEOS");
    NSString *audiosString = stringProducer(audiosCount, @"AUDIO", @"AUDIOS");
    
    // Put chunks together
    NSMutableString *string = [NSMutableString string];
    BOOL insertComma = NO;
    
    if (photosString) {
        [string appendString:photosString];
        insertComma = YES;
    }
    
    if (videosString) {
        if (insertComma) {
            [string appendString:@", "];
        }
        
        [string appendString:videosString];
        insertComma = YES;
    }
    
    if (audiosString) {
        if (insertComma) {
            [string appendString:@", "];
        }
        
        [string appendString:audiosString];
    }
    
    return string;
}

#pragma mark - Private: Layout

- (void)adjustGridView_ {
    CGRect gridFrame = [[self class] gridFrameForBounds_:self.bounds cellSize_:thumbnailSize_ imageOffset_:thumbnailOffset_];
    if (!CGRectEqualToRect(gridFrame, self.gridView_.frame)) {
        self.gridView_.frame = gridFrame;
    }
    
    self.gridView_.contentInset = UIEdgeInsetsMake(self.topPadding, 0, 0, 0);
    self.gridView_.scrollIndicatorInsets = UIEdgeInsetsMake(self.gridView_.contentInset.top, 0, 0, -self.thumbnailOffset.width);
}

+ (CGRect)gridFrameForBounds_:(CGRect)bounds cellSize_:(CGSize)cellSize imageOffset_:(CGSize)imageOffset
{
    CGRect frame = bounds;
    
    // Set same border to right
    frame.size.width -= imageOffset.width;
    
    // How much whitespace?
    NSInteger whiteSpace = (NSInteger)frame.size.width % (NSInteger)cellSize.width;
    
    // Center to divide whitespace
    if (whiteSpace > 0) { 
        frame.origin.x += whiteSpace/2;
        frame.size.width -= whiteSpace;
    }
    
    return frame;
}

#pragma mark - Private: Selection

- (void)selectCellAtIndex_:(NSInteger)index {
    MUKMediaThumbnailView_ *cell = (MUKMediaThumbnailView_ *)[self.gridView_ cellViewAtIndex:index];
    cell.selectionOverlayView.hidden = NO;
    
    self.selectedCellIndex_ = index;
}

- (void)deselectCellAtIndex_:(NSInteger)index {
    MUKMediaThumbnailView_ *cell = (MUKMediaThumbnailView_ *)[self.gridView_ cellViewAtIndex:index];
    cell.selectionOverlayView.hidden = YES;
    
    self.selectedCellIndex_ = -1;
}

#pragma mark - Private: Cells

- (MUKMediaThumbnailView_ *)createThumbnailCell_ {
    MUKMediaThumbnailView_ *cellView = [MUK objectOfClass:[MUKMediaThumbnailView_ class] instantiatedFromNibNamed:nil bundle:[MUKMediaGalleryUtils_ frameworkBundle] owner:nil options:nil atIndex:0];
    return cellView;
}

- (void)configureThumbnailCell_:(MUKMediaThumbnailView_ *)cell withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index
{
    cell.imageOffset = self.thumbnailOffset;
    
    // Don't preserve selection
    cell.selectionOverlayView.hidden = YES;
    
    // Clean thumbnail currently displayed
    [self setImage:nil inCell_:cell];
    
    // Search for thumbnail in cache
    // Only from memory, because async loading is done when view is idle
    [self loadThumbnailForMediaAsset_:mediaAsset onlyFromMemory_:YES atIndex_:index inCell_:cell];    
    
    // Bottom bar configuration
    [self configureThumbnailCellBottomView_:cell withMediaAsset_:mediaAsset atIndex_:index];
}

- (void)configureThumbnailCellBottomView_:(MUKMediaThumbnailView_ *)cell withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index
{
    switch ([mediaAsset mediaKind]) {
        case MUKMediaAssetKindAudio:
            cell.mediaKindImageView.image = self.audioCellImage_;
            cell.bottomView.hidden = NO;
            break;
            
        case MUKMediaAssetKindVideo:
        case MUKMediaAssetKindYouTubeVideo:
            cell.mediaKindImageView.image = self.videoCellImage_;
            cell.bottomView.hidden = NO;
            break;
            
        default:
            cell.mediaKindImageView.image = nil;
            cell.bottomView.hidden = YES;
            break;
    }
    
    NSTimeInterval duration = -1.0;
    if ([mediaAsset respondsToSelector:@selector(mediaDuration)])
    {
        // Could also be <MUKMediaAudioAsset>
        duration = [(id<MUKMediaVideoAsset>)mediaAsset mediaDuration];
    }
    
    // if duration >= 0
    if (duration > -0.00001) {
        cell.durationLabel.text = [MUK stringRepresentationOfTimeInterval:duration];
    }
    else {
        cell.durationLabel.text = nil;
    }
}

- (void)setImage:(UIImage *)image inCellAtIndex_:(NSInteger)index {
    MUKMediaThumbnailView_ *currentCell = (MUKMediaThumbnailView_ *)[self.gridView_ cellViewAtIndex:index];
    [self setImage:image inCell_:currentCell];
}

- (void)setImage:(UIImage *)image inCell_:(MUKMediaThumbnailView_ *)cell {
     cell.imageView.image = image;
}

- (BOOL)hasThumbnailInCell_:(MUKMediaThumbnailView_ *)cell {
    return (cell.imageView.image != nil);
}

@end
