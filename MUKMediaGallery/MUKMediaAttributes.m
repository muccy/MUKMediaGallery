#import "MUKMediaAttributes.h"
#import <MUKToolkit/MUK+String.h>

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

- (void)setCaptionWithTimeInterval:(NSTimeInterval)interval {
    self.caption = [MUK stringRepresentationOfTimeInterval:interval];
}

@end