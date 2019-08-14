#import "ThumbnailsViewController.h"
#import "MediaAsset.h"
#import "CarouselViewController.h"

#define DEBUG_SIMULATE_ASSETS_DOWNLOADING   0
#define DEBUG_HUGE_ASSETS                   0

@interface ThumbnailsViewController () <MUKMediaThumbnailsViewControllerDelegate>
@property (nonatomic) NSOperationQueue *networkQueue;
@end

@implementation ThumbnailsViewController

- (id)init {
    self = [super init];
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
    NSArray *URLStrings = @[@"http://photopin.com/phpflickr/getphoto.php?size=original&id=4561126538&url=http%3A%2F%2Ffarm5.staticflickr.com%2F4020%2F4561126538_ff11823d70_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=2456720470&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2095%2F2456720470_d95381244e_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=8544074541&url=http%3A%2F%2Ffarm9.staticflickr.com%2F8391%2F8544074541_d524cbd894_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=164963669&url=http%3A%2F%2Ffarm1.staticflickr.com%2F48%2F164963669_a8b04e7ac3_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=13290875115&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3711%2F13290875115_59b6ef17c0_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=3644223516&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3395%2F3644223516_c57fae255b_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=3101281662&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3180%2F3101281662_2646526718_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=292917043&url=http%3A%2F%2Ffarm1.staticflickr.com%2F113%2F292917043_32f325372f_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=213839709&url=http%3A%2F%2Ffarm1.staticflickr.com%2F81%2F213839709_889a86f0c9_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=157527342&url=http%3A%2F%2Ffarm1.staticflickr.com%2F48%2F157527342_00affe5f94_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=97204589&url=http%3A%2F%2Ffarm1.staticflickr.com%2F23%2F97204589_f70f4f6e25_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=5826755&url=http%3A%2F%2Ffarm1.staticflickr.com%2F6%2F5826755_8f7ca43323_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=13227507635&url=http%3A%2F%2Ffarm8.staticflickr.com%2F7257%2F13227507635_08beee10c6_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=12086742175&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2835%2F12086742175_646648b0b3_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=11934616456&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2856%2F11934616456_5fb701fc1b_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=11608712713&url=http%3A%2F%2Ffarm8.staticflickr.com%2F7395%2F11608712713_7527cf777b_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=11191240794&url=http%3A%2F%2Ffarm6.staticflickr.com%2F5528%2F11191240794_360c2c0341_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=10531577523&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3780%2F10531577523_8169627052_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=4561126538&url=http%3A%2F%2Ffarm5.staticflickr.com%2F4020%2F4561126538_ff11823d70_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=2456720470&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2095%2F2456720470_d95381244e_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=8544074541&url=http%3A%2F%2Ffarm9.staticflickr.com%2F8391%2F8544074541_d524cbd894_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=164963669&url=http%3A%2F%2Ffarm1.staticflickr.com%2F48%2F164963669_a8b04e7ac3_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=13290875115&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3711%2F13290875115_59b6ef17c0_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=3644223516&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3395%2F3644223516_c57fae255b_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=3101281662&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3180%2F3101281662_2646526718_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=292917043&url=http%3A%2F%2Ffarm1.staticflickr.com%2F113%2F292917043_32f325372f_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=213839709&url=http%3A%2F%2Ffarm1.staticflickr.com%2F81%2F213839709_889a86f0c9_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=157527342&url=http%3A%2F%2Ffarm1.staticflickr.com%2F48%2F157527342_00affe5f94_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=97204589&url=http%3A%2F%2Ffarm1.staticflickr.com%2F23%2F97204589_f70f4f6e25_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=5826755&url=http%3A%2F%2Ffarm1.staticflickr.com%2F6%2F5826755_8f7ca43323_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=13227507635&url=http%3A%2F%2Ffarm8.staticflickr.com%2F7257%2F13227507635_08beee10c6_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=12086742175&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2835%2F12086742175_646648b0b3_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=11934616456&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2856%2F11934616456_5fb701fc1b_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=11608712713&url=http%3A%2F%2Ffarm8.staticflickr.com%2F7395%2F11608712713_7527cf777b_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=11191240794&url=http%3A%2F%2Ffarm6.staticflickr.com%2F5528%2F11191240794_360c2c0341_o.jpg",
                            @"http://photopin.com/phpflickr/getphoto.php?size=original&id=10531577523&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3780%2F10531577523_8169627052_o.jpg"];
    NSArray *thumbnailURLStrings = @[@"http://photopin.com/phpflickr/getphoto.php?size=small&id=4561126538&url=http%3A%2F%2Ffarm5.staticflickr.com%2F4020%2F4561126538_374d62dfa2_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=2456720470&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2095%2F2456720470_94fb3d246d_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=8544074541&url=http%3A%2F%2Ffarm9.staticflickr.com%2F8391%2F8544074541_29a2c7a292_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=164963669&url=http%3A%2F%2Ffarm1.staticflickr.com%2F48%2F164963669_a8b04e7ac3_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=13290875115&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3711%2F13290875115_bed624a74c_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=3644223516&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3395%2F3644223516_a23eaafb99_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=3101281662&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3180%2F3101281662_d6c9f0e7f9_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=292917043&url=http%3A%2F%2Ffarm1.staticflickr.com%2F113%2F292917043_32f325372f_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=medium&id=213839709&url=http%3A%2F%2Ffarm1.staticflickr.com%2F81%2F213839709_889a86f0c9.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=157527342&url=http%3A%2F%2Ffarm1.staticflickr.com%2F48%2F157527342_00affe5f94_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=97204589&url=http%3A%2F%2Ffarm1.staticflickr.com%2F23%2F97204589_f70f4f6e25_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=5826755&url=http%3A%2F%2Ffarm1.staticflickr.com%2F6%2F5826755_8f7ca43323_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=13227507635&url=http%3A%2F%2Ffarm8.staticflickr.com%2F7257%2F13227507635_c2a72a5d92_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=12086742175&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2835%2F12086742175_cbd381f749_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=11934616456&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2856%2F11934616456_8c2d52e95b_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=11608712713&url=http%3A%2F%2Ffarm8.staticflickr.com%2F7395%2F11608712713_c68a777d03_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=11191240794&url=http%3A%2F%2Ffarm6.staticflickr.com%2F5528%2F11191240794_e79d6399f8_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=10531577523&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3780%2F10531577523_0e077a4791_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=4561126538&url=http%3A%2F%2Ffarm5.staticflickr.com%2F4020%2F4561126538_374d62dfa2_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=2456720470&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2095%2F2456720470_94fb3d246d_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=8544074541&url=http%3A%2F%2Ffarm9.staticflickr.com%2F8391%2F8544074541_29a2c7a292_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=164963669&url=http%3A%2F%2Ffarm1.staticflickr.com%2F48%2F164963669_a8b04e7ac3_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=13290875115&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3711%2F13290875115_bed624a74c_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=3644223516&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3395%2F3644223516_a23eaafb99_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=3101281662&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3180%2F3101281662_d6c9f0e7f9_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=292917043&url=http%3A%2F%2Ffarm1.staticflickr.com%2F113%2F292917043_32f325372f_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=medium&id=213839709&url=http%3A%2F%2Ffarm1.staticflickr.com%2F81%2F213839709_889a86f0c9.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=157527342&url=http%3A%2F%2Ffarm1.staticflickr.com%2F48%2F157527342_00affe5f94_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=97204589&url=http%3A%2F%2Ffarm1.staticflickr.com%2F23%2F97204589_f70f4f6e25_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=5826755&url=http%3A%2F%2Ffarm1.staticflickr.com%2F6%2F5826755_8f7ca43323_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=13227507635&url=http%3A%2F%2Ffarm8.staticflickr.com%2F7257%2F13227507635_c2a72a5d92_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=12086742175&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2835%2F12086742175_cbd381f749_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=11934616456&url=http%3A%2F%2Ffarm3.staticflickr.com%2F2856%2F11934616456_8c2d52e95b_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=11608712713&url=http%3A%2F%2Ffarm8.staticflickr.com%2F7395%2F11608712713_c68a777d03_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=11191240794&url=http%3A%2F%2Ffarm6.staticflickr.com%2F5528%2F11191240794_e79d6399f8_m.jpg",
                                     @"http://photopin.com/phpflickr/getphoto.php?size=small&id=10531577523&url=http%3A%2F%2Ffarm4.staticflickr.com%2F3780%2F10531577523_0e077a4791_m.jpg"];
    
    for (NSInteger i=0; i < [URLStrings count]; i++) {
        NSString *URLString = URLStrings[i];
        NSString *thumbURLString = thumbnailURLStrings[i];

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
        localVideoAsset.thumbnailURL = [[NSBundle mainBundle] URLForResource:@"sea-movie-thumbnail" withExtension:@"jpg"];
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

/*
- (MUKMediaThumbnailsViewControllerToCarouselTransition)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController transitionToPresentCarouselViewController:(MUKMediaCarouselViewController *)carouselViewController forItemAtIndex:(NSInteger)idx
{
    return MUKMediaThumbnailsViewControllerToCarouselTransitionCrossDissolve;
}
 */

@end
