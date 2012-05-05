//
//  RootTableViewController.m
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 02/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RootTableViewController.h"
#import "ThumbnailsViewController.h"
#import <MUKToolkit/MUKToolkit.h>

@interface Row_ : NSObject 
@property (nonatomic, strong) NSString *title, *subtitle;
@property (nonatomic, copy) void (^selectionHandler)(void);
@end

@implementation Row_
@synthesize title, subtitle;
@synthesize selectionHandler;
@end

#pragma mark - 
#pragma mark - 

@interface RootTableViewController ()
@property (nonatomic, strong) NSArray *rows_;
- (NSArray *)standardMediaAssets_;
@end

@implementation RootTableViewController
@synthesize rows_ = rows__;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"MUKMediaGallery";
    }
    return self;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Accessors

- (NSArray *)rows_ {
    if (rows__ == nil) {
        NSMutableArray *rows = [[NSMutableArray alloc] init];
        __unsafe_unretained RootTableViewController *weakSelf = self;
        
        Row_ *row = [[Row_ alloc] init];
        row.title = @"Thumbnails View";
        row.subtitle = @"MUKMediaThumbnailsView";
        row.selectionHandler = ^{
            ThumbnailsViewController *viewController = [[ThumbnailsViewController alloc] initWithNibName:nil bundle:nil];
            viewController.mediaAssets = [weakSelf standardMediaAssets_];
            [weakSelf.navigationController pushViewController:viewController animated:YES];
        };
        [rows addObject:row];        
        
        rows__ = rows;
    }
    
    return rows__;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.rows_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    Row_ *row = [self.rows_ objectAtIndex:indexPath.row];
    cell.textLabel.text = row.title;
    cell.detailTextLabel.text = row.subtitle;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Row_ *row = [self.rows_ objectAtIndex:indexPath.row];
    
    if (row.selectionHandler) {
        row.selectionHandler();
    }
}

#pragma mark - Private

- (NSArray *)standardMediaAssets_ {
    NSMutableArray *mediaAssets = [[NSMutableArray alloc] init];
    
    MUKMediaImageAsset *remoteImageAsset = [[MUKMediaImageAsset alloc] init];
    remoteImageAsset.thumbnailURL = [NSURL URLWithString:@"http://farm5.staticflickr.com/4092/4988725775_23993fbb41_t.jpg"];
    remoteImageAsset.mediaURL = [NSURL URLWithString:@"http://farm5.staticflickr.com/4092/4988725775_23993fbb41_z.jpg"];
    [mediaAssets addObject:remoteImageAsset];
    
    MUKMediaVideoAsset *localVideoAsset = [[MUKMediaVideoAsset alloc] init];
    localVideoAsset.thumbnailURL = [MUK URLForImageFileNamed:@"sea-movie-thumbnail.jpg" bundle:nil];
    localVideoAsset.mediaURL = [[NSBundle mainBundle] URLForResource:@"sea" withExtension:@"mp4"];
    [mediaAssets addObject:localVideoAsset];
    
    MUKMediaImageAsset *localImageAsset = [[MUKMediaImageAsset alloc] init];
    localImageAsset.thumbnailURL = [MUK URLForImageFileNamed:@"palms-thumbnail.jpg" bundle:nil];
    localImageAsset.mediaURL = [MUK URLForImageFileNamed:@"palms.jpg" bundle:nil];
    [mediaAssets addObject:localImageAsset];
    
    MUKMediaAudioAsset *localAudioAsset = [[MUKMediaAudioAsset alloc] init];
    localAudioAsset.thumbnailURL = [NSURL URLWithString:@"http://farm6.staticflickr.com/5178/5500963965_2776bf6a98_t.jpg"];
    localAudioAsset.mediaURL = [[NSBundle mainBundle] URLForResource:@"SexForModerns-StopTheClock_64kb" withExtension:@"mp3"];
    [mediaAssets addObject:localAudioAsset];
    
    MUKMediaVideoAsset *youTubeVideoAsset = [[MUKMediaVideoAsset alloc] init];
    youTubeVideoAsset.source = MUKMediaVideoAssetSourceYouTube;
    youTubeVideoAsset.duration = 906; // 15:06
    youTubeVideoAsset.thumbnailURL = [NSURL URLWithString:@"http://i2.ytimg.com/vi/UF8uR6Z6KLc/default.jpg"];
    youTubeVideoAsset.mediaURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=UF8uR6Z6KLc"];
    [mediaAssets addObject:youTubeVideoAsset];
    
    MUKMediaAudioAsset *remoteAudioAsset = [[MUKMediaAudioAsset alloc] init];
    remoteAudioAsset.duration = 332; // 05:32
    remoteAudioAsset.mediaURL = [NSURL URLWithString:@"http://ia600201.us.archive.org/21/items/SexForModerns-PenetratingLoveRay/SexForModerns-PenetratingLoveRay.mp3"];
    [mediaAssets addObject:remoteAudioAsset];
    
    return mediaAssets;
}

@end
