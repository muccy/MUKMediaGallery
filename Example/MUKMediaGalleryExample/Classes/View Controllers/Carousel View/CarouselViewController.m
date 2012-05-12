//
//  CarouselViewController.m
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 12/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CarouselViewController.h"
#import <MUKToolkit/MUKToolkit.h>

@interface CarouselViewController ()

@end

@implementation CarouselViewController
@synthesize carouselView = carouselView_;
@synthesize mediaAssets = mediaAssets_;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.carouselView.mediaAssets = self.mediaAssets;
    [self.carouselView reloadMedias];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.carouselView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
