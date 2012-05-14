//
//  ChainedViewController.m
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 14/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChainedViewController.h"

@implementation ChainedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil completion:(void (^)(MUKMediaThumbnailsViewController *))completionHandler
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil completion:completionHandler];
    if (self) {
        self.title = @"Thumbnails";
    }
    
    return self;
}

@end
