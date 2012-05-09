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

#import "MUKImageFetcher.h"
#import <MUKToolkit/MUKToolkit.h>
#import "MUKImageFetcherURLConnectionQueue_.h"

@interface MUKImageFetcher ()
- (id<NSCopying>)cacheKeyForImageURL_:(NSURL *)imageURL;
- (MUKObjectCacheLocation)cacheLocationsForSearchDomains_:(MUKImageFetcherSearchDomain)searchDomains imageURL_:(NSURL *)imageURL;
- (MUKImageFetcherSearchDomain)searchDomainForCacheLocation_:(MUKObjectCacheLocation)cacheLocation;

- (MUKURLConnection *)newConnectionForImageURL_:(NSURL *)imageURL;
- (BOOL)shouldStartConnection_:(MUKURLConnection *)connection;
@end

@implementation MUKImageFetcher
@synthesize connectionQueue = connectionQueue_;
@synthesize cache = cache_;
@synthesize downloadConnectionHandler = downloadConnectionHandler_;
@synthesize shouldStartConnectionHandler = shouldStartConnectionHandler_;

- (void)dealloc {
    [(MUKImageFetcherURLConnectionQueue_ *)connectionQueue_ setBlockHandlers:NO];
    connectionQueue_.connectionWillStartHandler = nil;
}

#pragma mark - Accessors

- (MUKURLConnectionQueue *)connectionQueue {
    if (connectionQueue_ == nil) {
        connectionQueue_ = [[MUKImageFetcherURLConnectionQueue_ alloc] init];
        connectionQueue_.maximumConcurrentConnections = 1;
        
        __unsafe_unretained MUKImageFetcher *weakSelf = self;
        connectionQueue_.connectionWillStartHandler = ^(MUKURLConnection *connection)
        {
            if (![weakSelf shouldStartConnection_:connection]) {
                [connection cancel];
            }
        };
        
        connectionQueue_.connectionDidFinishHandler = ^(MUKURLConnection *connection, BOOL cancelled)
        {
            // Break cycles
            if (cancelled) {
                connection.completionHandler = nil;
            }
        };
        
        // Don't change handlers externally
        [(MUKImageFetcherURLConnectionQueue_ *)connectionQueue_ setBlockHandlers:YES];
    }
    
    return connectionQueue_;
}

- (MUKObjectCache *)cache {
    if (cache_ == nil) {
        cache_ = [[MUKObjectCache alloc] init];
        
        cache_.fileCachedDataTransformer = ^(id key, NSData *data) {
            return [[UIImage alloc] initWithData:data];
        };
        
        cache_.fileCachedObjectTransformer = ^(id key, id object) {
            return UIImagePNGRepresentation(object);
        };
    }
    
    return cache_;
}

#pragma mark - Methods

- (void)loadImageForURL:(NSURL *)imageURL searchDomains:(MUKImageFetcherSearchDomain)searchDomains cacheToLocations:(MUKObjectCacheLocation)cacheLocations completionHandler:(void (^)(UIImage *, MUKImageFetcherSearchDomain))completionHandler
{
    // Don't know how to notify
    if (!completionHandler) {
        return;
    }
    
    // Don't know how to search for image
    if (!imageURL || MUKImageFetcherSearchDomainNone == searchDomains)
    {
        completionHandler(nil, MUKImageFetcherSearchDomainNone);
        return;
    }
    
    // Search in cache
    id<NSCopying> cacheKey = [self cacheKeyForImageURL_:imageURL];
    MUKObjectCacheLocation searchCacheLocations = [self cacheLocationsForSearchDomains_:searchDomains imageURL_:imageURL];
    
    [self.cache loadObjectForKey:cacheKey locations:searchCacheLocations completionHandler:^(id object, MUKObjectCacheLocation location) 
    {
        if ([object isKindOfClass:[UIImage class]]) {
            // Image found
            
            // If image is on disk
            // Cache to memory (if requested)
            if (MUKObjectCacheLocationFile == location) {
                if ([MUK bitmask:cacheLocations containsFlag:MUKObjectCacheLocationMemory])
                {
                    [self.cache saveObject:object forKey:cacheKey locations:MUKObjectCacheLocationMemory completionHandler:nil];
                }
            }
            
            // Notify success
            MUKImageFetcherSearchDomain resultDomain = [self searchDomainForCacheLocation_:location];
            completionHandler(object, resultDomain);
        }
        
        else {
            // Image not found
            
            // Load from disk (if requested)
            if ([imageURL isFileURL]) {
                if ([MUK bitmask:searchDomains containsFlag:MUKImageFetcherSearchDomainFile])
                {
                    dispatch_queue_t queue = dispatch_queue_create("it.melive.mukit.MUKImageFetcher.FileImageLoading", NULL);
                    dispatch_async(queue, ^{
                        UIImage *image = [[UIImage alloc] initWithContentsOfFile:[imageURL path]];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // Cache it to memory (if requested)
                            if ([MUK bitmask:cacheLocations containsFlag:MUKObjectCacheLocationMemory])
                            {
                                [self.cache saveObject:image forKey:cacheKey locations:MUKObjectCacheLocationMemory completionHandler:nil];
                            }
                            
                            // Notify loading completion
                            completionHandler(image, MUKImageFetcherSearchDomainFile);
                        }); // dispatch_async on main queue
                    }); // dispatch_async in image loading queue
                    
                    // Dispose queue
                    dispatch_release(queue);
                }
            } // if image URL is file URL
            
            // Download from remote (if requested)
            else if ([MUK bitmask:searchDomains containsFlag:MUKImageFetcherSearchDomainRemote])
            {
                MUKURLConnection *connection = [self newConnectionForImageURL_:imageURL];
                
                MUKURLConnection *strongConnection = connection;
                connection.completionHandler = ^(BOOL success, NSError *error)
                {
                    if (success) {
                        NSData *data = [strongConnection bufferedData];
                        UIImage *image = [[UIImage alloc] initWithData:data];
                        
                        // Cache image (if requested)
                        [self.cache saveObject:image forKey:cacheKey locations:cacheLocations completionHandler:nil];
                        
                        // Notify completion
                        completionHandler(image, MUKImageFetcherSearchDomainRemote);
                    }
                    
                    // Break cycle
                    strongConnection.completionHandler = nil;
                }; // connection's completionHandler
                
                // Enqueue connection
                [self.connectionQueue addConnection:connection];
            }
            
            else {
                // Image is not found, could not be loaded from file URL
                // and could not be loaded from network
                completionHandler(nil, searchDomains);
            }
        } // if object is UIImage instance
    }]; // loadObjectForKey:...
}

