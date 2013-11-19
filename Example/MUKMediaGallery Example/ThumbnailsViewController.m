#import "ThumbnailsViewController.h"
#import "MediaAsset.h"
#import "CarouselViewController.h"

#define DEBUG_SIMULATE_ASSETS_DOWNLOADING   0
#define DEBUG_HUGE_ASSETS                   1

@interface ThumbnailsViewController () <MUKMediaThumbnailsViewControllerDelegate>
@property (nonatomic) NSOperationQueue *networkQueue;
@end

@implementation ThumbnailsViewController

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.title = @"Thumbnails Grid";
        self.delegate = self;
        _networkQueue = [[NSOperationQueue alloc] init];
        _networkQueue.maxConcurrentOperationCount = 3;
        
#if !DEBUG_SIMULATE_ASSETS_DOWNLOADING
        _mediaAssets = [[self class] newAssets];
#endif
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

#if DEBUG_SIMULATE_ASSETS_DOWNLOADING
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    self.collectionView.backgroundView = backgroundView;
    
    UIView *wrapperView = [[UIView alloc] initWithFrame:self.collectionView.backgroundView.bounds];
    wrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    [wrapperView addSubview:spinner];
    [self.collectionView.backgroundView addSubview:wrapperView];

    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:spinner attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:spinner.superview attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f];
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:spinner attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:spinner.superview attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f];
    wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
    [wrapperView addConstraints:@[centerXConstraint, centerYConstraint]];
    
    double delayInSeconds = 3.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.mediaAssets = [[self class] newAssets];
        [self reloadData];
        
        [self.collectionView.backgroundView removeFromSuperview];
        self.collectionView.backgroundView = nil;
    });
#endif
}

#pragma mark - Private

+ (NSArray *)newAssets {
    NSMutableArray *mediaAssets = [[NSMutableArray alloc] init];

#if DEBUG_HUGE_ASSETS
    NSArray *URLStrings = @[@"http://farm8.staticflickr.com/7350/9866729914_97a955b4b8_o.jpg", @"http://farm8.staticflickr.com/7434/10921869254_7bffef2e3b_o.jpg", @"http://farm5.staticflickr.com/4057/4591850430_c48b559490_o.jpg", @"http://farm4.staticflickr.com/3260/3113370526_6a61e6b257_o.jpg", @"http://farm8.staticflickr.com/7453/10505239263_dc6dc13cbb_o.jpg", @"http://farm4.staticflickr.com/3330/3646343982_0240258b96_o.jpg", @"http://farm1.staticflickr.com/61/366959006_94023bb220_o.jpg", @"http://farm3.staticflickr.com/2370/2328858444_650067ed20_o.jpg", @"http://farm3.staticflickr.com/2576/4200626213_2eaeb1d045_o.jpg", @"http://farm1.staticflickr.com/161/368122234_30c9ddf6ae_o.jpg"];
    
    for (NSString *URLString in URLStrings) {
        NSString *thumbURLString = [URLString stringByReplacingOccurrencesOfString:@"_o." withString:@"_m."];

        MediaAsset *asset = [[MediaAsset alloc] initWithKind:MUKMediaKindImage];
        asset.URL = [NSURL URLWithString:URLString];
        asset.thumbnailURL = [NSURL URLWithString:thumbURLString];
        
        [mediaAssets addObject:asset];
    }
#else
    for (NSInteger i=0; i<100; i++) {
        MediaAsset *youTubeVideoAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindYouTubeVideo];
        youTubeVideoAsset.duration = 906; // 15:06
        youTubeVideoAsset.thumbnailURL = [NSURL URLWithString:@"http://i2.ytimg.com/vi/UF8uR6Z6KLc/default.jpg"];
        youTubeVideoAsset.URL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=UF8uR6Z6KLc"];
        youTubeVideoAsset.caption = @"Steve Jobs at Stanford";
        [mediaAssets addObject:youTubeVideoAsset];
        
        MediaAsset *localVideoAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindVideo];
        localVideoAsset.thumbnailURL = [MUK URLForImageFileNamed:@"sea-movie-thumbnail.jpg" bundle:nil];
        localVideoAsset.URL = [[NSBundle mainBundle] URLForResource:@"sea" withExtension:@"mp4"];
        localVideoAsset.caption = @"A local video asset downloaded from Flickr which has been recorded to be relaxing and entertaining";
        [mediaAssets addObject:localVideoAsset];
        
        MediaAsset *remoteVideoAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindVideo];
        remoteVideoAsset.URL = [NSURL URLWithString:@"http://mirrors.creativecommons.org/movingimages/Building_on_the_Past.mp4"];
        [mediaAssets addObject:remoteVideoAsset];
        
        // http://www.flickr.com/photos/26895569@N07/9134939367/sizes/l/in/explore-2013-06-25/
        MediaAsset *remoteImageAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindImage];
        remoteImageAsset.thumbnailURL = [NSURL URLWithString:@"http://farm3.staticflickr.com/2867/9134939367_228c3d310d_m.jpg"];
        remoteImageAsset.URL = [NSURL URLWithString:@"http://farm3.staticflickr.com/2867/9134939367_228c3d310d_b.jpg"]; // [NSURL URLWithString:@"http://farm3.staticflickr.com/2867/9134939367_5083834193_o.jpg"];
        remoteImageAsset.caption = @"Castilla entera se desangra, y nadie cierra la herida ni recoge su roja sangre derramada. Quien puede atender tamaña brecha no siente la sangre por sus venas, y deja a su albur sangre y herida. Los cielos que saben de olvidos acercan su luz a esos colores que gritan quedo su agonía. Quien puede encauzar esas arterias, que ponga el color dentro, en las venas, y fluya roja y encendida haciendo de la vida un paraíso.";
        [mediaAssets addObject:remoteImageAsset];
        
        MediaAsset *localImageAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindImage];
        localImageAsset.thumbnailURL = [MUK URLForImageFileNamed:@"palms-thumbnail.jpg" bundle:nil];
        localImageAsset.URL = [MUK URLForImageFileNamed:@"palms.jpg" bundle:nil];
        localImageAsset.caption = @"A local photo which represents a palm. Palms are a popular tree in many North African countries which is used in many ways.";
        [mediaAssets addObject:localImageAsset];
        
        MediaAsset *localAudioAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindAudio];
        localAudioAsset.thumbnailURL = [NSURL URLWithString:@"http://farm6.staticflickr.com/5178/5500963965_2776bf6a98_t.jpg"];
        localAudioAsset.URL = [[NSBundle mainBundle] URLForResource:@"SexForModerns-StopTheClock_64kb" withExtension:@"mp3"];
        [mediaAssets addObject:localAudioAsset];
        
        MediaAsset *remoteAudioAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindAudio];
        remoteAudioAsset.duration = 332.0; // 05:32
        remoteAudioAsset.URL = [NSURL URLWithString:@"http://ia600201.us.archive.org/21/items/SexForModerns-PenetratingLoveRay/SexForModerns-PenetratingLoveRay.mp3"];
        [mediaAssets addObject:remoteAudioAsset];
    }
