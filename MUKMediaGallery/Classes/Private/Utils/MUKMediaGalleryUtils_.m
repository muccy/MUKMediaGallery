//
//  MUKMediaGalleryUtils_.m
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 28/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKMediaGalleryUtils_.h"

@implementation MUKMediaGalleryUtils_

+ (NSBundle *)frameworkBundle {
    static NSBundle *frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate,^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"MUKMediaGallery" ofType:@"bundle"];
        frameworkBundle = [[NSBundle alloc] initWithPath:path];
    });
    
    return frameworkBundle;
}

+ (NSString *)localizedStringForKey:(NSString *)key comment:(NSString *)comment
{
    return [[self frameworkBundle] localizedStringForKey:key value:comment table:nil];
}

#pragma mark - Resources

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

+ (id)userProvidedAssetResourceForSelector:(SEL)selector mediaAsset:(id<MUKMediaAsset>)mediaAsset provided:(BOOL *)provided
{
    id resource = nil;
    if ([mediaAsset respondsToSelector:selector]) {
        resource = [mediaAsset performSelector:selector];
        
        if (provided != NULL) {
            *provided = YES;
        }
    }
    else {
        if (provided != NULL) {
            *provided = NO;
        }
    }
    
    return resource;
}

+ (NSURL *)assetResourceURLForSelector:(SEL)selector mediaAsset:(id<MUKMediaAsset>)mediaAsset
{
    NSURL *url = nil;
    if ([mediaAsset respondsToSelector:selector]) {
        url = [mediaAsset performSelector:selector];
    }
    
    return url;
}

+ (BOOL)assetResourceURLForSelector:(SEL)selector isInFileForMediaAsset:(id<MUKMediaAsset>)mediaAsset
{
    return [[self assetResourceURLForSelector:selector mediaAsset:mediaAsset] isFileURL];
}

+ (MUKImageFetcherSearchDomain)assetResourceURLForSelector:(SEL)selector searchDomainsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache file:(BOOL)file remote:(BOOL)remote
{
    MUKImageFetcherSearchDomain searchDomains = MUKImageFetcherSearchDomainNone;
    
    if (memoryCache) {
        searchDomains |= MUKImageFetcherSearchDomainMemoryCache;
    }
    
    if (file || remote || fileCache) {
        BOOL isFileURL = [self assetResourceURLForSelector:selector isInFileForMediaAsset:mediaAsset];
        
        if (file) {
            if (isFileURL) {
                searchDomains |= MUKImageFetcherSearchDomainFile;
            }
        }
        
        if (fileCache) {
            if (!isFileURL) {
                searchDomains |= MUKImageFetcherSearchDomainFileCache;
            }
        }
        
        if (remote) {
            if (!isFileURL) {
                searchDomains |= MUKImageFetcherSearchDomainRemote;
            }
        }
    }
    
    return searchDomains;
}

+ (MUKObjectCacheLocation)assetResourceURLForSelector:(SEL)selector cacheLocationsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache
{
    MUKObjectCacheLocation locations = MUKObjectCacheLocationNone;
    
    if (memoryCache) {
        locations |= MUKObjectCacheLocationMemory;
    }
    
    if (fileCache) {
        // Don't cache to file images which are already in a file
        if (![self assetResourceURLForSelector:selector isInFileForMediaAsset:mediaAsset])
        {
            locations |= MUKObjectCacheLocationFile;
        }
    }
    
    return locations;
}

+ (MUKURLConnection *)assetResourceURLForSelector:(SEL)selector connectionForMediaAsset:(id<MUKMediaAsset>)mediaAsset
{
    NSURL *assetURL = [self assetResourceURLForSelector:selector mediaAsset:mediaAsset];
    if (!assetURL) return nil;
    
    MUKURLConnection *connection = [MUKImageFetcher standardConnectionForImageAtURL:assetURL];
    connection.userInfo = mediaAsset;
    
    return connection;
}

#pragma clang diagnostic pop

#pragma mark - Thumbnails

+ (UIImage *)userProvidedThumbnailForMediaAsset:(id<MUKMediaAsset>)mediaAsset provided:(BOOL *)provided
{
    return [self userProvidedAssetResourceForSelector:@selector(mediaThumbnail) mediaAsset:mediaAsset provided:provided];
}

+ (NSURL *)thumbnailURLForMediaAsset:(id<MUKMediaAsset>)mediaAsset {
    return [self assetResourceURLForSelector:@selector(mediaThumbnailURL) mediaAsset:mediaAsset];
}

+ (BOOL)thumbnailIsInFileForMediaAsset:(id<MUKMediaAsset>)mediaAsset {
    return [self assetResourceURLForSelector:@selector(mediaThumbnailURL) isInFileForMediaAsset:mediaAsset];
}

+ (MUKImageFetcherSearchDomain)thumbnailSearchDomainsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache file:(BOOL)file remote:(BOOL)remote
{
    return [self assetResourceURLForSelector:@selector(mediaThumbnailURL) searchDomainsForMediaAsset:mediaAsset memoryCache:memoryCache fileCache:fileCache file:file remote:remote];
}

+ (MUKObjectCacheLocation)thumbnailCacheLocationsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache
{
    return [self assetResourceURLForSelector:@selector(mediaThumbnailURL) cacheLocationsForMediaAsset:mediaAsset memoryCache:memoryCache fileCache:fileCache];
}

+ (MUKURLConnection *)thumbnailConnectionForMediaAsset:(id<MUKMediaAsset>)mediaAsset
{
    return [self assetResourceURLForSelector:@selector(mediaThumbnailURL) connectionForMediaAsset:mediaAsset];
}

#pragma mark - Full Images

+ (UIImage *)userProvidedFullImageForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset provided:(BOOL *)provided
{
    return [self userProvidedAssetResourceForSelector:@selector(mediaFullImage) mediaAsset:mediaImageAsset provided:provided];
}

+ (NSURL *)fullImageURLForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset
{
    return [self assetResourceURLForSelector:@selector(mediaURL) mediaAsset:mediaImageAsset];
}

+ (BOOL)fullImageIsInFileForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset
{
    return [self assetResourceURLForSelector:@selector(mediaURL) isInFileForMediaAsset:mediaImageAsset];
}

+ (MUKImageFetcherSearchDomain)fullImageSearchDomainsForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache file:(BOOL)file remote:(BOOL)remote
{
    return [self assetResourceURLForSelector:@selector(mediaURL) searchDomainsForMediaAsset:mediaImageAsset memoryCache:memoryCache fileCache:fileCache file:file remote:remote];
}

+ (MUKObjectCacheLocation)fullImageCacheLocationsForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache
{
    return [self assetResourceURLForSelector:@selector(mediaURL) cacheLocationsForMediaAsset:mediaImageAsset memoryCache:memoryCache fileCache:fileCache];
}

+ (MUKURLConnection *)fullImageConnectionForMediaImageAsset:(id<MUKMediaImageAsset>)mediaImageAsset
{
    return [self assetResourceURLForSelector:@selector(mediaURL) connectionForMediaAsset:mediaImageAsset];
}

@end
