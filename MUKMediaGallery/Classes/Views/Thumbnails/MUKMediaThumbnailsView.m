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

#import <MUKScrolling/MUKScrolling.h>
#import <MUKToolkit/MUKToolkit.h>
#import "MUKMediaGalleryUtils_.h"

@interface MUKMediaThumbnailsView ()
@property (nonatomic, strong, readwrite) MUKURLConnectionQueue *thumbnailDownloadQueue;
@property (nonatomic, strong) MUKGridView *gridView_;

- (void)commonInitialization_;
@end

@implementation MUKMediaThumbnailsView
@synthesize mediaAssets = mediaAssets_;
@synthesize thumbnailImageCache = thumbnailImageCache_;
@synthesize usesThumbnailImageFileCache = usesThumbnailImageFileCache_;
@synthesize thumbnailDownloadQueue = thumbnailDownloadQueue_;
@synthesize thumbnailSize = thumbnailSize_;
@synthesize thumbnailOffset = thumbnailOffset_;
@synthesize displaysMediaAssetsCount = displaysMediaAssetsCount_;
@synthesize topPadding = topPadding_;

@synthesize thumbnailDownloadRequestHandler = thumbnailDownloadRequestHandler_;

@synthesize mediaAssetsCountView_ = mediaAssetsCountView__;
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
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSLog(@"%@", [self.gridView_ visibleViews]);
        });
    }
    return self;
}

- (void)dealloc {
    thumbnailImageCache_.fileCacheURLHandler = nil;
    thumbnailImageCache_.fileCachedDataTransformer = nil;
    thumbnailImageCache_.fileCachedObjectTransformer = nil;
    
    thumbnailDownloadQueue_.connectionWillStartHandler = nil;
    
    [self.gridView_ removeAllHandlers];
}

#pragma mark - Overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    [self adjustGridView_];
}

#pragma mark - Accessors

- (MUKObjectCache *)thumbnailImageCache {
    if (thumbnailImageCache_ == nil) {
        thumbnailImageCache_ = [[MUKObjectCache alloc] init];
    }
    
    return thumbnailImageCache_;
}

- (MUKURLConnectionQueue *)thumbnailDownloadQueue {
    if (thumbnailDownloadQueue_ == nil) {
        thumbnailDownloadQueue_ = [[MUKURLConnectionQueue alloc] init];
        thumbnailDownloadQueue_.maximumConcurrentConnections = 2;
        
        __unsafe_unretained MUKMediaThumbnailsView *weakSelf = self;
        thumbnailDownloadQueue_.connectionWillStartHandler = ^(MUKURLConnection * connection)
        {
            id<MUKMediaAsset> mediaAsset = connection.userInfo;
            NSInteger assetIndex = [weakSelf.mediaAssets indexOfObject:mediaAsset];
            
            NSIndexSet *visibleAssetsIndexes = [weakSelf.gridView_ indexesOfVisibleCells];
            BOOL assetVisible = [visibleAssetsIndexes containsIndex:assetIndex];
            
            if (!assetVisible) {
                // If asset is hidden, cancel download
                [connection cancel];
            }
        };
        
        thumbnailDownloadQueue_.connectionDidFinishHandler = ^(MUKURLConnection *connection, BOOL cancelled)
        {
            // Break cycles
            if (cancelled) {
                connection.completionHandler = nil;
            }
        };
    }
    
    return thumbnailDownloadQueue_;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.gridView_.backgroundColor = backgroundColor;
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
    [self.gridView_ reloadData];
}

#pragma mark - Thumbnail Download

- (NSURLRequest *)requestForMediaAsset:(id<MUKMediaAsset>)mediaAsset {
    NSURLRequest *request = nil;
    
    if (self.thumbnailDownloadRequestHandler) {
        request = self.thumbnailDownloadRequestHandler(mediaAsset);
    }
    
    if (request == nil) {
        request = [[NSURLRequest alloc] initWithURL:[mediaAsset mediaThumbnailURL]];
    }
    
    return request;
}

#pragma mark - Private

- (void)commonInitialization_ {
    thumbnailSize_ = CGSizeMake(79, 79);
    thumbnailOffset_ = CGSizeMake(4, 4);
    
    CGRect gridFrame = [[self class] gridFrameForBounds_:self.bounds cellSize_:thumbnailSize_ imageOffset_:thumbnailOffset_];
    self.gridView_ = [[MUKGridView alloc] initWithFrame:gridFrame];
    
    self.gridView_.alwaysBounceVertical = YES;
    self.gridView_.clipsToBounds = NO;
    self.gridView_.backgroundColor = self.backgroundColor;
    self.gridView_.direction = MUKGridDirectionVertical;
    
    self.gridView_.cellSize = [[MUKGridCellFixedSize alloc] initWithSize:thumbnailSize_];
        
    displaysMediaAssetsCount_ = YES;
    // Don't insert here, because we have 0 assets
    
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
        [weakSelf configureThumbnailCell_:cellView atIndex_:cellIndex];
        
        return cellView;
    };
    
    [self addSubview:self.gridView_];

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

- (NSString *)cacheKeyForMediaAsset_:(id<MUKMediaAsset>)mediaAsset {
    return [[self thumbnailURLForMediaAsset_:mediaAsset] absoluteString];
}

