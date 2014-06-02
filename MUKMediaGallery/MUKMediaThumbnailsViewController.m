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
@property (nonatomic) CGRect lastCollectionSuperviewBounds, lastCollectionViewBounds;
@property (nonatomic) NSOperationQueue *thumbnailResizeQueue;

@property (nonatomic) UIBarStyle previousNavigationBarStyle;
@property (nonatomic) UIStatusBarStyle previousStatusBarStyle;
@property (nonatomic) BOOL isTransitioningWithCarouselViewController;
@property (nonatomic) UINavigationBar *observedNavigationBar;
@property (nonatomic, weak) UIViewController *carouselPresentationViewController;
@property (nonatomic) BOOL shouldReloadDataInViewWillAppear, shouldChangeCollectionViewLayoutAtViewDidLayoutSubviews, shouldChangeCollectionViewContentOffsetAtViewDidLayoutSubviews;
@property (nonatomic) CGPoint collectionViewContentOffsetToSetAtViewDidLayoutSubviews;
@end

@implementation MUKMediaThumbnailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        CommonInitialization(self, [[UICollectionViewFlowLayout alloc] init]);
    }
    return self;
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    layout = [[UICollectionViewFlowLayout alloc] init];
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
    [self stopObservingChangesToAdjustTopPadding];
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
        self.previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    }
    else {
        // if coming from carousel, say is not coming from carousel anymore
        self.isTransitioningWithCarouselViewController = NO;
    }
    
    if ([MUKMediaGalleryUtils defaultUIParadigm] == MUKMediaGalleryUIParadigmGlossy)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.wantsFullScreenLayout = YES;
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
#pragma clang diagnostic pop
    }
    else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    }
    
    if (self.shouldReloadDataInViewWillAppear) {
        self.shouldReloadDataInViewWillAppear = NO;
        [self.collectionView reloadData];
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForVisibleItems])
    {
        [self requestLoadingCancellationForImageAtIndexPath:indexPath];
        self.shouldReloadDataInViewWillAppear = YES;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!CGRectIsNull(self.lastCollectionSuperviewBounds)) {
        if (self.lastCollectionSuperviewBounds.size.width != self.collectionView.superview.bounds.size.width)
        {
            // Maintain scrolling ratio
            CGFloat const ratio = self.collectionView.superview.bounds.size.height/self.lastCollectionSuperviewBounds.size.height;
            
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
            
            self.shouldChangeCollectionViewContentOffsetAtViewDidLayoutSubviews = YES;
            self.collectionViewContentOffsetToSetAtViewDidLayoutSubviews = offset;

            // Update layout at -viewDidLayoutSubviews
            self.shouldChangeCollectionViewLayoutAtViewDidLayoutSubviews = YES;
            
            // Hide transition
            [UIView animateWithDuration:0.25 animations:^{
                self.collectionView.alpha = 0.0f;
            } completion:nil];
        }
    }
    
    self.lastCollectionViewBounds = self.collectionView.bounds;
    self.lastCollectionSuperviewBounds = self.collectionView.superview.bounds;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
 
    if (self.shouldChangeCollectionViewLayoutAtViewDidLayoutSubviews) {
        self.shouldChangeCollectionViewLayoutAtViewDidLayoutSubviews = NO;
        
        // Invalidate layout
        __weak MUKMediaThumbnailsViewController *weakSelf = self;
        [self.collectionView performBatchUpdates:nil completion:^(BOOL finished)
        {
            MUKMediaThumbnailsViewController *strongSelf = weakSelf;
            
            // Sometimes collection view goes out of bounds
            strongSelf.collectionView.frame = strongSelf.collectionView.superview.bounds;
            
            // Maintain scrolling ratio
            if (strongSelf.shouldChangeCollectionViewContentOffsetAtViewDidLayoutSubviews)
            {
                strongSelf.shouldChangeCollectionViewContentOffsetAtViewDidLayoutSubviews = NO;
                
                CGPoint const offset = strongSelf.collectionViewContentOffsetToSetAtViewDidLayoutSubviews;
                if (!CGPointEqualToPoint(offset, strongSelf.collectionView.contentOffset))
                {
                    [strongSelf.collectionView setContentOffset:offset animated:NO];
                }
            }
            
            // Restore visibility
            [UIView animateWithDuration:0.1 animations:^{
                strongSelf.collectionView.alpha = 1.0f;
            } completion:nil];
        }];
    }
    
    // Maintain scrolling ratio also when layout has not been invalidated
    else if (self.shouldChangeCollectionViewContentOffsetAtViewDidLayoutSubviews)
    {
        self.shouldChangeCollectionViewContentOffsetAtViewDidLayoutSubviews = NO;
        
        CGPoint const offset = self.collectionViewContentOffsetToSetAtViewDidLayoutSubviews;
        if (!CGPointEqualToPoint(offset, self.collectionView.contentOffset))
        {
            [self.collectionView setContentOffset:offset animated:NO];
        }
    }
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
    self.lastCollectionSuperviewBounds = CGRectNull;

    // Reload collection view
    [self.collectionView reloadData];
}

