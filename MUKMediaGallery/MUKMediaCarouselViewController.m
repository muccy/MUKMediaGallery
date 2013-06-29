#import "MUKMediaCarouselViewController.h"
#import "MUKMediaCarouselFullImageCell.h"
#import "MUKMediaCarouselPlayerCell.h"
#import "MUKMediaAttributesCache.h"

static NSString *const kFullImageCellIdentifier = @"MUKMediaFullImageCell";
static NSString *const kMediaPlayerCellIdentifier = @"MUKMediaPlayerCell";
static NSString *const kBoundsChangesKVOIdentifier = @"BoundsChangesKVOIdentifier";
static CGFloat const kLateralPadding = 4.0f;

@interface MUKMediaCarouselViewController ()
@property (nonatomic) MUKMediaAttributesCache *mediaAttributesCache;
@property (nonatomic) MUKMediaModelCache *imagesCache, *thumbnailImagesCache;
@property (nonatomic) NSMutableIndexSet *loadingImageIndexes, *loadingThumbnailImageIndexes;
@property (nonatomic) CGRect lastCollectionViewBounds;
@property (nonatomic) BOOL isObservingBoundsChanges;
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    CGRect frame = self.collectionView.frame;
    frame.origin.x -= kLateralPadding;
    frame.size.width += kLateralPadding * 2.0f;
    self.collectionView.frame = frame;
    
    [self.collectionView registerClass:[MUKMediaCarouselFullImageCell class] forCellWithReuseIdentifier:kFullImageCellIdentifier];
    [self.collectionView registerClass:[MUKMediaCarouselPlayerCell class] forCellWithReuseIdentifier:kMediaPlayerCellIdentifier];
    
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
    
    if (layout) {
        viewController.collectionView.collectionViewLayout = layout;
    }
}

static inline NSInteger ItemIndexForIndexPath(NSIndexPath *indexPath) {
    return indexPath.section;
}

#pragma mark - Private — Layout

+ (UICollectionViewLayout *)newCarouselLayout {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0.0f;
    layout.minimumLineSpacing = 0.0f;
    return layout;
}

- (void)viewBoundsDidChangeFromSize:(CGSize)oldSize toNewSize:(CGSize)newSize {
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - Private — KVO

- (void)beginObservingBoundsChanges {
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:(__bridge void *)kBoundsChangesKVOIdentifier];
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
        CGRect old = [change[NSKeyValueChangeOldKey] CGRectValue];
        CGRect new = [change[NSKeyValueChangeNewKey] CGRectValue];
        if (!CGSizeEqualToSize(old.size, new.size)) {
            [self viewBoundsDidChangeFromSize:old.size toNewSize:new.size];
        }
    }
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
    [self loadImageOfKind:MUKMediaImageKindFullSize forItemAtIndexPath:indexPath];
    
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
    [self loadImageOfKind:MUKMediaImageKindThumbnail forItemAtIndexPath:indexPath];
    
    // No image in memory
    if (foundImageKind != NULL) {
        *foundImageKind = MUKMediaImageKindNone;
    }
    
    return nil;
}

- (void)loadImageOfKind:(MUKMediaImageKind)imageKind forItemAtIndexPath:(NSIndexPath *)indexPath
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
            MUKMediaCarouselFullImageCell *cell = (MUKMediaCarouselFullImageCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                        
            // Set image if needed
            if ([self shouldSetLoadedImageOfKind:imageKind intoFullImageCell:cell atIndexPath:indexPath])
            {
                [self setImage:image ofKind:imageKind inFullImageCell:cell];
            }
        } // if isLoadingImageKind
    }; // completionHandler
    
    [self.delegate carouselViewController:self loadImageOfKind:imageKind forItemAtIndex:kImageIndex completionHandler:completionHandler];
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
    cell.backgroundColor = [UIColor colorWithRed:(float)(arc4random()%255)/255.0f green:(float)(arc4random()%255)/255.0f blue:(float)(arc4random()%255)/255.0f alpha:0.7f];
    
    if ([cell isKindOfClass:[MUKMediaCarouselCell class]]) {
        MUKMediaCarouselCell *carouselCell = (MUKMediaCarouselCell *)cell;
        
        if ([attributes.caption length] && ![self areBarsHidden]) {
            carouselCell.captionLabel.text = attributes.caption;
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
    // TODO
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
            [cell setCaptionHidden:hidden animated:animated completion:nil];
        }
    } // for
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.delegate numberOfItemsInCarouselViewController:self];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Load attributes
    MUKMediaAttributes *attributes = [self.mediaAttributesCache mediaAttributesAtIndex:ItemIndexForIndexPath(indexPath) cacheIfNeeded:YES loadingHandler:^MUKMediaAttributes *
    {
        if ([self.delegate respondsToSelector:@selector(carouselViewController:attributesForItemAtIndex:)])
        {
            return [self.delegate carouselViewController:self attributesForItemAtIndex:ItemIndexForIndexPath(indexPath)];
        }
        
        return nil;
    }];
    
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
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Toggle bars visibility
    BOOL barsHidden = [self areBarsHidden];
    [self setBarsHidden:!barsHidden animated:YES];
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = collectionView.frame.size;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionViewLayout;
    size.width -= kLateralPadding * 2.0f;
    
    return size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat padding;
    if (section == 0) {
        padding = kLateralPadding;
    }
    else {
        padding = kLateralPadding * 2.0f;
    }
    
    return UIEdgeInsetsMake(0.0f, padding, 0.0f, 0.0f);
}

@end
