#import <Foundation/Foundation.h>

extern NSUInteger const MUKMediaModelCacheDefaultCostLimit; // 10,000,000

@interface MUKMediaModelCache : NSObject
@property (nonatomic, readonly) NSCache *cache;
@property (nonatomic, readonly) BOOL cacheNulls;

// Cache is created with given count limit, plus a cost limit of MUKMediaModelCacheDefaultCostLimit
- (instancetype)initWithCountLimit:(NSInteger)countLimit cacheNulls:(BOOL)cacheNulls;

// With you set images it automatically sets a cost of width * height
- (void)setObject:(id)object atIndex:(NSInteger)index;
- (id)objectAtIndex:(NSInteger)index isNull:(BOOL *)isNull;

@end
