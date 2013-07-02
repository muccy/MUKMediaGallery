#import "MUKMediaCarouselViewController.h"
#import "MUKMediaCarouselFullImageCell.h"
#import "MUKMediaCarouselPlayerCell.h"
#import "MUKMediaAttributesCache.h"
#import "MUKMediaCarouselFlowLayout.h"
#import "MUKMediaGalleryUtils.h"

static NSString *const kFullImageCellIdentifier = @"MUKMediaFullImageCell";
static NSString *const kMediaPlayerCellIdentifier = @"MUKMediaPlayerCell";
static NSString *const kBoundsChangesKVOIdentifier = @"BoundsChangesKVOIdentifier";
static CGFloat const kLateralPadding = 4.0f;

@interface MUKMediaCarouselViewController () <MUKMediaCarouselFullImageCellDelegate, MUKMediaCarouselPlayerCellDelegate>
@property (nonatomic) MUKMediaAttributesCache *mediaAttributesCache;
@property (nonatomic) MUKMediaModelCache *imagesCache, *thumbnailImagesCache;
@property (nonatomic) NSMutableIndexSet *loadingImageIndexes, *loadingThumbnailImageIndexes;
@property (nonatomic) CGRect lastCollectionViewBounds;
@property (nonatomic) BOOL isObservingBoundsChanges;
@property (nonatomic) NSInteger itemIndexToMantainAfterBoundsChange;
@property (nonatomic) BOOL hasPendingScrollToItem;
@end

@implementation MUKMediaCarouselViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        CommonInitialization(self, [[self class] newCarouselLayout]);
    }
    
    return self;
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    layout = [[self class] newCarouselLayout];
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
    [self stopObservingBoundsChangesIfNeeded];
    
    for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
        if ([cell isKindOfClass:[MUKMediaCarouselPlayerCell class]]) {
            [self cancelMediaPlaybackInPlayerCell:(MUKMediaCarouselPlayerCell *)cell];
        }
    } // for
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    [self.collectionView registerClass:[MUKMediaCarouselFullImageCell class] forCellWithReuseIdentifier:kFullImageCellIdentifier];
    [self.collectionView registerClass:[MUKMediaCarouselPlayerCell class] forCellWithReuseIdentifier:kMediaPlayerCellIdentifier];
    
    if (self.hasPendingScrollToItem) {
        self.hasPendingScrollToItem = NO;
        [self scrollToItemAtIndex:self.itemIndexToMantainAfterBoundsChange animated:NO];
    }

    // This adjust things prior rotation
    [self beginObservingBoundsChanges];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Overrides

- (BOOL)prefersStatusBarHidden {
    return self.navigationController.isNavigationBarHidden;
}

#pragma mark - Methods

- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (![self isViewLoaded]) {
        self.hasPendingScrollToItem = YES;
        self.itemIndexToMantainAfterBoundsChange = index;
        return;
    }

    CGFloat pageWidth = [MUKMediaCarouselFlowLayout fullPageWidthForFrame:self.collectionView.frame spacing:kLateralPadding * 2.0f];
    [self.collectionView setContentOffset:CGPointMake(pageWidth * index, 0.0f) animated:animated];
}

#pragma mark - Private

static void CommonInitialization(MUKMediaCarouselViewController *viewController, UICollectionViewLayout *layout)
{
    viewController.automaticallyAdjustsScrollViewInsets = NO;
    
    viewController.imagesCache = [[MUKMediaModelCache alloc] initWithCountLimit:3 cacheNulls:NO];
    viewController.thumbnailImagesCache = [[MUKMediaModelCache alloc] initWithCountLimit:7 cacheNulls:NO];
    viewController.mediaAttributesCache = [[MUKMediaAttributesCache alloc] initWithCountLimit:7 cacheNulls:YES];
    
    viewController.loadingImageIndexes = [[NSMutableIndexSet alloc] init];
    viewController.loadingThumbnailImageIndexes = [[NSMutableIndexSet alloc] init];
    
    viewController.lastCollectionViewBounds = CGRectNull;
    viewController.itemIndexToMantainAfterBoundsChange = 0;
    
    if (layout) {
        viewController.collectionView.collectionViewLayout = layout;
    }
}

static inline NSInteger ItemIndexForIndexPath(NSIndexPath *indexPath) {
    return indexPath.item;
}

#pragma mark - Private — Layout

