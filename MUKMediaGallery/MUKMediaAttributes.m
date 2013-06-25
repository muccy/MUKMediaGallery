#import "MUKMediaAttributes.h"

@implementation MUKMediaAttributes

- (id)init {
    return [self initWithKind:MUKMediaKindImage];
}

- (instancetype)initWithKind:(MUKMediaKind)kind {
    self = [super init];
    if (self) {
        _kind = kind;
    }
    
    return self;
}

@end