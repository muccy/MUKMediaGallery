//
//  MUKMediaThumbnailView_.h
//  MUKMediaGallery
//
//  Created by Marco Muccinelli on 28/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <MUKScrolling/MUKScrolling.h>

/*
 Load with MUKToolkit
 */
@interface MUKMediaThumbnailView_ : MUKRecyclableView
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIView *bottomView;
@property (nonatomic, strong) IBOutlet UIImageView *mediaKindImageView;
@property (nonatomic, strong) IBOutlet UILabel *durationLabel;

@property (nonatomic) CGSize imageOffset;
@end
