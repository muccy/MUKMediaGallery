#import "MUKMediaThumbnailsViewController.h"
#import "MUKMediaThumbnailCell.h"
#import "MUKMediaAttributesCache.h"
#import "MUKMediaGalleryUtils.h"
#import "MUKMediaGalleryImageResizeOperation.h"
#import "MUKMediaCarouselViewController.h"

static NSString *const kCellIdentifier = @"MUKMediaThumbnailCell";

static NSString *const kNavigationBarBoundsKVOIdentifier = @"NavigationBarFrameKVOIdentifier";

@interface MUKMediaThumbnailsViewController () <MUKMediaGalleryImageResizeOperationDrawingDelegate>
@property (nonatomic) MUKMediaModelCache *imagesCache;
@property (nonatomic) MUKMediaAttributesCache *mediaAttributesCache;
@property (nonatomic) NSMutableIndexSet *loadingImageIndexes;
@property (nonatomic) CGRect lastCollectionViewBounds;
@property (nonatomic) NSOperationQueue *thumbnailResizeQueue;

@property (nonatomic) UIBarStyle previousNavigationBarStyle;
@property (nonatomic) UIStatusBarStyle previousStatusBarStyle;
@property (nonatomic) BOOL isTransitioningWithCarouselViewController;
@property (nonatomic) BOOL isObservingChangesToAdjustTopPadding;
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

- (void)dealloc {
    if (self.isObservingChangesToAdjustTopPadding) {
        [self stopObservingChangesToAdjustTopPadding];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[MUKMediaThumbnailCell class] forCellWithReuseIdentifier:kCellIdentifier];
    
    if (![self automaticallyAdjustsTopPadding]) {
        [self adjustTopPadding];
        [self beginObservingChangesToAdjustTopPadding];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.isTransitioningWithCarouselViewController) {
        // if not coming from carousel, save past bar styles
        self.previousNavigationBarStyle = self.navigationController.navigationBar.barStyle;
        self.previousNavigationBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    }
    else {
        // if coming from carousel, say is not coming from carousel anymore
        self.isTransitioningWithCarouselViewController = NO;
    }
    
    if ([MUKMediaGalleryUtils defaultUIParadigm] == MUKMediaGalleryUIParadigmGlossy)
    {
        self.wantsFullScreenLayout = YES;
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
    }
    else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (!self.isTransitioningWithCarouselViewController) {
        // If not transitioning to carousel, reset past bar values
        
        if ([MUKMediaGalleryUtils defaultUIParadigm] == MUKMediaGalleryUIParadigmGlossy)
        {
            self.navigationController.navigationBar.barStyle = self.previousNavigationBarStyle;
            [[UIApplication sharedApplication] setStatusBarStyle:self.previousStatusBarStyle animated:animated];
        }
        else {
            self.navigationController.navigationBar.barStyle = self.previousNavigationBarStyle;
        }
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!CGRectIsNull(self.lastCollectionViewBounds)) {
        if (!CGSizeEqualToSize(self.lastCollectionViewBounds.size, self.collectionView.bounds.size))
        {
            CGFloat const ratio = self.collectionView.bounds.size.height/self.lastCollectionViewBounds.size.height;
            
            CGPoint offset;
            if ([MUKMediaGalleryUtils defaultUIParadigm] == MUKMediaGalleryUIParadigmLayered)
            {
                // Value stored in self.collectionView.contentOffset is already
                // changed at this moment: use bounds instead (on iOS 7 and over)
                offset = self.lastCollectionViewBounds.origin;
            }
            else {
                offset = self.collectionView.contentOffset;
            }
            
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
}

#pragma mark - Methods

- (void)reloadData {
    // Empty caches
    [self.imagesCache.cache removeAllObjects];
    [self.mediaAttributesCache.cache removeAllObjects];
    
    // Mark every image as not loaded
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
    // One screen contains ~28 thumbnails: cache more than 5 screens
    viewController.imagesCache = [[MUKMediaModelCache alloc] initWithCountLimit:150 cacheNulls:NO];
    viewController.mediaAttributesCache = [[MUKMediaAttributesCache alloc] initWithCountLimit:150 cacheNulls:YES];
    
    viewController.loadingImageIndexes = [[NSMutableIndexSet alloc] init];
    
    viewController.thumbnailResizeQueue = [[NSOperationQueue alloc] init];
    viewController.thumbnailResizeQueue.name = @"it.melive.MUKit.MUKMediaGallery.MUKMediaThumbnailsViewController.ThumbnailResizeQueue";
    viewController.thumbnailResizeQueue.maxConcurrentOperationCount = 1;
    
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

- (BOOL)automaticallyAdjustsTopPadding {
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)])
    {
        return self.automaticallyAdjustsScrollViewInsets;
    }
    
    return NO;
}

