//
//  MUKMediaGalleryUtils_.h
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 28/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUKMediaAssetProtocol.h"
#import "MUKMediaImageAssetProtocol.h"
#import "MUKImageFetcher.h"
#import <MUKScrolling/MUKScrolling.h>

@interface MUKMediaGalleryUtils_ : NSObject
+ (NSBundle *)frameworkBundle;
+ (NSString *)localizedStringForKey:(NSString *)key comment:(NSString *)comment;
@end

@interface MUKMediaGalleryUtils_ (Resources)
+ (id)userProvidedAssetResourceForSelector:(SEL)selector mediaAsset:(id<MUKMediaAsset>)mediaAsset provided:(BOOL *)provided;

+ (NSURL *)assetResourceURLForSelector:(SEL)selector mediaAsset:(id<MUKMediaAsset>)mediaAsset;
+ (BOOL)assetResourceForSelector:(SEL)selector isInFileForMediaAsset:(id<MUKMediaAsset>)mediaAsset;

+ (MUKImageFetcherSearchDomain)assetResourceURLForSelector:(SEL)selctor searchDomainsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache file:(BOOL)file remote:(BOOL)remote;
+ (MUKObjectCacheLocation)assetResourceURLForSelector:(SEL)selector cacheLocationsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache;

+ (MUKURLConnection *)assetResourceURLForSelector:(SEL)selector connectionForMediaAsset:(id<MUKMediaAsset>)mediaAsset;
@end

@interface MUKMediaGalleryUtils_ (Thumbnails)
+ (UIImage *)userProvidedThumbnailForMediaAsset:(id<MUKMediaAsset>)mediaAsset provided:(BOOL *)provided;

+ (NSURL *)thumbnailURLForMediaAsset:(id<MUKMediaAsset>)mediaAsset;
+ (BOOL)thumbnailIsInFileForMediaAsset:(id<MUKMediaAsset>)mediaAsset;

+ (MUKImageFetcherSearchDomain)thumbnailSearchDomainsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache file:(BOOL)file remote:(BOOL)remote;
+ (MUKObjectCacheLocation)thumbnailCacheLocationsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache;

+ (MUKURLConnection *)thumbnailConnectionForMediaAsset:(id<MUKMediaAsset>)mediaAsset;
@end

@interface MUKMediaGalleryUtils_ (FullImages)
+ (UIImage *)userProvidedFullImageForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset provided:(BOOL *)provided;

+ (NSURL *)fullImageURLForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset;
+ (BOOL)fullImageIsInFileForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset;

+ (MUKImageFetcherSearchDomain)fullImageSearchDomainsForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache file:(BOOL)file remote:(BOOL)remote;
+ (MUKObjectCacheLocation)fullImageCacheLocationsForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache;

+ (MUKURLConnection *)fullImageConnectionForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset;
@end

@interface MUKMediaGalleryUtils_ (MediaAssets)
+ (NSIndexSet *)indexesOfMediaAsset:(id<MUKMediaAsset>)mediaAsset inMediaAssets:(NSArray *)mediaAssets;
+ (BOOL)isVisibleMediaAsset:(id<MUKMediaAsset>)mediaAsset fromMediaAssets:(NSArray *)mediaAssets inGridView:(MUKGridView *)gridView;
@end
