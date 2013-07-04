//
//  MediaAsset.m
//  MUKMediaGallery Example
//
//  Created by Marco on 26/06/13.
//  Copyright (c) 2013 MeLive. All rights reserved.
//

#import "MediaAsset.h"

@implementation MediaAsset

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
