//
//  ThumbnailsViewController.h
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 02/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MUKMediaGallery/MUKMediaGallery.h>

@interface ThumbnailsViewController : UIViewController
@property (nonatomic, strong) IBOutlet MUKMediaThumbnailsView *thumbnailsView;

@property (nonatomic, strong) NSArray *mediaAssets;
@property (nonatomic) BOOL usesFileCache;

@end
