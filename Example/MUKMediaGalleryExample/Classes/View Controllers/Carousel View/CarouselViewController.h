//
//  CarouselViewController.h
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 12/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MUKMediaGallery/MUKMediaGallery.h>

@interface CarouselViewController : UIViewController
@property (nonatomic, strong) IBOutlet MUKMediaCarouselView *carouselView;

@property (nonatomic, strong) NSArray *mediaAssets;
@end