+ (UICollectionViewLayout *)newCarouselLayout {
    MUKMediaCarouselFlowLayout *layout = [[MUKMediaCarouselFlowLayout alloc] init];
    layout.minimumLineSpacing = kLateralPadding * 2.0f;
    return layout;
}

- (void)viewBoundsCouldChangeFromSize:(CGSize)oldSize {
    if (!self.hasPendingScrollToItem) {
        self.itemIndexToMantainAfterBoundsChange = [self currentPageIndex];
    }
}

- (void)viewBoundsDidChangeFromSize:(CGSize)oldSize toNewSize:(CGSize)newSize {
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self scrollToItemAtIndex:self.itemIndexToMantainAfterBoundsChange animated:NO];
}

- (NSInteger)currentPageIndex {
    CGFloat pageWidth = [MUKMediaCarouselFlowLayout fullPageWidthForFrame:self.collectionView.frame spacing:kLateralPadding * 2.0f];
    NSInteger index = self.collectionView.contentOffset.x/pageWidth;
    
    if (index < 0) {
        index = 0;
    }
    else if (index >= [self.collectionView numberOfItemsInSection:0]) {
        index = [self.collectionView numberOfItemsInSection:0] - 1;
    }
    
    return index;
}

#pragma mark - Private — KVO

- (void)beginObservingBoundsChanges {
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionPrior context:(__bridge void *)kBoundsChangesKVOIdentifier];
    self.isObservingBoundsChanges = YES;
}

