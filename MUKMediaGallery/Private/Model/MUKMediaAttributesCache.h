#import "MUKMediaModelCache.h"
#import "MUKMediaAttributes.h"

@interface MUKMediaAttributesCache : MUKMediaModelCache

// Search for attributes in cache. If attributes can not be found, it invokes
// loadingHandler and caches
- (MUKMediaAttributes *)mediaAttributesAtIndex:(NSInteger)index cacheIfNeeded:(BOOL)cache loadingHandler:(MUKMediaAttributes *(^)(void))loadingHandler;

@end