#endif
    
    return mediaAssets;
}

#pragma mark - <MUKMediaThumbnailsViewControllerDelegate>

- (NSInteger)numberOfItemsInThumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController
{
    return [self.mediaAssets count];
}

- (void)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController loadImageForItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *))completionHandler
{
    MediaAsset *asset = self.mediaAssets[idx];

    if (!asset.thumbnailURL) {
        completionHandler(nil);
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:asset.thumbnailURL];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.userInfo = @{ @"index" : @(idx) };
    
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

- (void)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController cancelLoadingForImageAtIndex:(NSInteger)idx
{
    for (AFHTTPRequestOperation *op in self.networkQueue.operations) {
        if ([op.userInfo[@"index"] integerValue] == idx) {
            [op cancel];
            break;
        }
    }
}

- (MUKMediaAttributes *)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController attributesForItemAtIndex:(NSInteger)idx
{
    MediaAsset *asset = self.mediaAssets[idx];
    MUKMediaAttributes *attributes = [[MUKMediaAttributes alloc] initWithKind:asset.kind];
    
    if (asset.duration > 0.0) {
        [attributes setCaptionWithTimeInterval:asset.duration];
    }
    
    return attributes;
}

- (MUKMediaCarouselViewController *)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController carouselToPresentAfterSelectingItemAtIndex:(NSInteger)idx
{
    CarouselViewController *carouselViewController = [[CarouselViewController alloc] init];
    carouselViewController.mediaAssets = self.mediaAssets;
    return carouselViewController;
}

- (MUKMediaThumbnailsViewControllerToCarouselTransition)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController transitionToPresentCarouselViewController:(MUKMediaCarouselViewController *)carouselViewController forItemAtIndex:(NSInteger)idx
{
    return MUKMediaThumbnailsViewControllerToCarouselTransitionCoverVertical;
}

@end
