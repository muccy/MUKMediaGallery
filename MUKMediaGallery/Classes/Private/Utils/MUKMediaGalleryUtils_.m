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

#pragma mark - Thumbnails

+ (UIImage *)userProvidedThumbnailForMediaAsset:(id<MUKMediaAsset>)mediaAsset provided:(BOOL *)provided
{
    UIImage *image = nil;
    if ([mediaAsset respondsToSelector:@selector(mediaThumbnail)]) {
        image = [mediaAsset mediaThumbnail];
        
        if (provided != NULL) {
            *provided = YES;
        }
    }
    else {
        if (provided != NULL) {
            *provided = NO;
        }
    }
    
    return image;
}

+ (NSURL *)thumbnailURLForMediaAsset:(id<MUKMediaAsset>)mediaAsset {
    NSURL *url = nil;
    if ([mediaAsset respondsToSelector:@selector(mediaThumbnailURL)]) {
        url = [mediaAsset mediaThumbnailURL];
    }
    
    return url;
}

+ (BOOL)thumbnailIsInFileForMediaAsset:(id<MUKMediaAsset>)mediaAsset {
    NSURL *url = [[self class] thumbnailURLForMediaAsset:mediaAsset];
    return [url isFileURL];
}

+ (MUKImageFetcherSearchDomain)thumbnailSearchDomainsForMediaAsset:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache file:(BOOL)file remote:(BOOL)remote
{
    MUKImageFetcherSearchDomain searchDomains = MUKImageFetcherSearchDomainNone;
    
    if (memoryCache) {
        searchDomains |= MUKImageFetcherSearchDomainMemoryCache;
    }
    
    if (file || remote || fileCache) {
        BOOL isFileURL = [self thumbnailIsInFileForMediaAsset:mediaAsset];
        
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

+ (MUKObjectCacheLocation)thumbnailCacheLocationsForMediaAsset_:(id<MUKMediaAsset>)mediaAsset memoryCache:(BOOL)memoryCache fileCache:(BOOL)fileCache
{
    MUKObjectCacheLocation locations = MUKObjectCacheLocationNone;
    
    if (memoryCache) {
        locations |= MUKObjectCacheLocationMemory;
    }
    
    if (fileCache) {
        // Don't cache to file images which are already in a file
        if (![self thumbnailIsInFileForMediaAsset:mediaAsset]) {
            locations |= MUKObjectCacheLocationFile;
        }
    }
    
    return locations;
}

+ (MUKURLConnection *)thumbnailConnectionForMediaAsset:(id<MUKMediaAsset>)mediaAsset
{
    NSURL *thumbnailURL = [self thumbnailURLForMediaAsset:mediaAsset];
    if (!thumbnailURL) return nil;
    
    MUKURLConnection *connection = [MUKImageFetcher standardConnectionForImageAtURL:thumbnailURL];
    connection.userInfo = mediaAsset;
    
    return connection;
}

@end
