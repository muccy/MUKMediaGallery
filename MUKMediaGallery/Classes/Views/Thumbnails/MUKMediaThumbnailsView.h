// Copyright (c) 2012, Marco Muccinelli
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
// * Neither the name of the <organization> nor the
// names of its contributors may be used to endorse or promote products
// derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <UIKit/UIKit.h>
#import <MUKMediaGallery/MUKImageFetcher.h>
#import <MUKMediaGallery/MUKMediaAssetProtocol.h>

/**
 A view which displays a grid of thumbnails.
 */
@interface MUKMediaThumbnailsView : UIView
/** @name Properties */
/**
 Media assets.
 
 This an array of instances which conform to MUKMediaAsset protocol.
 */
@property (nonatomic, strong) NSArray *mediaAssets;
/**
 Image fetcher which loads and stores thumbnails.
  
 This object is lazy loaded, but you can customize its behaviour.
 
 @warning You should set file cache handlers (on `thumbnailsFetcher.cache`)
 if you decide to cache thumbnails to file. Mind that cache key is 
 [MUKMediaAsset mediaThumbnailURL].
 @warning You can not set [MUKImageFetcher shouldStartConnectionHandler] 
 because it is used internally not to load invisible thumbnails.
 */
@property (nonatomic, strong, readonly) MUKImageFetcher *thumbnailsFetcher;
/**
 Cache thumbnail images to file.
 
 Default is `NO`. If `YES`, thumbnails are searched/saved in file cache too.
 
 @warning You should set file cache handlers (on `thumbnailsFetcher.cache`)
 if you decide to cache thumbnails to file. Mind that cache key is 
 [MUKMediaAsset mediaThumbnailURL].
 */
@property (nonatomic) BOOL usesThumbnailImageFileCache;
/**
 Cleans thumbnails memory cache when reloadThumbnails is called.
 
 Default is `NO`.
 */
@property (nonatomic) BOOL purgesThumbnailsMemoryCacheWhenReloading;
/**
 Size of thumbnails.
 
 Default is `{79, 79}`.
 */
@property (nonatomic) CGSize thumbnailSize;
/**
 Space between thumbnails.
 
 Default is `{4, 4}`.
 */
@property (nonatomic) CGSize thumbnailOffset;
/**
 Top padding over the thumbnails.
 
 This is useful when you put this view into a navigation controller with
 transparent navigation bar.
 
    CGFloat statusBarHeight;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) 
    {
       statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
    else {
       statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.width;
    }
 
    CGFloat topPadding = statusBarHeight + self.navigationController.navigationBar.frame.size.height;
 */
@property (nonatomic) CGFloat topPadding;
/**
 Displays media asset count under thumbnails.
 
 This count is displayed only if there media assets in mediaAssets array.
 
 Default is `YES`.
 */
@property (nonatomic) BOOL displaysMediaAssetsCount;
/**
 Shows selection on touch.
 
 Default is `YES`.
 */
@property (nonatomic) BOOL showsSelection;

/** @name Handlers */
/**
 Handler called when a thumbnail is selected.
 */
@property (nonatomic, copy) void (^thumbnailSelectionHandler)(NSInteger index);
/**
 Handler called to create a connection to download a thumbnail.
 
 Return `nil` in order to use a standard connection.
 
 @warning [MUKURLConnection userInfo] will be overwritten with `mediaAsset`.
 */
@property (nonatomic, copy) MUKURLConnection* (^thumbnailConnectionHandler)(id<MUKMediaAsset> mediaAsset, NSInteger index);

/** @name Methods */
/**
 Reload thumbnail cells.
 */
- (void)reloadThumbnails;
/**
 Scrolls to media asset thumbnail.
 
 @param index Media asset index.
 @param animated `YES` if you want an animated transition.
*/
- (void)scrollToMediaAssetAtIndex:(NSInteger)index animated:(BOOL)animated;
/**
 Scroll to top.
 
 This is different to scrollToMediaAssetAtIndex:animated: if you
 set topPadding.
 
 @param animated `YES` if you want an animated transition.
 */
- (void)scrollToTopAnimated:(BOOL)animated;
@end


@interface MUKMediaThumbnailsView (Selection)
/**
 Selected media asset index.
 
 If no media asset is selected, it returns `NSNotFound`.
 
 @return Selected media asset index or `NSNotFound`.
 */
- (NSInteger)selectedMediaAssetIndex;
/**
 Deselects selected media asset (if any).
 */
- (void)deselectSelectedMediaAsset;
/**
 Media asset selection callback.
 
 This callback is invoked when a tap is detected on a media asset cell.
 
 Default implementation calls thumbnailSelectionHandler.
 
 @param index Media asset index.
 @warning It is not safe to deselect media asset here synchronously because
 of internal tap handling (touches began handling is postponed because of
 grid's scrolling, so tap gesture could arrive before cell selection).
 Please deselect media asset as you do with `UITableView` instances (e.g. in 
 `viewWillAppear:` method).
 */
- (void)didSelectMediaAssetAtIndex:(NSInteger)index;
@end
