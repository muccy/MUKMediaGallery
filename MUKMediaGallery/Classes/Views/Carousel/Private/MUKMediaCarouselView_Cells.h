//
//  MUKMediaCarouselView_Cells.h
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 12/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKMediaCarouselView.h"

@protocol MUKMediaAsset;
@class MUKMediaCarouselCellView_;
@class MUKGridCellOptions;
@interface MUKMediaCarouselView ()

- (MUKMediaCarouselCellView_ *)createOrDequeueCellForMediaAsset_:(id<MUKMediaAsset>)mediaAsset;

- (void)configureCellView_:(MUKMediaCarouselCellView_ *)cellView withMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index;

- (void)loadMediaForMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index onlyFromMemory_:(BOOL)onlyFromMemory inCell_:(MUKMediaCarouselCellView_ *)cellView whichHadMediaAsset_:(id<MUKMediaAsset>)prevMediaAsset;
- (void)didLoadMediaAsset_:(id<MUKMediaAsset>)mediaAsset atIndex_:(NSInteger)index inCell_:(MUKMediaCarouselCellView_ *)cellView;
- (BOOL)isLoadedMediaAssetAtIndex_:(NSInteger)index;

- (void)loadVisibleMedias_;
- (void)loadMediaInCell_:(MUKMediaCarouselCellView_ *)cellView;

- (MUKGridCellOptions *)cellOptionsForMediaAsset_:(id<MUKMediaAsset>)mediaAsset permitsZoomIfRequested_:(BOOL)permitsZoom;

@end
