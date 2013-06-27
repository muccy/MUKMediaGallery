//
//  CarouselViewController.m
//  MUKMediaGallery Example
//
//  Created by Marco on 27/06/13.
//  Copyright (c) 2013 MeLive. All rights reserved.
//

#import "CarouselViewController.h"

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

@end