- (void)loadThumbnailForMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index inCell_:(MUKMediaThumbnailView_ *)cell
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
        NSString *cacheKey = [self cacheKeyForMediaAsset_:mediaAsset];
        MUKObjectCacheLocation cacheLocations = [self cacheLocationsForMediaAsset_:mediaAsset];
        
        [self.thumbnailImageCache loadObjectForKey:cacheKey locations:cacheLocations completionHandler:^(id object, MUKObjectCacheLocation location)
         {
             if (object) {
                 // Thumbnail found
                 
                 if (MUKObjectCacheLocationFile == location) {
                     // Thumbnail found on file
                     // Cache to memory to speed up access next time
                     [self.thumbnailImageCache saveObject:object forKey:cacheKey locations:MUKObjectCacheLocationMemory completionHandler:nil];
                     
                     // Insert in right cell at this time
                     [self setImage:object inCellAtIndex_:index];
                 }       
                 
                 else if (MUKObjectCacheLocationMemory) {
                     // Insert synchronously
                     [self setImage:object inCell_:cell];
                 }
             }
             
             else {
                 // Thumbnail not found
                 // Get it
                 
                 if ([self thumbnailIsInFileForMediaAsset_:mediaAsset]) {
                     // Load from file and save to cache
                     dispatch_queue_t queue = dispatch_queue_create("it.melive.mukit.MUKMediaThumbnailsView.ImageLoading", NULL);
                     dispatch_async(queue, ^{
                         UIImage *image = [[UIImage alloc] initWithContentsOfFile:[thumbnailURL path]];
                         
                         dispatch_async(dispatch_get_main_queue(), ^{
                             // Insert in right cell at this time (on main queue)
                             [self setImage:image inCellAtIndex_:index];
                             
                             // Cache it to memory
                             [self.thumbnailImageCache saveObject:image forKey:cacheKey locations:MUKObjectCacheLocationMemory completionHandler:nil];
                         });
                     });
                     
                     // Dispose queue
                     dispatch_release(queue);
                 }
                 
                 else {
                     // Download
                     [self downloadThumbnailForMediaAsset_:mediaAsset atIndex_:index];
                 }
             }
         }];
    }
    else {
        // No URL
        [self setImage:nil inCell_:cell];
    }
}

- (void)downloadThumbnailForMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index
{
    NSString *cacheKey = [self cacheKeyForMediaAsset_:mediaAsset];
    MUKObjectCacheLocation cacheLocations = [self cacheLocationsForMediaAsset_:mediaAsset];
    
    NSURLRequest *request = [self requestForMediaAsset:mediaAsset];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    connection.runsInBackground = YES;
    connection.userInfo = mediaAsset;
    
    MUKURLConnection *strongConnection = connection;
    connection.completionHandler = ^(BOOL success, NSError *error)
    {
        if (success) {
            NSData *data = [strongConnection bufferedData];
            UIImage *image = [[UIImage alloc] initWithData:data];
            
            // Cache image
            [self.thumbnailImageCache saveObject:image forKey:cacheKey locations:cacheLocations completionHandler:nil];
            
            // Insert thumbnail
            // Cell at this moment can represent a different index
            // because scrolling has gone on
            [self setImage:image inCellAtIndex_:index];
        }
        
        // Break cycle
        strongConnection.completionHandler = nil;
    }; // connection's completionHandler
    
    // Enqueue connection
    [self.thumbnailDownloadQueue addConnection:connection];
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

#pragma mark - Cells

- (MUKMediaThumbnailView_ *)createThumbnailCell_ {
    MUKMediaThumbnailView_ *cellView = [MUK objectOfClass:[MUKMediaThumbnailView_ class] instantiatedFromNibNamed:nil bundle:[MUKMediaGalleryUtils_ frameworkBundle] owner:nil options:nil atIndex:0];
    return cellView;
}

- (void)configureThumbnailCell_:(MUKMediaThumbnailView_ *)cell atIndex_:(NSInteger)index
{
    id<MUKMediaAsset> mediaAsset = [MUK array:self.mediaAssets objectAtIndex:index];
    [self configureThumbnailCell_:cell withMediaAsset_:mediaAsset atIndex_:index];
}

- (void)configureThumbnailCell_:(MUKMediaThumbnailView_ *)cell withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index
{
    // Clean thumbnail currently displayed
    [self setImage:nil inCell_:cell];
    
    // Search for thumbnail in cache
    [self loadThumbnailForMediaAsset_:mediaAsset atIndex_:index inCell_:cell];    
    
    // Bottom bar configuration
    [self configureThumbnailCellBottomView_:cell withMediaAsset_:mediaAsset atIndex_:index];
}

- (void)configureThumbnailCellBottomView_:(MUKMediaThumbnailView_ *)cell withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index
{
    switch ([mediaAsset mediaKind]) {
        case MUKMediaAssetKindAudio:
        case MUKMediaAssetKindVideo:
        case MUKMediaAssetKindYouTubeVideo: {
            cell.bottomView.hidden = NO;
            break;
        }
            
        default: {
            cell.bottomView.hidden = YES;
            break;
        }
    }
}

- (void)setImage:(UIImage *)image inCellAtIndex_:(NSInteger)index {
    MUKMediaThumbnailView_ *currentCell = (MUKMediaThumbnailView_ *)[self.gridView_ cellViewAtIndex:index];
    [self setImage:image inCell_:currentCell];
}

- (void)setImage:(UIImage *)image inCell_:(MUKMediaThumbnailView_ *)cell {
     cell.imageView.image = image;
}

@end
