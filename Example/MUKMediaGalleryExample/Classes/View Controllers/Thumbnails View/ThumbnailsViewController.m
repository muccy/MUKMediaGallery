//
//  ThumbnailsViewController.m
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 02/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ThumbnailsViewController.h"
#import <MUKToolkit/MUKToolkit.h>

@interface ThumbnailsViewController ()

@end

@implementation ThumbnailsViewController
@synthesize thumbnailsView = thumbnailsView_;
@synthesize mediaAssets = mediaAssets_;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSURL *containerURL = [[MUK URLForTemporaryDirectory] URLByAppendingPathComponent:@"ThumbnailsViewExampleCache"];
    
    self.thumbnailsView.usesThumbnailImageFileCache = YES;
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
    
    [self.thumbnailsView reloadThumbnails];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