#pragma mark - Private

static void CommonInitialization(MUKMediaThumbnailsViewController *viewController, UICollectionViewLayout *layout)
{
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        viewController->_thumbnailCellSize = CGSizeMake(104.0f, 104.0f);
        viewController->_thumbnailCellSpacing = 5.0f;
    }
    else {
        viewController->_thumbnailCellSize = CGSizeMake(75.0f, 75.0f);
        viewController->_thumbnailCellSpacing = 4.0f;
    }
    
    // One screen contains ~28 thumbnails on phones: cache more than 5 screens
    // One screen contains ~70 thumbnails on pads: cache more than 3 screens
    NSInteger countLimit;
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        countLimit = 250;
    }
    else {
        countLimit = 150;
    }
    
    viewController.imagesCache = [[MUKMediaModelCache alloc] initWithCountLimit:countLimit cacheNulls:NO];
    viewController.mediaAttributesCache = [[MUKMediaAttributesCache alloc] initWithCountLimit:countLimit cacheNulls:YES];
    
    viewController.loadingImageIndexes = [[NSMutableIndexSet alloc] init];
    
    viewController.thumbnailResizeQueue = [[NSOperationQueue alloc] init];
    viewController.thumbnailResizeQueue.name = @"it.melive.MUKit.MUKMediaGallery.MUKMediaThumbnailsViewController.ThumbnailResizeQueue";
    viewController.thumbnailResizeQueue.maxConcurrentOperationCount = 1;
    
    viewController.lastCollectionViewBounds = CGRectNull;
    viewController.lastCollectionSuperviewBounds = CGRectNull;
    
    if (layout) {
        viewController.collectionView.collectionViewLayout = layout;
    }
}

- (void)requestLoadingCancellationForImageAtIndexPath:(NSIndexPath *)indexPath {
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

#pragma mark - Private — Layout

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
    self.observedNavigationBar = self.navigationController.navigationBar;
    [self.observedNavigationBar addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:(__bridge void *)kNavigationBarBoundsKVOIdentifier];
}