- (void)cancelImageDownloadForURL:(NSURL *)imageURL {
    [[self.connectionQueue connections] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        MUKURLConnection *connection = obj;
        if ([connection.request.URL isEqual:imageURL]) {
            [connection cancel];
            *stop = YES;
        }
    }];
}

- (void)cancelImageDownloadsForURLs:(NSSet *)imageURLs {
    [[self.connectionQueue connections] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        MUKURLConnection *connection = obj;
        if ([imageURLs containsObject:connection.request.URL]) {
            [connection cancel];
        }
    }];
}

#pragma mark - Private

- (id<NSCopying>)cacheKeyForImageURL_:(NSURL *)imageURL {
    return [imageURL absoluteString];
}

- (MUKObjectCacheLocation)cacheLocationsForSearchDomains_:(MUKImageFetcherSearchDomain)searchDomains imageURL_:(NSURL *)imageURL
{
    MUKObjectCacheLocation cacheLocations = MUKObjectCacheLocationNone;
    
    if ([MUK bitmask:searchDomains containsFlag:MUKImageFetcherSearchDomainMemoryCache])
    {
        cacheLocations |= MUKObjectCacheLocationMemory;
    }
    
    if ([MUK bitmask:searchDomains containsFlag:MUKImageFetcherSearchDomainFileCache])
    {
        // Don't cache file URLs to file cache (they are already on disk)
        if ([imageURL isFileURL] == NO) {
            cacheLocations |= MUKObjectCacheLocationFile;
        }
    }
    
    return cacheLocations;
}
    
- (MUKImageFetcherSearchDomain)searchDomainForCacheLocation_:(MUKObjectCacheLocation)cacheLocation
{
    MUKImageFetcherSearchDomain searchDomain;
    
    switch (cacheLocation) {
        case MUKObjectCacheLocationMemory:
            searchDomain = MUKImageFetcherSearchDomainMemoryCache;
            break;
            
        case MUKObjectCacheLocationFile:
            searchDomain = MUKImageFetcherSearchDomainFileCache;
            
        default:
            searchDomain = MUKImageFetcherSearchDomainNone;
            break;
    }
    
    return searchDomain;
}

- (MUKURLConnection *)newConnectionForImageURL_:(NSURL *)imageURL {
    MUKURLConnection *connection = nil;
    
    if (self.downloadConnectionHandler) {
        connection = self.downloadConnectionHandler(imageURL);
    }
    
    if (connection == nil) {
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL];
        connection = [[MUKURLConnection alloc] initWithRequest:request];
        connection.runsInBackground = YES;
    }
    
    return connection;
}

- (BOOL)shouldStartConnection_:(MUKURLConnection *)connection {
    if (self.shouldStartConnectionHandler) {
        return self.shouldStartConnectionHandler(connection);
    }
    
    return YES;
}

@end
