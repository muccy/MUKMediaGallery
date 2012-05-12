//
//  MUKMediaGalleryUtils_.h
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 28/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUKMediaAssetProtocol.h"
#import "MUKImageFetcher.h"

@interface MUKMediaGalleryUtils_ : NSObject
+ (NSBundle *)frameworkBundle;
+ (NSString *)localizedStringForKey:(NSString *)key comment:(NSString *)comment;
@end

@interface MUKMediaGalleryUtils_ (Thumbnails)
+ (UIImage *)userProvidedThumbnailForMediaAsset:(id<MUKMediaAsset>)mediaAsset provided:(BOOL *)provided;

+ (NSURL *)thumbnailURLForMediaAsset:(id<MUKMediaAsset>)mediaAsset;
+ (BOOL)thumbnailIsInFileForMediaAsset:(id<MUKMediaAsset>)mediaAsset;

+ (MUKImageFetcherSearchDomain)thumbnailSearchDomainsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache file:(BOOL)file remote:(BOOL)remote;
+ (MUKObjectCacheLocation)thumbnailCacheLocationsForMediaAsset_:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache;

+ (MUKURLConnection *)thumbnailConnectionForMediaAsset:(id<MUKMediaAsset>)mediaAsset;
@end