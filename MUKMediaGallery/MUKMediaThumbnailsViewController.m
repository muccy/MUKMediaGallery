#import "MUKMediaThumbnailsViewController.h"
#import "MUKMediaThumbnailCell.h"
#import "MUKMediaAttributes.h"
#import "MUKMediaGalleryUtils.h"
#import "MUKMediaGalleryImageResizeOperation.h"

static NSString *const kCellIdentifier = @"MUKMediaThumbnailCell";

@interface MUKMediaThumbnailsViewController () <MUKMediaGalleryImageResizeOperationDrawingDelegate>
@property (nonatomic) NSCache *imagesCache;
@property (nonatomic) NSMutableIndexSet *loadingImageIndexes;
@property (nonatomic) NSCache *mediaAttributesCache;
@property (nonatomic) CGRect lastCollectionViewBounds;
@property (nonatomic) NSOperationQueue *thumbnailResizeQueue;
@end

@implementation MUKMediaThumbnailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        CommonInitialization(self, [[self class] newGridLayout]);
    }
    return self;
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    layout = [[self class] newGridLayout];
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        CommonInitialization(self, nil);
    }
    
    return self;
}

- (id)init {
    return [self initWithCollectionViewLayout:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[MUKMediaThumbnailCell class] forCellWithReuseIdentifier:kCellIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    // Just to be sure...
    [self.imagesCache removeAllObjects];
    [self.mediaAttributesCache removeAllObjects];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!CGRectIsNull(self.lastCollectionViewBounds)) {
        if (!CGSizeEqualToSize(self.lastCollectionViewBounds.size, self.collectionView.bounds.size))
        {
            CGFloat const ratio = self.collectionView.bounds.size.height/self.lastCollectionViewBounds.size.height;
            
            // Value stored in self.collectionView.contentOffset is already
            // changed at this moment: use bounds instead
            CGPoint offset = self.lastCollectionViewBounds.origin;
            
            // Don't include insets into calculations
            offset.y = ((offset.y + self.collectionView.contentInset.top) * ratio) - self.collectionView.contentInset.top;
            
            // Performance check
            if (!CGPointEqualToPoint(offset, self.collectionView.contentOffset)) {
                [self.collectionView setContentOffset:offset animated:NO];
            }
        }
    }
    
    self.lastCollectionViewBounds = self.collectionView.bounds;
}

#pragma mark - Methods

- (void)reloadData {
    // Empty caches
    [self.imagesCache removeAllObjects];
    [self.mediaAttributesCache removeAllObjects];
    
    // Cancel loading images
    if ([self.delegate respondsToSelector:@selector(thumbnailsViewController:cancelLoadingForImageAtIndex:)])
    {
        // Request delegate to cancel every load in progress
        [self.loadingImageIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
        {
            [self.delegate thumbnailsViewController:self cancelLoadingForImageAtIndex:idx];
        }];
    }
    [self.loadingImageIndexes removeAllIndexes];
    
    // Cancel every resize in progress
    [self.thumbnailResizeQueue cancelAllOperations];
    
    // Reset initial values
    self.lastCollectionViewBounds = CGRectNull;

    // Reload collection view
    [self.collectionView reloadData];
}

#pragma mark - Private

static void CommonInitialization(MUKMediaThumbnailsViewController *viewController, UICollectionViewLayout *layout)
{
    viewController.imagesCache = [[NSCache alloc] init];
    // One screen contains ~28 thumbnails: cache more than 5 screens
    viewController.imagesCache.countLimit = 150;
    
    viewController.mediaAttributesCache = [[NSCache alloc] init];
    viewController.mediaAttributesCache.countLimit = 150;
    
    viewController.loadingImageIndexes = [[NSMutableIndexSet alloc] init];
    viewController.thumbnailResizeQueue = [[NSOperationQueue alloc] init];

    viewController.lastCollectionViewBounds = CGRectNull;
    
    if (layout) {
        viewController.collectionView.collectionViewLayout = layout;
    }
}

#pragma mark - Private — Layout

+ (UICollectionViewFlowLayout *)newGridLayout {
    UICollectionViewFlowLayout *grid = [[UICollectionViewFlowLayout alloc] init];
    grid.itemSize = [self thumbnailSize];
    grid.minimumInteritemSpacing = 4.0f;
    grid.minimumLineSpacing = 4.0f;
    grid.sectionInset = UIEdgeInsetsMake(4.0f, 4.0f, 4.0f, 4.0f);
    
    return grid;
}

