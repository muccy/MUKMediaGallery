#import <Foundation/Foundation.h>

@interface MUKMediaModelCache : NSObject
@property (nonatomic, readonly) NSCache *cache;
@property (nonatomic, readonly) BOOL cacheNulls;

- (instancetype)initWithCountLimit:(NSInteger)countLimit cacheNulls:(BOOL)cacheNulls;

- (void)setObject:(id)object atIndex:(NSInteger)index;
- (id)objectAtIndex:(NSInteger)index isNull:(BOOL *)isNull;

@end
