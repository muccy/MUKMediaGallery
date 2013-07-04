#import "MUKMediaAttributesCache.h"

@implementation MUKMediaAttributesCache

- (MUKMediaAttributes *)mediaAttributesAtIndex:(NSInteger)index cacheIfNeeded:(BOOL)cache loadingHandler:(MUKMediaAttributes *(^)(void))loadingHandler
{
    BOOL nullAttributes = NO;
    MUKMediaAttributes *attributes = [self objectAtIndex:index isNull:&nullAttributes];
    
    // User has chosen for this index
    if (attributes || nullAttributes) {
        return attributes;
    }
    
    // At this point attributes == nil for sure
    // Load from handler!
    if (loadingHandler) {
        attributes = loadingHandler();
    }
    
    // Should cache it?
    if (cache) {
        [self setObject:attributes atIndex:index];
    }
    
    return attributes;
}

@end