- (void)stopObservingBoundsChangesIfNeeded {
    if (self.isObservingBoundsChanges) {
        self.isObservingBoundsChanges = NO;
        [self.view removeObserver:self forKeyPath:@"frame"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (kBoundsChangesKVOIdentifier == (__bridge NSString *)context) {
        BOOL isPrior = [change[NSKeyValueChangeNotificationIsPriorKey] boolValue];
        CGRect old = [change[NSKeyValueChangeOldKey] CGRectValue];
        
        if (isPrior) {
            [self viewBoundsCouldChangeFromSize:old.size];
        }
        else {
            CGRect new = [change[NSKeyValueChangeNewKey] CGRectValue];
            if (!CGSizeEqualToSize(old.size, new.size)) {
                [self viewBoundsDidChangeFromSize:old.size toNewSize:new.size];
            }
        }
    }
}

#pragma mark - Private — Media Attributes

- (MUKMediaAttributes *)mediaAttributesForItemAtIndex:(NSInteger)idx {
    return [self.mediaAttributesCache mediaAttributesAtIndex:idx cacheIfNeeded:YES loadingHandler:^MUKMediaAttributes *
    {
        if ([self.delegate respondsToSelector:@selector(carouselViewController:attributesForItemAtIndex:)])
        {
            return [self.delegate carouselViewController:self attributesForItemAtIndex:idx];
        }
      
        return nil;
    }];
}

#pragma mark - Private — Images

- (MUKMediaModelCache *)cacheForImageKind:(MUKMediaImageKind)kind {
    MUKMediaModelCache *cache;
    
    switch (kind) {
        case MUKMediaImageKindThumbnail:
            cache = self.thumbnailImagesCache;
            break;
            
        case MUKMediaImageKindFullSize:
            cache = self.imagesCache;
            break;
            
        default:
            cache = nil;
            break;
    }
    
    return cache;
}

- (NSMutableIndexSet *)loadingIndexesForImageKind:(MUKMediaImageKind)kind {
    NSMutableIndexSet *indexSet;
    
    switch (kind) {
        case MUKMediaImageKindThumbnail:
            indexSet = self.loadingThumbnailImageIndexes;
            break;
            
        case MUKMediaImageKindFullSize:
            indexSet = self.loadingImageIndexes;
            break;
            
        default:
            indexSet = nil;
            break;
    }
    
    return indexSet;
}

- (BOOL)isLoadingImageOfKind:(MUKMediaImageKind)imageKind atIndex:(NSInteger)index
{
    return [[self loadingIndexesForImageKind:imageKind] containsIndex:index];
}

- (void)setLoading:(BOOL)loading imageOfKind:(MUKMediaImageKind)imageKind atIndex:(NSInteger)index
{
    NSMutableIndexSet *indexSet = [self loadingIndexesForImageKind:imageKind];
    
    if (loading) {
        [indexSet addIndex:index];
    }
    else {
        [indexSet removeIndex:index];
    }
}

- (UIImage *)biggestCachedImageOrRequestLoadingForItemAtIndexPath:(NSIndexPath *)indexPath foundImageKind:(MUKMediaImageKind *)foundImageKind
{
    NSInteger const kImageIndex = ItemIndexForIndexPath(indexPath);

    // Try to load biggest image
    UIImage *fullImage = [[self cacheForImageKind:MUKMediaImageKindFullSize] objectAtIndex:kImageIndex isNull:NULL];
    
    // If full image is there, we have just finished :)
    if (fullImage) {
        if (foundImageKind != NULL) {
            *foundImageKind = MUKMediaImageKindFullSize;
        }
        
        return fullImage;
    }
    
    // No full image in cache :(
    // We need to request full image loading to delegate
    [self loadImageOfKind:MUKMediaImageKindFullSize forItemAtIndexPath:indexPath inNextRunLoop:YES];
    
    // Try to load thumbnail to appeal user eye from cache
    UIImage *thumbnail = [[self cacheForImageKind:MUKMediaImageKindThumbnail] objectAtIndex:kImageIndex isNull:NULL];

    // Give back thumbnail if it's in memory
    if (thumbnail) {
        if (foundImageKind != NULL) {
            *foundImageKind = MUKMediaImageKindThumbnail;
        }
        
        return thumbnail;
    }
    
    // Thumbnail is not available, too :(
    // Request it to delegate!
    [self loadImageOfKind:MUKMediaImageKindThumbnail forItemAtIndexPath:indexPath inNextRunLoop:YES];
    
    // No image in memory
    if (foundImageKind != NULL) {
        *foundImageKind = MUKMediaImageKindNone;
    }
    
    return nil;
}

- (void)loadImageOfKind:(MUKMediaImageKind)imageKind forItemAtIndexPath:(NSIndexPath *)indexPath inNextRunLoop:(BOOL)useNextRunLoop
{
    NSInteger const kImageIndex = ItemIndexForIndexPath(indexPath);
    
    // Mark as loading
    [self setLoading:YES imageOfKind:imageKind atIndex:kImageIndex];
    
    // This block is called by delegate which can give back an image
    // asynchronously
    void (^completionHandler)(UIImage *) = ^(UIImage *image) {
        // If it's still loading
        if ([self isLoadingImageOfKind:imageKind atIndex:kImageIndex]) {
            // Mark as not loading
            [self setLoading:NO imageOfKind:imageKind atIndex:kImageIndex];
            
            // Stop smaller loading
            [self cancelImageLoadingSmallerThanKind:imageKind atIndexPath:indexPath];
            
            // Cache image
            [[self cacheForImageKind:imageKind] setObject:image atIndex:kImageIndex];
            
            // Get actual cell
            MUKMediaCarouselCell *cell = (MUKMediaCarouselCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            
            // Set image if needed
            if ([cell isKindOfClass:[MUKMediaCarouselFullImageCell class]]) {
                MUKMediaCarouselFullImageCell *fullImageCell = (MUKMediaCarouselFullImageCell *)cell;
                
                if ([self shouldSetLoadedImageOfKind:imageKind intoFullImageCell:fullImageCell atIndexPath:indexPath])
                {
                    [self setImage:image ofKind:imageKind inFullImageCell:fullImageCell];
                }
            }
            else if ([cell isKindOfClass:[MUKMediaCarouselPlayerCell class]]) {
                MUKMediaCarouselPlayerCell *playerCell = (MUKMediaCarouselPlayerCell *)cell;
                if ([self shouldSetLoadedImageOfKind:imageKind intoPlayerCell:playerCell atIndexPath:indexPath])
                {
                    BOOL stock = NO;
                    
                    if (!image) {
                        // Use stock thumbnail
                        MUKMediaAttributes *attributes = [self mediaAttributesForItemAtIndex:kImageIndex];
                        image = [self stockThumbnailForMediaKind:attributes.kind];
                        stock = YES;
                    }
                    
                    [self setThumbnailImage:image stock:stock inPlayerCell:playerCell hideActivityIndicator:YES];
                }
            }
        } // if isLoadingImageKind
    }; // completionHandler
    
    // Call delegate in next run loop when we need cell enters in reuse queue
    // In completionHandler we have [self.collectionView cellForItemAtIndexPath:indexPath]
    // which fill nil if is called inside -collectionView:cellForItemAtIndexPath:
    // and this is the case when completionHandler is invoked synchrounosly (say
    // user has a nil thumbnail
    if (useNextRunLoop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate carouselViewController:self loadImageOfKind:imageKind forItemAtIndex:kImageIndex completionHandler:completionHandler];
        });
    }
    else {
        [self.delegate carouselViewController:self loadImageOfKind:imageKind forItemAtIndex:kImageIndex completionHandler:completionHandler];
    }
}