- (CGFloat)topPadding {
    CGFloat statusBarHeight;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
    {
        statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
    else {
        statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.width;
    }
    
    CGFloat topPadding = statusBarHeight + self.navigationController.navigationBar.bounds.size.height;
    return topPadding;
}

- (void)adjustTopPadding {
    CGFloat topPadding = [self topPadding];
    CGFloat diff = topPadding - self.collectionView.contentInset.top;
    
    if (ABS(diff) > 0.0f) {
        UIEdgeInsets insets = UIEdgeInsetsMake(topPadding, 0.0f, 0.0f, 0.0f);
        self.collectionView.contentInset = insets;
        self.collectionView.scrollIndicatorInsets = insets;
        
        CGPoint offset = self.collectionView.contentOffset;
        offset.y -= diff;
        self.collectionView.contentOffset = offset;
    }
}

#pragma mark - Private — KVO

- (void)beginObservingChangesToAdjustTopPadding {
    self.isObservingChangesToAdjustTopPadding = YES;
    [self.navigationController addObserver:self forKeyPath:@"navigationBar.bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:(__bridge void *)kNavigationBarBoundsKVOIdentifier];
}

- (void)stopObservingChangesToAdjustTopPadding {
    self.isObservingChangesToAdjustTopPadding = NO;
    [self.navigationController removeObserver:self forKeyPath:@"navigationBar.bounds"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void *)kNavigationBarBoundsKVOIdentifier) {
        CGRect old = [change[NSKeyValueChangeOldKey] CGRectValue];
        CGRect new = [change[NSKeyValueChangeNewKey] CGRectValue];
        
        if (!CGSizeEqualToSize(old.size, new.size)) {
            [self adjustTopPadding];
        }
    }
}

#pragma mark - Private — Images

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
    
    // Try to load from cache
    UIImage *image = [self.imagesCache objectAtIndex:kImageIndex isNull:NULL];

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
        [self.imagesCache setObject:resizedImage atIndex:kImageIndex];
        
        // Take actual cell and set image
        MUKMediaThumbnailCell *actualCell = (MUKMediaThumbnailCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self setImage:resizedImage inThumbnailCell:actualCell];
    }
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
    MUKMediaAttributes *attributes = [self.mediaAttributesCache mediaAttributesAtIndex:indexPath.item cacheIfNeeded:YES loadingHandler:^MUKMediaAttributes *
    {
        if ([self.delegate respondsToSelector:@selector(thumbnailsViewController:attributesForItemAtIndex:)])
        {
            return [self.delegate thumbnailsViewController:self attributesForItemAtIndex:indexPath.item];
        }
        
        return nil;
    }];
    
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

#pragma mark - <UICollectionViewDelegate>

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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{    
    if ([self.delegate respondsToSelector:@selector(thumbnailsViewController:carouselToPushAfterSelectingItemAtIndex:)])
    {
        MUKMediaCarouselViewController *carouselViewController = [self.delegate thumbnailsViewController:self carouselToPushAfterSelectingItemAtIndex:indexPath.item];
        [carouselViewController scrollToItemAtIndex:indexPath.item animated:NO];
        
        if (carouselViewController) {
            self.isTransitioningWithCarouselViewController = YES;
            [self.navigationController pushViewController:carouselViewController animated:YES];
        }
    }
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
