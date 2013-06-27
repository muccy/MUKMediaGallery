#import "CarouselViewController.h"
#import "MediaAsset.h"

@interface CarouselViewController () <MUKMediaCarouselViewControllerDelegate>

@end

@implementation CarouselViewController

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.title = @"Thumbnails Grid";
        self.delegate = self;
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

- (void)carouselViewController:(MUKMediaCarouselViewController *)viewController loadImageOfKind:(MUKMediaImageKind)imageKind forItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *image))completionHandler
{
    MediaAsset *asset = self.mediaAssets[idx];
    NSURL *URL = (imageKind == MUKMediaImageKindFullSize ? asset.URL : asset.thumbnailURL);
    
    if (!URL) {
        completionHandler(nil);
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        UIImage *image = nil;
        
        if ([data length]) {
            image = [UIImage imageWithData:data];
        }
        
        completionHandler(image);
    }];
}

- (NSURL *)carouselViewController:(MUKMediaCarouselViewController *)viewController mediaURLForItemAtIndex:(NSInteger)idx
{
    return nil;
}

@end
