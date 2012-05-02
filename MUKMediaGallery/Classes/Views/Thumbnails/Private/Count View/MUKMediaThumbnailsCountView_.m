//
//  MUKMediaThumbnailsCountView_.m
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 28/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKMediaThumbnailsCountView_.h"

@implementation MUKMediaThumbnailsCountView_
@synthesize label = label_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect rect = CGRectInset(self.bounds, 5, 5);
        self.label = [[UILabel alloc] initWithFrame:rect];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.label];
        
        self.label.backgroundColor = self.backgroundColor;
        self.label.font = [UIFont systemFontOfSize:18.0];
        self.label.textAlignment = UITextAlignmentCenter;
        self.label.textColor = [UIColor darkGrayColor];
    }
    return self;
}

#pragma mark - Overrides

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.label.backgroundColor = backgroundColor;
}

@end
