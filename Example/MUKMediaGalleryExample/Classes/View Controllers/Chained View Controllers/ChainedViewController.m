//
//  ChainedViewController.m
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 14/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChainedViewController.h"

@interface ChainedViewController ()
- (void)donePressed_:(id)sender;
@end

@implementation ChainedViewController
@synthesize doneHandler = doneHandler_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil completion:(void (^)(MUKMediaThumbnailsViewController *))completionHandler
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil completion:completionHandler];
    if (self) {
        self.title = @"Thumbnails";
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.doneHandler) {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed_:)];
        self.navigationItem.leftBarButtonItem = doneItem;
    }
}

- (void)donePressed_:(id)sender {
    if (self.doneHandler) {
        self.doneHandler();
    }
}

@end
