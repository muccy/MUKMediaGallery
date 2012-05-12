//
//  MUKMediaCarouselView_Thumbnails.h
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 12/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKMediaCarouselView.h"

@class MUKMediaCarouselCellView_;
@protocol MUKMediaAsset;
@interface MUKMediaCarouselView ()

/*
 Only memory in-memory thumbnails are supported
 */
- (void)configureThumbnailInCell_:(MUKMediaCarouselCellView_ *)cell withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index;
- (void)loadThumbnailForMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index inCell_:(MUKMediaCarouselCellView_ *)cell;

@end
