#import "MUKMediaModelCache.h"

@implementation MUKMediaModelCache

- (instancetype)initWithCountLimit:(NSInteger)countLimit cacheNulls:(BOOL)cacheNulls
{
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _cache.countLimit = countLimit;
        
        _cacheNulls = cacheNulls;
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(didReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    
    return self;
}

- (id)init {
    return [self initWithCountLimit:0 cacheNulls:NO];
}

- (void)dealloc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

#pragma mark - Attributes

- (void)setObject:(id)object atIndex:(NSInteger)index {
    if (object == nil) {
        if (self.cacheNulls) {
            object = [NSNull null];
        }
        else {
            return; // Abort
        }
    }

    [self.cache setObject:object forKey:@(index)];
}

- (id)objectAtIndex:(NSInteger)index isNull:(BOOL *)isNull {
    id object = [self.cache objectForKey:@(index)];
    
    if (self.cacheNulls && object == [NSNull null]) {
        if (isNull != NULL) {
            *isNull = YES;
        }
        
        object = nil;
    }
    else {
        if (isNull != NULL) {
            *isNull = NO;
        }
    }
    
    return object;
}

#pragma mark - Private

- (void)didReceiveMemoryWarningNotification:(NSNotification *)notification
{
    [self.cache removeAllObjects]; // Just to be sure...
}

@end
