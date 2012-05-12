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
 A view which displays a paginated carousel of medias.
 */
@interface MUKMediaCarouselView : UIView
/** @name Properties */
/**
 Media assets.
 
 This an array of instances which conform to MUKMediaAsset protocol.
 */
@property (nonatomic, strong) NSArray *mediaAssets;
/**
 Image fetcher which loads and stores thumbnails (only in memory).
 
 This object is lazy loaded, but you can customize its behaviour.
 
 You could also reuse a cache (e.g. reusing an already populated 
 MUKMediaThumbnailsView's cache).
 
 @warning You can not set [MUKImageFetcher shouldStartConnectionHandler] 
 because it is used internally not to load invisible thumbnails.
 */
@property (nonatomic, strong, readonly) MUKImageFetcher *thumbnailsFetcher;
/**
 Image fetcher which loads and stores full images.
 
 This object is lazy loaded, but you can customize its behaviour.
 
 @warning You should set file cache handlers (on `imagesFetcher.cache`)
 if you decide to cache images to file. Mind that cache key is 
 [MUKMediaAsset mediaURL].
 @warning You can not set [MUKImageFetcher shouldStartConnectionHandler] 
 because it is used internally not to load invisible images.
 */
@property (nonatomic, strong, readonly) MUKImageFetcher *imagesFetcher;
/**
 Cache images to memory.
 
 Default is `NO`.
 
 @warning Memory cache is disabled by default because RAM usage may
 become expensive with big images. If you know you images are not too big,
 you could enable memory cache to make transition more fluid. Mind that cache 
 key is [MUKMediaAsset mediaURL].
 */
@property (nonatomic) BOOL usesImageMemoryCache;
/**
 Cache images to file.
 
 Default is `YES` and so images are searched/saved in file cache too 
 by default.
 
 @warning You should set file cache handlers (on `imagesFetcher.cache`)
 if you decide to cache images to file. Mind that cache key is 
 [MUKMediaAsset mediaURL].
 */
@property (nonatomic) BOOL usesImageFileCache;
/**
 Cleans images memory cache when reloadMedias is called.
 
 Default is `YES`.
 */
@property (nonatomic) BOOL purgesImagesMemoryCacheWhenReloading;
/**
 Space between medias.
 
 Default is `20.0f`.
 */
@property (nonatomic) CGFloat mediaOffset;
/**
 Minimum zoom scale for an image.
 
 Default is `1.0f`
 */
@property (nonatomic) float imageMinimumZoomScale;
/**
 Maximum zoom scale for an image.
 
 Default is `3.0f`
 */
@property (nonatomic) float imageMaximumZoomScale;

/** @name Methods */
/**
 Reload media views.
 */
- (void)reloadMedias;
@end
