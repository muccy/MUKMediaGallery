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
#import <MUKObjectCache/MUKObjectCache.h>
#include <MUKNetworking/MUKNetworking.h>

typedef enum {
    MUKImageFetcherSearchDomainNone         =   0,
    
    MUKImageFetcherSearchDomainMemoryCache  =   1 << 0,
    MUKImageFetcherSearchDomainFileCache    =   1 << 1,
    
    MUKImageFetcherSearchDomainCache        =   (MUKImageFetcherSearchDomainMemoryCache|MUKImageFetcherSearchDomainFileCache),
    
    MUKImageFetcherSearchDomainFile         =   1 << 2,
    
    MUKImageFetcherSearchDomainLocal        = (MUKImageFetcherSearchDomainCache|MUKImageFetcherSearchDomainFile),
    
    MUKImageFetcherSearchDomainRemote       =   1 << 3,
    
    MUKImageFetcherSearchDomainEverywhere   =   (MUKImageFetcherSearchDomainLocal|MUKImageFetcherSearchDomainRemote)
} MUKImageFetcherSearchDomain;


/**
 An object which coordinates a `MUKObjectCache` instance with a 
 `MUKURLConnectionQueue` instance in order to download and cache a group
 of images (e.g. thumbnails in a table view).
 
 ## Constants
 
 `MUKImageFetcherSearchDomain` enumerates where the fetcher could look for
 image:
 
 * `MUKImageFetcherSearchDomainNone` does not search anywhere.
 * `MUKImageFetcherSearchDomainMemoryCache` searches in memory cache.
 * `MUKImageFetcherSearchDomainFileCache` searches in file cache.
 * `MUKImageFetcherSearchDomainCache` searches in cache (both in memory and 
 in files.
 * `MUKImageFetcherSearchDomainFile` permits to load images from files (in
 provided image URLs are file URLs).
 * `MUKImageFetcherSearchDomainLocal` permits local loading.
 * `MUKImageFetcherSearchDomainRemote` permits downloading from network.
 * `MUKImageFetcherSearchDomainEverywhere` searches for image everywhere, both
 locally and on network.
 */
@interface MUKImageFetcher : NSObject
/** @name Properties */
/**
 Connection queue used to download images.
 
 This connection is lazily loaded with 
 [MUKURLConnectionQueue maximumConcurrentConnections] set to `1`.
 
 @warning You can not assign 
 [MUKURLConnectionQueue connectionWillStartHandler] and
 [MUKURLConnectionQueue connectionDidFinishHandler] because they are
 used internally.
 */
@property (nonatomic, strong, readonly) MUKURLConnectionQueue *connectionQueue;
/**
 Object cache used to store images.
 
 This object is lazily loaded but you can assign yours (e.g. reusing caches).
 
 You should assign [MUKObjectCache fileCacheURLHandler] properly if you plan 
 to use `MUKImageFetcherSearchDomainFileCache` search domain. 
 Default implementation uses `UIImagePNGRepresentation` function to convert 
 `UIImage` instances to data.
 */
@property (nonatomic, strong) MUKObjectCache *cache;

/** @name Handlers */
/**
 Handler which returns a connection given image URL.
 
 If you return `nil` or you do not implement this handler, a standard
 connection is enqueued.
 */
@property (nonatomic, copy) MUKURLConnection* (^downloadConnectionHandler)(NSURL *imageURL);
/**
 Handler which gives you a chance to stop a connection before is started.
 
 You could you this handler in order to stop downloads for hidden images.
 
 Otherwhise, every enqueued download will start.
 */
@property (nonatomic, copy) BOOL (^shouldStartConnectionHandler)(MUKURLConnection *connection);

/** @name Methods */
/**
 Load image given its URL.
 
 This method search for image and calls a completion handler on main queue. This handler is
 called synchrounously only if result domain is 
 `MUKImageFetcherSearchDomainMemoryCache`.
 
 @param imageURL Image URL. Could be also a file URL.
 @param searchDomains Where fetcher should look in order to load image. 
 Remember to set `MUKImageFetcherSearchDomainFile` if you feed file URLs and
 you want an image back: otherwise completion handler will be called with 
 `nil` image.
 @param cacheLocations Where fetcher should cache found image. Remember to
 set [MUKObjectCache fileCacheURLHandler] properly for `cache` property.
 If image comes from a file URL, it will not be cached to file.
 @param completionHandler An handler called to signal loading completion.
 First parameter is loaded `image`, second one is where `image` has been found. This handler could be invoked with `nil` if image could not be found.
 */
- (void)loadImageForURL:(NSURL *)imageURL searchDomains:(MUKImageFetcherSearchDomain)searchDomains cacheToLocations:(MUKObjectCacheLocation)cacheLocations completionHandler:(void (^)(UIImage *image, MUKImageFetcherSearchDomain resultDomains))completionHandler;
/**
 Cancels download of an image.
 
 @param imageURL Download URL of image to cancel.
 */
- (void)cancelImageDownloadForURL:(NSURL *)imageURL;
/**
 Cancels download of a group of images.
 
 @param imageURLs Downloads URLs of images to cancel.
 */
- (void)cancelImageDownloadsForURLs:(NSSet *)imageURLs;
@end
