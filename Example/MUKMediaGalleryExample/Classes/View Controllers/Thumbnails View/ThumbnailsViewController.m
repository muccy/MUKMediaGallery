//
//  ThumbnailsViewController.m
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 02/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ThumbnailsViewController.h"

@interface ThumbnailsViewController ()

@end

@implementation ThumbnailsViewController
@synthesize thumbnailsView = thumbnailsView_;
@synthesize mediaAssets = mediaAssets_;
@synthesize usesFileCache = usesFileCache_;

- (void)dealloc {
    self.thumbnailsView.thumbnailSelectionHandler = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSURL *containerURL = [[MUK URLForTemporaryDirectory] URLByAppendingPathComponent:@"ThumbnailsViewExampleCache"];
    
    self.thumbnailsView.usesThumbnailImageFileCache = self.usesFileCache;
    self.thumbnailsView.thumbnailsFetcher.cache.fileCacheURLHandler = ^(id key) 
    {
        NSString *URLString = [key absoluteString];
        NSURL *cacheURL = [MUKObjectCache standardFileCacheURLForStringKey:URLString containerURL:containerURL];
        
        return cacheURL;
    };
    
    self.thumbnailsView.mediaAssets = self.mediaAssets;
    
    self.thumbnailsView.thumbnailSelectionHandler = ^(NSInteger index) {
        NSLog(@"Selected media asset at index %i", index);
    };
    
    self.thumbnailsView.thumbnailConnectionHandler = ^(id<MUKMediaAsset> mediaAsset, NSInteger index)
    {
        MUKURLConnection *connection = [MUKImageFetcher standardConnectionForImageAtURL:[mediaAsset mediaThumbnailURL]];
        connection.runsInBackground = YES;
        
        NSMutableURLRequest *request = [connection.request mutableCopy];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        connection.request = request;
        
        return connection;
    };
    
    [self.thumbnailsView reloadThumbnails];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.thumbnailsView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
