#import "CarouselViewController.h"
#import "MediaAsset.h"

@interface CarouselViewController () <MUKMediaCarouselViewControllerDelegate>
@property (nonatomic) NSOperationQueue *networkQueue;
@end

@implementation CarouselViewController

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.title = @"Media Carousel";
        self.delegate = self;
        _networkQueue = [[NSOperationQueue alloc] init];
        _networkQueue.maxConcurrentOperationCount = 2;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - <MUKMediaCarouselViewControllerDelegate>

- (NSInteger)numberOfItemsInCarouselViewController:(MUKMediaCarouselViewController *)viewController
{
    return [self.mediaAssets count];
}

- (MUKMediaAttributes *)carouselViewController:(MUKMediaCarouselViewController *)viewController attributesForItemAtIndex:(NSInteger)idx
{
    MediaAsset *asset = self.mediaAssets[idx];
    MUKMediaAttributes *attributes = [[MUKMediaAttributes alloc] initWithKind:asset.kind];
    attributes.caption = asset.caption;
    return attributes;
}

- (void)carouselViewController:(MUKMediaCarouselViewController *)viewController loadImageOfKind:(MUKMediaImageKind)imageKind forItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *image))completionHandler
{
    MediaAsset *asset = self.mediaAssets[idx];
    NSURL *URL = (imageKind == MUKMediaImageKindFullSize ? asset.URL : asset.thumbnailURL);
    
    if (!URL) {
        completionHandler(nil);
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.userInfo = @{ @"index" : @(idx), @"imageKind" : @(imageKind) };
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        UIImage *image = nil;
        
        if ([responseObject length]) {
            image = [UIImage imageWithData:responseObject];
        }
        
        completionHandler(image);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completionHandler(nil);
    }];
    
    [self.networkQueue addOperation:op];
}

- (void)carouselViewController:(MUKMediaCarouselViewController *)viewController cancelLoadingForImageOfKind:(MUKMediaImageKind)imageKind atIndex:(NSInteger)idx
{
    for (AFHTTPRequestOperation *op in self.networkQueue.operations) {
        if ([op.userInfo[@"index"] integerValue] == idx &&
            [op.userInfo[@"imageKind"] integerValue] == imageKind)
        {
            [op cancel];
            break;
        }
    }
}

- (NSURL *)carouselViewController:(MUKMediaCarouselViewController *)viewController mediaURLForItemAtIndex:(NSInteger)idx
{
    return nil;
}

@end