- (void)cancelLoadingForImageOfKind:(MUKMediaImageKind)imageKind atIndex:(NSInteger)index
{
    if ([self isLoadingImageOfKind:imageKind atIndex:index]) {
        // Mark as not loading
        [self setLoading:NO imageOfKind:imageKind atIndex:index];
        
        // Request delegate to abort
        if ([self.delegate respondsToSelector:@selector(carouselViewController:cancelLoadingForImageOfKind:atIndex:)])
        {
            [self.delegate carouselViewController:self cancelLoadingForImageOfKind:imageKind atIndex:index];
        }
    }
}

- (void)cancelImageLoadingSmallerThanKind:(MUKMediaImageKind)imageKind atIndexPath:(NSIndexPath *)indexPath
{
    if (imageKind == MUKMediaImageKindFullSize) {
        [self cancelLoadingForImageOfKind:MUKMediaImageKindThumbnail atIndex:ItemIndexForIndexPath(indexPath)];
    }
}

- (void)cancelAllImageLoadingsForItemAtIndex:(NSInteger)index {
    [self cancelLoadingForImageOfKind:MUKMediaImageKindFullSize atIndex:index];
    [self cancelLoadingForImageOfKind:MUKMediaImageKindThumbnail atIndex:index];
}

- (UIImage *)stockThumbnailForMediaKind:(MUKMediaKind)mediaKind {
    UIImage *thumbnail;
    
    switch (mediaKind) {
        case MUKMediaKindAudio:
            thumbnail = [[MUKMediaGalleryUtils imageNamed:@"audio_big_transparent"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
            
        case MUKMediaKindVideo:
        case MUKMediaKindYouTubeVideo:
            thumbnail = [[MUKMediaGalleryUtils imageNamed:@"video_big_transparent"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
            
        default:
            thumbnail = nil;
            break;
    }
    
    return thumbnail;
}

#pragma mark - Private — Media Playback

- (void)cancelMediaPlaybackInPlayerCell:(MUKMediaCarouselPlayerCell *)cell {
    [cell setMediaURL:nil];
}

- (BOOL)shouldDismissThumbnailAsNewPlaybackStartsInPlayerCell:(MUKMediaCarouselPlayerCell *)cell forItemAtIndex:(NSInteger)index
{
    // Load attributes
    MUKMediaAttributes *attributes = [self mediaAttributesForItemAtIndex:index];
    
    BOOL shouldDismissThumbnail;
    
    // Keep thumbnail for audio tracks
    if (attributes.kind == MUKMediaKindAudio) {
        shouldDismissThumbnail = NO;
    }
    else {
        if (cell.moviePlayerController.playbackState != MPMoviePlaybackStateStopped ||
            cell.moviePlayerController.playbackState != MPMoviePlaybackStatePaused)
        {
            shouldDismissThumbnail = YES;
        }
        else {
            shouldDismissThumbnail = NO;
        }
    }
    
    return shouldDismissThumbnail;
}

#pragma mark - Private — Cell

- (UICollectionViewCell *)dequeueCellForMediaAttributes:(MUKMediaAttributes *)attributes atIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier;
    if (attributes && attributes.kind != MUKMediaKindImage) {
        identifier = kMediaPlayerCellIdentifier;
    }
    else {
        identifier = kFullImageCellIdentifier;
    }
    
    return [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
}

- (void)configureCell:(UICollectionViewCell *)cell forMediaAttributes:(MUKMediaAttributes *)attributes atIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor blackColor];
    
    if ([cell isKindOfClass:[MUKMediaCarouselCell class]]) {
        MUKMediaCarouselCell *carouselCell = (MUKMediaCarouselCell *)cell;
        carouselCell.captionLabel.text = attributes.caption;
        
        if ([attributes.caption length] && ![self areBarsHidden]) {
            [carouselCell setCaptionHidden:NO animated:NO completion:nil];
        }
        else {
            [carouselCell setCaptionHidden:YES animated:NO completion:nil];
        }
        
        if ([cell isKindOfClass:[MUKMediaCarouselFullImageCell class]]) {
            [self configureFullImageCell:(MUKMediaCarouselFullImageCell *)cell forMediaAttributes:attributes atIndexPath:indexPath];
        }
        else if ([cell isKindOfClass:[MUKMediaCarouselPlayerCell class]]) {
            [self configureMediaPlayerCell:(MUKMediaCarouselPlayerCell *)cell forMediaAttributes:attributes atIndexPath:indexPath];
        }
    }
}

- (void)configureFullImageCell:(MUKMediaCarouselFullImageCell *)cell forMediaAttributes:(MUKMediaAttributes *)attributes atIndexPath:(NSIndexPath *)indexPath
{
    cell.delegate = self;
    
    MUKMediaImageKind foundImageKind = MUKMediaImageKindNone;
    UIImage *image = [self biggestCachedImageOrRequestLoadingForItemAtIndexPath:indexPath foundImageKind:&foundImageKind];
    [self setImage:image ofKind:foundImageKind inFullImageCell:cell];
    
    
}

- (BOOL)shouldSetLoadedImageOfKind:(MUKMediaImageKind)imageKind intoFullImageCell:(MUKMediaCarouselFullImageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (!cell || !indexPath) return NO;
    
    BOOL shouldSetImage = NO;
    
    // It's still visible
    if ([[self.collectionView indexPathsForVisibleItems] containsObject:indexPath])
    {
        // Don't overwrite bigger images
        if (imageKind == MUKMediaImageKindThumbnail &&
            cell.imageKind == MUKMediaImageKindFullSize)
        {
            shouldSetImage = NO;
        }
        else {
            shouldSetImage = YES;
        }
    }
    
    return shouldSetImage;
}

- (void)setImage:(UIImage *)image ofKind:(MUKMediaImageKind)kind inFullImageCell:(MUKMediaCarouselFullImageCell *)cell
{
    BOOL shouldShowActivityIndicator = (kind != MUKMediaImageKindFullSize);
    if (shouldShowActivityIndicator) {
        [cell.activityIndicatorView startAnimating];
    }
    else {
        [cell.activityIndicatorView stopAnimating];
    }
    
    [cell setImage:image ofKind:kind];
}

- (void)configureMediaPlayerCell:(MUKMediaCarouselPlayerCell *)cell forMediaAttributes:(MUKMediaAttributes *)attributes atIndexPath:(NSIndexPath *)indexPath
{
    cell.delegate = self;
    
    // Set media URL (this will create room for thumbnail)
    NSURL *mediaURL = [self.delegate carouselViewController:self mediaURLForItemAtIndex:ItemIndexForIndexPath(indexPath)];
    [cell setMediaURL:mediaURL];
    
    // Nullify existing thumbnail
    cell.thumbnailImageView.image = nil;
    
    // Try to load thumbnail to appeal user eye, from cache
    UIImage *thumbnail = [[self cacheForImageKind:MUKMediaImageKindThumbnail] objectAtIndex:ItemIndexForIndexPath(indexPath) isNull:NULL];
    
    // Thumbnail available: display it
    if (thumbnail) {
        [self setThumbnailImage:thumbnail stock:NO inPlayerCell:cell hideActivityIndicator:YES];
    }
    
    // Thumbnail unavailable: request to delegate
    else {
        // Show loading
        [cell.activityIndicatorView startAnimating];
        
        // Request loading
        [self loadImageOfKind:MUKMediaImageKindThumbnail forItemAtIndexPath:indexPath inNextRunLoop:YES];
        
        // Use stock thumbnail in the meanwhile
        if (cell.thumbnailImageView.image == nil) {
            thumbnail = [self stockThumbnailForMediaKind:attributes.kind];
            [self setThumbnailImage:thumbnail stock:YES inPlayerCell:cell hideActivityIndicator:NO];
        }
    }
}

- (BOOL)shouldSetLoadedImageOfKind:(MUKMediaImageKind)imageKind intoPlayerCell:(MUKMediaCarouselPlayerCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (!cell || !indexPath) return NO;
    
    BOOL shouldSetImage = NO;
    
    // Only thumbnails and when cell is still visible
    if (imageKind == MUKMediaImageKindThumbnail &&
        [[self.collectionView indexPathsForVisibleItems] containsObject:indexPath])
    {
        shouldSetImage = YES;
    }
    
    return shouldSetImage;
}

- (void)setThumbnailImage:(UIImage *)image stock:(BOOL)isStock inPlayerCell:(MUKMediaCarouselPlayerCell *)cell hideActivityIndicator:(BOOL)hideActivityIndicator
{
    if (hideActivityIndicator) {
        [cell.activityIndicatorView stopAnimating];
    }

    cell.thumbnailImageView.image = image;
    cell.thumbnailImageView.contentMode = (isStock ? UIViewContentModeCenter : UIViewContentModeScaleAspectFit);
}

- (void)dismissThumbnailInPlayerCell:(MUKMediaCarouselPlayerCell *)cell forItemAtIndex:(NSInteger)index
{
    // Cancel thumbnail loading
    [self cancelAllImageLoadingsForItemAtIndex:index];
    
    // Hide thumbnail
    [self setThumbnailImage:nil stock:NO inPlayerCell:cell hideActivityIndicator:YES];
}

#pragma mark - Private — Bars

- (BOOL)areBarsHidden {
    return self.navigationController.navigationBarHidden;
}

- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:hidden animated:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    
    for (MUKMediaCarouselCell *cell in [self.collectionView visibleCells]) {
        if ([cell isKindOfClass:[MUKMediaCarouselCell class]]) {
            if (hidden || (!hidden && [cell.captionLabel.text length] > 0)) {
                [cell setCaptionHidden:hidden animated:animated completion:nil];
            }
        }
    } // for
}

- (void)toggleBarsVisibility {
    BOOL barsHidden = [self areBarsHidden];
    [self setBarsHidden:!barsHidden animated:YES];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.delegate numberOfItemsInCarouselViewController:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Load attributes
    MUKMediaAttributes *attributes = [self mediaAttributesForItemAtIndex:ItemIndexForIndexPath(indexPath)];
    
    // Create cell
    UICollectionViewCell *cell = [self dequeueCellForMediaAttributes:attributes atIndexPath:indexPath];
    
    // Configure cell
    [self configureCell:cell forMediaAttributes:attributes atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self cancelAllImageLoadingsForItemAtIndex:ItemIndexForIndexPath(indexPath)];
    
    if ([cell isKindOfClass:[MUKMediaCarouselPlayerCell class]]) {
        [self cancelMediaPlaybackInPlayerCell:(MUKMediaCarouselPlayerCell *)cell];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Show movie controls if bars are hidden and current item is an audio/video
    // Hide movie controls if bars are shows and current item is already playing
    MUKMediaCarouselPlayerCell *cell = (MUKMediaCarouselPlayerCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[MUKMediaCarouselPlayerCell class]]) {
        if ([self areBarsHidden]) {
            [cell setPlayerControlsHidden:NO animated:YES completion:nil];
        }
        else if (cell.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying)
        {
            [cell setPlayerControlsHidden:YES animated:YES completion:nil];
        }
    }
    
    [self toggleBarsVisibility];
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return collectionView.frame.size;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self setBarsHidden:YES animated:YES];
}

#pragma mark - <MUKMediaCarouselFullImageCellDelegate>

- (void)carouselFullImageCell:(MUKMediaCarouselFullImageCell *)cell imageScrollViewDidReceiveTapWithGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer
{
    [self toggleBarsVisibility];
}

#pragma mark - <MUKMediaCarouselPlayerCellDelegate>

- (void)carouselPlayerCellDidChangeNowPlayingMovie:(MUKMediaCarouselPlayerCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath == nil) {
        return;
    }
    
    NSInteger const kItemIndex = ItemIndexForIndexPath(indexPath);

    // Dismiss thumbnail (if needed) when new playback starts (or begins scrubbing)
    if ([self shouldDismissThumbnailAsNewPlaybackStartsInPlayerCell:cell forItemAtIndex:kItemIndex])
    {
        [self dismissThumbnailInPlayerCell:cell forItemAtIndex:kItemIndex];
    }
}

- (void)carouselPlayerCellDidChangePlaybackState:(MUKMediaCarouselPlayerCell *)cell
{
    // Hide bars when playback starts
    if (cell.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying)
    {
        [self setBarsHidden:YES animated:YES];
    }
}

@end
