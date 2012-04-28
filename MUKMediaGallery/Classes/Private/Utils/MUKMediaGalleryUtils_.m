//
//  MUKMediaGalleryUtils_.m
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 28/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKMediaGalleryUtils_.h"

@implementation MUKMediaGalleryUtils_

+ (NSBundle *)frameworkBundle {
    static NSBundle *frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate,^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"MUKMediaGallery" ofType:@"bundle"];
        frameworkBundle = [[NSBundle alloc] initWithPath:path];
    });
    
    return frameworkBundle;
}

+ (NSString *)localizedStringForKey:(NSString *)key comment:(NSString *)comment
{
    return [[self frameworkBundle] localizedStringForKey:key value:comment table:nil];
}

@end