- (void)stopObservingChangesToAdjustTopPadding {
    [self.observedNavigationBar removeObserver:self forKeyPath:@"bounds"];
    self.observedNavigationBar = nil;
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
            __weak MUKMediaThumbnailsViewController *weakSelf = self;
            void (^completionHandler)(UIImage *) = ^(UIImage *image) {
                MUKMediaThumbnailsViewController *strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                
                // If it is still loading...
                if ([strongSelf isLoadingImageAtIndex:kImageIndex]) {
                    // Resize image in a detached queue
                    [strongSelf beginResizingImage:image toThumbnailSize:strongSelf.thumbnailCellSize forItemAtIndexPath:indexPath];
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

#pragma mark - Private — Carousel

- (void)carouselViewControllerDoneBarButtonItemPressed:(id)sender {
    [self.carouselPresentationViewController dismissViewControllerAnimated:YES completion:nil];
    self.carouselPresentationViewController = nil;
}

#pragma mark - <UICollectionViewFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.thumbnailCellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return self.thumbnailCellSpacing/2.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return self.thumbnailCellSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat const availableWidth = CGRectGetWidth(collectionView.superview.frame);
    NSUInteger const cellsPerRow = floorf(availableWidth/self.thumbnailCellSize.width);
    
    CGFloat const usedSpace = (cellsPerRow * self.thumbnailCellSize.width) + ((cellsPerRow - 1) * self.thumbnailCellSpacing);
    CGFloat const margin = (availableWidth - usedSpace) / 2.0;
    
    return UIEdgeInsetsMake(self.thumbnailCellSpacing, margin, self.thumbnailCellSpacing, margin);
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
    [self requestLoadingCancellationForImageAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{    
    if ([self.delegate respondsToSelector:@selector(thumbnailsViewController:carouselToPresentAfterSelectingItemAtIndex:)])
    {
        MUKMediaCarouselViewController *carouselViewController = [self.delegate thumbnailsViewController:self carouselToPresentAfterSelectingItemAtIndex:indexPath.item];
        
        if (carouselViewController) {
            [carouselViewController scrollToItemAtIndex:indexPath.item animated:NO completion:nil];
            
            self.isTransitioningWithCarouselViewController = YES;
            
            MUKMediaThumbnailsViewControllerToCarouselTransition transition = MUKMediaThumbnailsViewControllerToCarouselTransitionPush;
            if ([self.delegate respondsToSelector:@selector(thumbnailsViewController:transitionToPresentCarouselViewController:forItemAtIndex:)])
            {
                transition = [self.delegate thumbnailsViewController:self transitionToPresentCarouselViewController:carouselViewController forItemAtIndex:indexPath.item];
            }
            
            UIViewController *presentationViewController = nil;
            if ([self.delegate respondsToSelector:@selector(thumbnailsViewController:presentationViewControllerForCarouselViewController:forItemAtIndex:)])
            {
                presentationViewController = [self.delegate thumbnailsViewController:self presentationViewControllerForCarouselViewController:carouselViewController forItemAtIndex:indexPath.item];
            }
            
            // Define a local block to choose what to present
            UIViewController *(^viewControllerToPresentBlock)(UIViewController *defaultViewController);
            viewControllerToPresentBlock = ^(UIViewController *defaultViewController){
                // Choose what to present
                UIViewController *viewController = nil;
                if ([self.delegate respondsToSelector:@selector(thumbnailsViewController:viewControllerToPresent:toShowCarouselViewController:forItemAtIndex:)])
                {
                    viewController = [self.delegate thumbnailsViewController:self viewControllerToPresent:defaultViewController toShowCarouselViewController:carouselViewController forItemAtIndex:indexPath.item];
                }
                
                if (![viewController isKindOfClass:[UIViewController class]]) {
                    viewController = defaultViewController;
                }
                
                return viewController;
            };
            
            switch (transition) {
                case MUKMediaThumbnailsViewControllerToCarouselTransitionPush:
                {
                    // Choose presenter
                    UINavigationController *navController = nil;
                    if ([presentationViewController isKindOfClass:[UINavigationController class]])
                    {
                        navController = (UINavigationController *)presentationViewController;
                    }
                    else {
                        navController = self.navigationController;
                    }
                    
                    // Choose what to present
                    UIViewController *viewController = viewControllerToPresentBlock(carouselViewController);

                    // Present it!
                    [navController pushViewController:viewController animated:YES];
                    
                    break;
                }
                    
                case MUKMediaThumbnailsViewControllerToCarouselTransitionCoverVertical:
                case MUKMediaThumbnailsViewControllerToCarouselTransitionCrossDissolve:
                {
                    if (![presentationViewController respondsToSelector:@selector(presentViewController:animated:completion:)])
                    {
                        presentationViewController = self;
                    }
                    
                    // Create a button to close modal presentation
                    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(carouselViewControllerDoneBarButtonItemPressed:)];
                    carouselViewController.navigationItem.leftBarButtonItem = doneBarButtonItem;
                    
                    // Embed in navigation controller
                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:carouselViewController];
                    navController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
                    
                    // Choose what to present
                    UIViewController *viewController = viewControllerToPresentBlock(navController);
                    
                    // Choose transition style
                    if (transition == MUKMediaThumbnailsViewControllerToCarouselTransitionCrossDissolve)
                    {
                        viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    }
                    
                    // Present it!
                    self.carouselPresentationViewController = presentationViewController;
                    [presentationViewController presentViewController:viewController animated:YES completion:nil];
                    
                    break;
                }
                    
                default:
                    break;
            } // switch
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
