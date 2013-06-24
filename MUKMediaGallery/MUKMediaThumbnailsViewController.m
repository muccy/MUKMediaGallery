#import "MUKMediaThumbnailsViewController.h"
#import "MUKMediaThumbnailCell.h"

static NSString *const kCellIdentifier = @"MUKMediaThumbnailCell";

@interface MUKMediaThumbnailsViewController ()
@property (nonatomic) NSMutableDictionary *loadedImages;
@property (nonatomic) NSMutableIndexSet *loadingImageIndexes;
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
    [self.loadedImages removeAllObjects];
}

#pragma mark - Private

static void CommonInitialization(MUKMediaThumbnailsViewController *viewController, UICollectionViewLayout *layout)
{
    viewController.loadedImages = [[NSMutableDictionary alloc] init];
    viewController.loadingImageIndexes = [[NSMutableIndexSet alloc] init];
    
    if (layout) {
        viewController.collectionView.collectionViewLayout = layout;
    }
}

#pragma mark - Private — Layout

+ (UICollectionViewFlowLayout *)newGridLayout {
    UICollectionViewFlowLayout *grid = [[UICollectionViewFlowLayout alloc] init];
    grid.itemSize = CGSizeMake(75.0f, 75.0f);
    grid.minimumInteritemSpacing = 4.0f;
    grid.minimumLineSpacing = 4.0f;
    grid.sectionInset = UIEdgeInsetsMake(4.0f, 4.0f, 4.0f, 4.0f);
    
    return grid;
}

#pragma mark - Private — Images

- (BOOL)hasLoadedImageAtIndex:(NSInteger)index {
    return [[self.loadedImages allKeys] containsObject:@(index)];
}

- (UIImage *)loadedImageAtIndex:(NSInteger)index {
    return self.loadedImages[@(index)];
}

- (void)cacheLoadedImage:(UIImage *)image atIndex:(NSInteger)index {
    if (image == nil) {
        return;
    }
    
    self.loadedImages[@(index)] = image;
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

#pragma mark - Private — Cell

- (void)configureThumbnailCell:(MUKMediaThumbnailCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    
    UIImage *image = nil;
    NSInteger const imageIndex = indexPath.item;
    
    // Is loaded?
    if ([self hasLoadedImageAtIndex:imageIndex]) {
        image = [self loadedImageAtIndex:imageIndex];
    }
    
    // If no image is cached, check if it's loading
    if (image == nil) {
        // If it's not loading, request an image
        if ([self isLoadingImageAtIndex:imageIndex] == NO) {
            // Mark as loading
            [self setLoading:YES imageAtIndex:imageIndex];
            
            // This block is called by delegate which can give back an image
            // asynchronously
            void (^completionHandler)(UIImage *) = ^(UIImage *image) {
                // Set image as not loading
                [self setLoading:NO imageAtIndex:imageIndex];
                
                // Cache given image
                [self cacheLoadedImage:image atIndex:imageIndex];
                
                // Take actual cell and set image
                MUKMediaThumbnailCell *actualCell = (MUKMediaThumbnailCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                [self setImage:image inThumbnailCell:actualCell];
            };
            
            [self.delegate thumbnailsViewController:self loadImageForItemAtIndex:imageIndex completionHandler:completionHandler];
        }
    }
    
    // Anyway set the image, also if it's nil
    [self setImage:image inThumbnailCell:cell];
}

- (void)setImage:(UIImage *)image inThumbnailCell:(MUKMediaThumbnailCell *)cell {
    cell.imageView.image = image;
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
        NSInteger const imageIndex = indexPath.item;

        if ([self isLoadingImageAtIndex:imageIndex]) {
            if ([self.delegate thumbnailsViewController:self cancelLoadingForImageAtIndex:imageIndex])
            {
                // Mark as not loading
                [self setLoading:NO imageAtIndex:imageIndex];
            } // if cancelled
        } // if -isLoadingImageAtIndex:
    } // if delegate responds
}

@end