+ (CGSize)thumbnailSize {
    return CGSizeMake(75.0f, 75.0f);
}

#pragma mark - Private — Images

- (UIImage *)loadedImageAtIndex:(NSInteger)index {
    return [self.imagesCache objectForKey:@(index)];
}

- (void)cacheLoadedImage:(UIImage *)image atIndex:(NSInteger)index {
    if (image == nil) {
        return;
    }
    
    [self.imagesCache setObject:image forKey:@(index)];
}

- (BOOL)isLoadingImageAtIndex:(NSInteger)index {
    return [self.loadingImageIndexes containsIndex:index];
}

- (void)setLoading:(BOOL)loading imageAtIndex:(NSInteger)index {
    if (loading) {
        [self.loadingImageIndexes addIndex:index];
    }
    else {
        [self.loadingImageIndexes removeIndex:index];
    }
}

- (UIImage *)cachedImageOrRequestLoadingForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger const kImageIndex = indexPath.item;
    UIImage *image = [self loadedImageAtIndex:kImageIndex]; // Try to load from cache

    // If no image is cached, check if it's loading
    if (image == nil) {
        // If it's not loading, request an image
        if ([self isLoadingImageAtIndex:kImageIndex] == NO) {
            // Mark as loading
            [self setLoading:YES imageAtIndex:kImageIndex];
            
            // This block is called by delegate which can give back an image
            // asynchronously
            void (^completionHandler)(UIImage *) = ^(UIImage *image) {
                // If it is still loading...
                if ([self isLoadingImageAtIndex:kImageIndex]) {
                    // Resize image in a detached queue
                    [self beginResizingImage:image toThumbnailSize:[[self class] thumbnailSize] forItemAtIndexPath:indexPath];
                }
            };
            
            [self.delegate thumbnailsViewController:self loadImageForItemAtIndex:kImageIndex completionHandler:completionHandler];
        }
    }
    
    return image;
}

- (void)beginResizingImage:(UIImage *)image toThumbnailSize:(CGSize)size forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!image) {
        [self didFinishResizingImage:nil forItemAtIndexPath:indexPath cancelled:NO];
        return;
    }
    
    MUKMediaGalleryImageResizeOperation *op = [[MUKMediaGalleryImageResizeOperation alloc] init];
    op.boundingSize = size;
    op.sourceImage = image;
    op.userInfo = indexPath;
    op.drawingDelegate = self;
    
    __weak MUKMediaGalleryImageResizeOperation *weakOp = op;
    __weak MUKMediaThumbnailsViewController *weakSelf = self;
    op.completionBlock = ^{
        MUKMediaGalleryImageResizeOperation *strongOp = weakOp;
        MUKMediaThumbnailsViewController *strongSelf = weakSelf;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf didFinishResizingImage:strongOp.resizedImage forItemAtIndexPath:indexPath cancelled:[strongOp isCancelled]];
        });
    };
    
    [self.thumbnailResizeQueue addOperation:op];
}

- (void)cancelImageResizingForItemAtIndexPath:(NSIndexPath *)indexPath {
    for (MUKMediaGalleryImageResizeOperation *op in self.thumbnailResizeQueue.operations)
    {
        if ([(NSIndexPath *)op.userInfo isEqual:indexPath]) {
            [op cancel];
            break;
        }
    }
}

- (void)didFinishResizingImage:(UIImage *)resizedImage forItemAtIndexPath:(NSIndexPath *)indexPath cancelled:(BOOL)cancelled
{
    NSInteger const kImageIndex = indexPath.item;
    
    // Set image as not loading
    [self setLoading:NO imageAtIndex:kImageIndex];
    
    if (!cancelled) {
        // Cache resized image
        [self cacheLoadedImage:resizedImage atIndex:kImageIndex];
        
        // Take actual cell and set image
        MUKMediaThumbnailCell *actualCell = (MUKMediaThumbnailCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self setImage:resizedImage inThumbnailCell:actualCell];
    }
}

#pragma mark - Private — Media Attributes

