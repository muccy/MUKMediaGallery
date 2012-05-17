//
//  RootTableViewController.m
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 02/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RootTableViewController.h"

#import "ThumbnailsViewController.h"
#import "ImageFetcherViewController.h"
#import "CarouselViewController.h"
#import "ChainedViewController.h"

#import <MUKToolkit/MUKToolkit.h>

@interface Row_ : NSObject 
@property (nonatomic, strong) NSString *title, *subtitle;
@property (nonatomic, copy) void (^selectionHandler)(void);
@end

@implementation Row_
@synthesize title, subtitle;
@synthesize selectionHandler;
@end

#pragma mark - 
#pragma mark - 

@interface RootTableViewController ()
@property (nonatomic, strong) NSArray *rows_;
- (NSArray *)standardMediaAssets_;
- (NSArray *)remoteThumbnailsAssets_;
@end

@implementation RootTableViewController
@synthesize rows_ = rows__;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"MUKMediaGallery";
    }
    return self;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Accessors

- (NSArray *)rows_ {
    if (rows__ == nil) {
        NSMutableArray *rows = [[NSMutableArray alloc] init];
        __unsafe_unretained RootTableViewController *weakSelf = self;
        
        Row_ *row = [[Row_ alloc] init];
        row.title = @"Image Fetcher";
        row.subtitle = @"MUKImageFetch in a UITableViewController";
        row.selectionHandler = ^{
            ImageFetcherViewController *viewController = [[ImageFetcherViewController alloc] initWithStyle:UITableViewStylePlain];
            [weakSelf.navigationController pushViewController:viewController animated:YES];
        };
        [rows addObject:row];  
        
        row = [[Row_ alloc] init];
        row.title = @"Thumbnails View";
        row.subtitle = @"MUKMediaThumbnailsView";
        row.selectionHandler = ^{
            ThumbnailsViewController *viewController = [[ThumbnailsViewController alloc] initWithNibName:nil bundle:nil];
            viewController.usesFileCache = YES;
            viewController.mediaAssets = [weakSelf standardMediaAssets_];
            [weakSelf.navigationController pushViewController:viewController animated:YES];
        };
        [rows addObject:row]; 
        
        row = [[Row_ alloc] init];
        row.title = @"Remote Thumbnails View";
        row.subtitle = @"MUKMediaThumbnailsView";
        row.selectionHandler = ^{
            ThumbnailsViewController *viewController = [[ThumbnailsViewController alloc] initWithNibName:nil bundle:nil];
            viewController.usesFileCache = NO;
            viewController.mediaAssets = [weakSelf remoteThumbnailsAssets_];
            [weakSelf.navigationController pushViewController:viewController animated:YES];
        };
        [rows addObject:row]; 
        
        row = [[Row_ alloc] init];
        row.title = @"Carousel View";
        row.subtitle = @"MUKMediaCarouselView";
        row.selectionHandler = ^{
            CarouselViewController *viewController = [[CarouselViewController alloc] initWithNibName:nil bundle:nil];
            viewController.mediaAssets = [weakSelf standardMediaAssets_];
            [weakSelf.navigationController pushViewController:viewController animated:YES];
        };
        [rows addObject:row];  
        
        row = [[Row_ alloc] init];
        row.title = @"Auto-Chained";
        row.subtitle = @"MUKMediaThumbnailsViewController";
        row.selectionHandler = ^{
            ChainedViewController *viewController = [[ChainedViewController alloc] initWithNibName:nil bundle:nil completion:^(MUKMediaThumbnailsViewController *vc)
            {
                NSURL *cacheContainer = [[MUK URLForTemporaryDirectory] URLByAppendingPathComponent:@"Auto-Chained-Thumbs-Cache"];
                
                vc.thumbnailsView.usesThumbnailImageFileCache = YES;
                vc.thumbnailsView.thumbnailsFetcher.cache.fileCacheURLHandler = ^(id key)
                {
                    NSURL *cacheURL = [MUKObjectCache standardFileCacheURLForStringKey:[key absoluteString] containerURL:cacheContainer];
                    
                    return cacheURL;
                };
                
                vc.thumbnailsView.mediaAssets = [weakSelf standardMediaAssets_];
                [vc.thumbnailsView reloadThumbnails];
            }];
            
            NSURL *cacheContainer = [[MUK URLForTemporaryDirectory] URLByAppendingPathComponent:@"Auto-Chained-Full-Cache"];
            viewController.carouselConfigurator = ^(MUKMediaCarouselViewController *carouselController, NSInteger index)
            {
                carouselController.carouselView.imagesFetcher.cache.fileCacheURLHandler = ^(id key)
                {
                    NSURL *cacheURL = [MUKObjectCache standardFileCacheURLForStringKey:[key absoluteString] containerURL:cacheContainer];
                    return cacheURL;
                };
            };
            
            [weakSelf.navigationController pushViewController:viewController animated:YES];
        };
        [rows addObject:row];  
        
        rows__ = rows;
    }
    
    return rows__;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.rows_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    Row_ *row = [self.rows_ objectAtIndex:indexPath.row];
    cell.textLabel.text = row.title;
    cell.detailTextLabel.text = row.subtitle;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Row_ *row = [self.rows_ objectAtIndex:indexPath.row];
    
    if (row.selectionHandler) {
        row.selectionHandler();
    }
}

