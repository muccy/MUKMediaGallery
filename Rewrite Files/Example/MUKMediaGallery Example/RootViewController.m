//
//  RootViewController.m
//  MUKMediaGallery Example
//
//  Created by Marco on 03/07/13.
//  Copyright (c) 2013 MeLive. All rights reserved.
//

#import "RootViewController.h"
#import "ThumbnailsViewController.h"

@interface RootViewController ()
@property (nonatomic) BOOL pushedThumbnailsGridViewController;
@end

@implementation RootViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.pushedThumbnailsGridViewController) {
        self.pushedThumbnailsGridViewController = YES;
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            ThumbnailsViewController *thumbnailsViewController = [[ThumbnailsViewController alloc] init];
            [self.navigationController pushViewController:thumbnailsViewController animated:YES];
        });
    }
}

- (void)goToGridButtonPressed:(id)sender {
    ThumbnailsViewController *thumbnailsViewController = [[ThumbnailsViewController alloc] init];
    [self.navigationController pushViewController:thumbnailsViewController animated:YES];
}

@end
