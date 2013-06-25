//
//  ThumbnailViewController.m
//  MUKMediaGallery Example
//
//  Created by Marco on 24/06/13.
//  Copyright (c) 2013 MeLive. All rights reserved.
//

#import "ThumbnailsViewController.h"

@interface ThumbnailsViewController () <MUKMediaThumbnailsViewControllerDelegate>
@end

@implementation ThumbnailsViewController

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.title = @"Thumbnails Grid";
        self.delegate = self;
    }
    
    return self;
}

#pragma mark - <MUKMediaThumbnailsViewControllerDelegate>

- (NSInteger)numberOfItemsInThumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController
{
    return 100;
}

- (void)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController loadImageForItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *))completionHandler
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.lottimista.com/wp-content/uploads/2011/03/Steve-Jobs-a-Stanford1.jpg"]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        UIImage *image = [UIImage imageWithData:data];
        completionHandler(image);
    }];
}

- (MUKMediaAttributes *)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController attributesForItemAtIndex:(NSInteger)idx
{
    MUKMediaAttributes *attributes = [[MUKMediaAttributes alloc] initWithKind:MUKMediaKindAudio];
    [attributes setCaptionWithTimeInterval:125.0];
    return attributes;
}

@end