#pragma mark - Private

- (NSArray *)standardMediaAssets_ {
    NSMutableArray *mediaAssets = [[NSMutableArray alloc] init];
    
    for (NSInteger i=0; i<100; i++) {
        MUKMediaImageAsset *remoteImageAsset = [[MUKMediaImageAsset alloc] init];
        remoteImageAsset.thumbnailURL = [NSURL URLWithString:@"http://farm5.staticflickr.com/4092/4988725775_23993fbb41_t.jpg"];
        remoteImageAsset.mediaURL = [NSURL URLWithString:@"http://farm5.staticflickr.com/4092/4988725775_23993fbb41_z.jpg"];
        remoteImageAsset.caption = @"Creative Commons Surfing Image";
        [mediaAssets addObject:remoteImageAsset];
        
        MUKMediaVideoAsset *localVideoAsset = [[MUKMediaVideoAsset alloc] init];
        localVideoAsset.thumbnailURL = [MUK URLForImageFileNamed:@"sea-movie-thumbnail.jpg" bundle:nil];
        localVideoAsset.mediaURL = [[NSBundle mainBundle] URLForResource:@"sea" withExtension:@"mp4"];
        localVideoAsset.caption = @"A local video asset downloaded from Flickr which has been recorded to be relaxing and entertaining";
        [mediaAssets addObject:localVideoAsset];
        
        MUKMediaVideoAsset *remoteVideoAsset = [[MUKMediaVideoAsset alloc] init];
        remoteVideoAsset.mediaURL = [NSURL URLWithString:@"http://mirrors.creativecommons.org/movingimages/Building_on_the_Past.mp4"];
        [mediaAssets addObject:remoteVideoAsset];
        
        MUKMediaImageAsset *localImageAsset = [[MUKMediaImageAsset alloc] init];
        localImageAsset.thumbnailURL = [MUK URLForImageFileNamed:@"palms-thumbnail.jpg" bundle:nil];
        localImageAsset.mediaURL = [MUK URLForImageFileNamed:@"palms.jpg" bundle:nil];
        localImageAsset.caption = @"A local photo which represents a palm. Palms are a popular tree in many North African countries which is used in many ways.";
        [mediaAssets addObject:localImageAsset];
        
        MUKMediaAudioAsset *localAudioAsset = [[MUKMediaAudioAsset alloc] init];
        localAudioAsset.thumbnailURL = [NSURL URLWithString:@"http://farm6.staticflickr.com/5178/5500963965_2776bf6a98_t.jpg"];
        localAudioAsset.mediaURL = [[NSBundle mainBundle] URLForResource:@"SexForModerns-StopTheClock_64kb" withExtension:@"mp3"];
        [mediaAssets addObject:localAudioAsset];
        
        MUKMediaVideoAsset *youTubeVideoAsset = [[MUKMediaVideoAsset alloc] init];
        youTubeVideoAsset.source = MUKMediaVideoAssetSourceYouTube;
        youTubeVideoAsset.duration = 906; // 15:06
        youTubeVideoAsset.thumbnailURL = [NSURL URLWithString:@"http://i2.ytimg.com/vi/UF8uR6Z6KLc/default.jpg"];
        youTubeVideoAsset.mediaURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=UF8uR6Z6KLc"];
        [mediaAssets addObject:youTubeVideoAsset];
        
        MUKMediaAudioAsset *remoteAudioAsset = [[MUKMediaAudioAsset alloc] init];
        remoteAudioAsset.duration = 332; // 05:32
        remoteAudioAsset.mediaURL = [NSURL URLWithString:@"http://ia600201.us.archive.org/21/items/SexForModerns-PenetratingLoveRay/SexForModerns-PenetratingLoveRay.mp3"];
        [mediaAssets addObject:remoteAudioAsset];
    }
    
    return mediaAssets;
}

