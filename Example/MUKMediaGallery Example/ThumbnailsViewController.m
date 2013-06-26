//
//  ThumbnailViewController.m
//  MUKMediaGallery Example
//
//  Created by Marco on 24/06/13.
//  Copyright (c) 2013 MeLive. All rights reserved.
//

#import "ThumbnailsViewController.h"
#import "MediaAsset.h"

@interface ThumbnailsViewController () <MUKMediaThumbnailsViewControllerDelegate>
@end

@implementation ThumbnailsViewController

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.title = @"Thumbnails Grid";
        self.delegate = self;
        self.mediaAssets = [[self class] newAssets];
    }
    
    return self;
}

#pragma mark - Private

+ (NSArray *)newAssets {
    NSMutableArray *mediaAssets = [[NSMutableArray alloc] init];
    
    for (NSInteger i=0; i<100; i++) {
        MediaAsset *remoteImageAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindImage];
        remoteImageAsset.thumbnailURL = [NSURL URLWithString:@"http://farm5.staticflickr.com/4092/4988725775_23993fbb41_t.jpg"];
        remoteImageAsset.URL = [NSURL URLWithString:@"http://farm5.staticflickr.com/4092/4988725775_23993fbb41_z.jpg"];
        remoteImageAsset.caption = @"Creative Commons Surfing Image";
        [mediaAssets addObject:remoteImageAsset];
        
        MediaAsset *localVideoAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindVideo];
        localVideoAsset.thumbnailURL = [MUK URLForImageFileNamed:@"sea-movie-thumbnail.jpg" bundle:nil];
        localVideoAsset.URL = [[NSBundle mainBundle] URLForResource:@"sea" withExtension:@"mp4"];
        localVideoAsset.caption = @"A local video asset downloaded from Flickr which has been recorded to be relaxing and entertaining";
        [mediaAssets addObject:localVideoAsset];
        
        MediaAsset *remoteVideoAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindVideo];
        remoteVideoAsset.URL = [NSURL URLWithString:@"http://mirrors.creativecommons.org/movingimages/Building_on_the_Past.mp4"];
        [mediaAssets addObject:remoteVideoAsset];
        
        MediaAsset *localImageAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindImage];
        localImageAsset.thumbnailURL = [MUK URLForImageFileNamed:@"palms-thumbnail.jpg" bundle:nil];
        localImageAsset.URL = [MUK URLForImageFileNamed:@"palms.jpg" bundle:nil];
        localImageAsset.caption = @"A local photo which represents a palm. Palms are a popular tree in many North African countries which is used in many ways.";
        [mediaAssets addObject:localImageAsset];
        
        MediaAsset *localAudioAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindAudio];
        localAudioAsset.thumbnailURL = [NSURL URLWithString:@"http://farm6.staticflickr.com/5178/5500963965_2776bf6a98_t.jpg"];
        localAudioAsset.URL = [[NSBundle mainBundle] URLForResource:@"SexForModerns-StopTheClock_64kb" withExtension:@"mp3"];
        [mediaAssets addObject:localAudioAsset];
        
        MediaAsset *youTubeVideoAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindYouTubeVideo];
        youTubeVideoAsset.duration = 906; // 15:06
        youTubeVideoAsset.thumbnailURL = [NSURL URLWithString:@"http://i2.ytimg.com/vi/UF8uR6Z6KLc/default.jpg"];
        youTubeVideoAsset.URL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=UF8uR6Z6KLc"];
        youTubeVideoAsset.caption = @"Steve Jobs at Stanford";
        [mediaAssets addObject:youTubeVideoAsset];
        
        MediaAsset *remoteAudioAsset = [[MediaAsset alloc] initWithKind:MUKMediaKindAudio];
        remoteAudioAsset.duration = 332.0; // 05:32
        remoteAudioAsset.URL = [NSURL URLWithString:@"http://ia600201.us.archive.org/21/items/SexForModerns-PenetratingLoveRay/SexForModerns-PenetratingLoveRay.mp3"];
        [mediaAssets addObject:remoteAudioAsset];
    }
    
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
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        UIImage *image = nil;
        
        if ([data length]) {
            image = [UIImage imageWithData:data];
        }
        
        completionHandler(image);
    }];
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

@end