- (MUKMediaAttributes *)mediaAttributesAtIndex:(NSInteger)index cacheIfNeeded:(BOOL)cache
{
    BOOL nullAttributes = NO;
    MUKMediaAttributes *attributes = [self cachedMediaAttributesAtIndex:index nullAttributes:&nullAttributes];
    
    // User has chosen for this index
    if (attributes || nullAttributes) {
        return attributes;
    }
    
    // At this point attributes == nil for sure
    // Load from delegate!
    
    if ([self.delegate respondsToSelector:@selector(thumbnailsViewController:attributesForItemAtIndex:)])
    {
        attributes = [self.delegate thumbnailsViewController:self attributesForItemAtIndex:index];
    }
    
    // Should cache it?
    if (cache) {
        [self cacheMediaAttributes:attributes atIndex:index];
    }
    
    return attributes;
}

- (MUKMediaAttributes *)cachedMediaAttributesAtIndex:(NSInteger)index nullAttributes:(BOOL *)nullAttributes
{
    id cachedObject = [self.mediaAttributesCache objectForKey:@(index)];
    MUKMediaAttributes *attributes;
    
    if (cachedObject == [NSNull null]) {
        if (nullAttributes != NULL) {
            *nullAttributes = YES;
        }
        
        attributes = nil;
    }
    else {
        if (nullAttributes != NULL) {
            *nullAttributes = NO;
        }
        
        attributes = cachedObject;
    }
    
    return attributes;
}

- (void)cacheMediaAttributes:(MUKMediaAttributes *)attributes atIndex:(NSInteger)index {
    id objectToCache = attributes;
    
    if (objectToCache == nil) {
        objectToCache = [NSNull null];
    }
    
    [self.mediaAttributesCache setObject:objectToCache forKey:@(index)];
}

#pragma mark - Private — Cell

- (void)configureThumbnailCell:(MUKMediaThumbnailCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    
    // Get cached image or request it to delegate
    UIImage *image = [self cachedImageOrRequestLoadingForItemAtIndexPath:indexPath];
    
    // Anyway set the image, also if it's nil
    [self setImage:image inThumbnailCell:cell];
    
    // Configure bottom view of cell
    [self configureBottomViewInThumbnailCell:cell atIndexPath:indexPath];
}

- (void)setImage:(UIImage *)image inThumbnailCell:(MUKMediaThumbnailCell *)cell {
    cell.imageView.image = image;
}

- (void)configureBottomViewInThumbnailCell:(MUKMediaThumbnailCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    MUKMediaAttributes *attributes = [self mediaAttributesAtIndex:indexPath.item cacheIfNeeded:YES];
    cell.bottomView.hidden = (attributes == nil || (attributes.kind == MUKMediaKindImage && [attributes.caption length] == 0));
    cell.bottomIconImageView.image = [self thumbnailCellBottomViewIconForMediaAttributes:attributes];
    cell.captionLabel.text = attributes.caption;
}

- (UIImage *)thumbnailCellBottomViewIconForMediaAttributes:(MUKMediaAttributes *)attributes
{
    if (attributes == nil) {
        return nil;
    }
    
    UIImage *icon;
    
    switch (attributes.kind) {
        case MUKMediaKindAudio:
            icon = [MUKMediaGalleryUtils imageNamed:@"audio_small"];
            break;
            
        case MUKMediaKindVideo:
        case MUKMediaKindYouTubeVideo:
            icon = [MUKMediaGalleryUtils imageNamed:@"video_small"];
            break;
            
        default:
            icon = nil;
            break;
    }
    
    return icon;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.delegate numberOfItemsInThumbnailsViewController:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MUKMediaThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    [self configureThumbnailCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(thumbnailsViewController:cancelLoadingForImageAtIndex:)])
    {
        NSInteger const kImageIndex = indexPath.item;

        if ([self isLoadingImageAtIndex:kImageIndex]) {
            [self.delegate thumbnailsViewController:self cancelLoadingForImageAtIndex:kImageIndex];
            
            // Mark as not loading
            [self setLoading:NO imageAtIndex:kImageIndex];
            
            // Cancel image resizing
            [self cancelImageResizingForItemAtIndexPath:indexPath];
            
        } // if -isLoadingImageAtIndex:
    } // if delegate responds
}

#pragma mark - <MUKMediaGalleryImageResizeOperationDrawingDelegate>

- (void)imageResizeOperation:(MUKMediaGalleryImageResizeOperation *)op drawOverResizedImageInContext:(CGContextRef)ctx
{
    // Draw a border over the image    
    CGRect rect = CGRectZero;
    rect.size = op.boundingSize;
    [MUKMediaThumbnailCell drawBorderInsideRect:rect context:ctx];
}

@end
