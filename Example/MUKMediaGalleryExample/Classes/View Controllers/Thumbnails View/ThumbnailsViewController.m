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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.thumbnailsView.mediaAssets = self.mediaAssets;
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