- (NSArray *)remoteThumbnailsAssets_ {
    NSArray *URLStrings = [[NSArray alloc] initWithObjects:
                           @"http://farm8.staticflickr.com/7056/6859998891_38c6e8111f_t.jpg",
                           @"http://farm7.staticflickr.com/6039/6327833811_16f34da1db_t.jpg",
                           @"http://farm6.staticflickr.com/5470/7180036482_c2ece9b447_t.jpg",
                           @"http://farm8.staticflickr.com/7189/7098047023_b603860d23_t.jpg",
                           @"http://farm8.staticflickr.com/7014/6695011735_7fd1b9e32a_t.jpg",
                           @"http://farm9.staticflickr.com/8006/7215377670_4c4c1c04b4_t.jpg",
                           @"http://farm8.staticflickr.com/7084/7215352896_77d833cab0_t.jpg",
                           @"http://farm6.staticflickr.com/5332/7215355798_5d6446cdf7_t.jpg",
                           @"http://farm8.staticflickr.com/7081/7215188826_9eaaf57151_t.jpg",
                           @"http://farm1.staticflickr.com/188/417924629_6832e79c98_t.jpg",
                           @"http://farm4.staticflickr.com/3552/3284140306_35b859c620_t.jpg",
                           @"http://farm2.staticflickr.com/1087/994551622_b3a4e2be32_t.jpg",
                           @"http://farm4.staticflickr.com/3159/3019874112_769b607d2f_t.jpg",
                           @"http://farm3.staticflickr.com/2361/2351000967_245c4d028d_t.jpg",
                           @"http://farm3.staticflickr.com/2249/3005103471_3bd92e02e3_t.jpg",
                           @"http://farm1.staticflickr.com/60/214965701_afa4d5f824_t.jpg",
                           @"http://farm8.staticflickr.com/7213/6962165646_5cb8effa10_t.jpg",
                           @"http://farm4.staticflickr.com/3255/3153346586_ae900be48a_t.jpg",
                           @"http://farm4.staticflickr.com/3136/2745459668_659a5095ca_t.jpg",
                           @"http://farm3.staticflickr.com/2334/2411062263_43b8965a00_t.jpg",
                           @"http://farm3.staticflickr.com/2157/2232204467_7a22a0953d_t.jpg",
                           @"http://farm3.staticflickr.com/2279/1750062309_6f1411539a_t.jpg",
                           @"http://farm4.staticflickr.com/3444/3244546342_69910d9747_t.jpg",
                           @"http://farm1.staticflickr.com/49/172843023_3bcd0d3a10_t.jpg",
                           @"http://farm4.staticflickr.com/3044/2684002442_d7eb40735a_t.jpg",
                           @"http://farm4.staticflickr.com/3338/3274183756_10411ace99_t.jpg",
                           @"http://farm3.staticflickr.com/2267/2084104463_be10c746f0_t.jpg",
                           @"http://farm6.staticflickr.com/5323/7007199108_f5461e738c_t.jpg",
                           @"http://farm4.staticflickr.com/3327/5711422645_f36dc15bf8_t.jpg",
                           @"http://farm8.staticflickr.com/7042/6975498429_b7308492f6_t.jpg",
                           @"http://farm1.staticflickr.com/76/190531770_b02d2ff306_t.jpg",
                           @"http://farm7.staticflickr.com/6201/6128326891_8d9e03a2d1_t.jpg",
                           @"http://farm4.staticflickr.com/3300/3652077613_6d9d96b1f3_t.jpg",
                           @"http://farm3.staticflickr.com/2234/2056165222_4593805e6d_t.jpg",
                           @"http://farm5.staticflickr.com/4003/4253832484_282a868969_t.jpg",
                           @"http://farm5.staticflickr.com/4053/5143024453_006c915c0d_t.jpg",
                           nil];
    
    NSArray *assets = [MUK array:URLStrings map:^id(id obj, NSInteger index, BOOL *exclude, BOOL *stop) 
    {
        MUKMediaImageAsset *imageAsset = [[MUKMediaImageAsset alloc] init];
        imageAsset.thumbnailURL = [[NSURL alloc] initWithString:obj];
        return imageAsset;
    }];
    
    return assets;
}

@end
