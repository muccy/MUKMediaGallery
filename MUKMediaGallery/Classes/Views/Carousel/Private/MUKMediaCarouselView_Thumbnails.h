//
//  MUKMediaCarouselView_Thumbnails.h
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 12/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKMediaCarouselView.h"

@class MUKMediaCarouselImageCellView_;
@protocol MUKMediaAsset;
@interface MUKMediaCarouselView ()

- (void)configureThumbnailInCell_:(MUKMediaCarouselImageCellView_ *)cell withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index;

- (void)loadThumbnailForMediaAsset_:(id<MUKMediaAsset>)mediaAsset onlyFromMemory_:(BOOL)onlyFromMemory atIndex_:(NSInteger)index inCell_:(MUKMediaCarouselImageCellView_ *)cell;

- (void)loadVisibleThumbnails_;
- (void)loadThumbnailsInCells_:(NSSet *)cells;

@end
