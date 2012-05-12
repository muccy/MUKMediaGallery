//
//  MUKMediaCarouselView_FullImage.h
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 12/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <MUKMediaGallery/MUKMediaGallery.h>

@protocol MUKMediaAsset, MUKMediaImageAsset;
@interface MUKMediaCarouselView ()

- (void)loadFullImageForMediaImageAsset_:(id<MUKMediaImageAsset>)mediaImageAsset onlyFromMemory_:(BOOL)onlyFromMemory atIndex_:(NSInteger)index inCell_:(MUKMediaCarouselImageCellView_ *)cell;

@end
