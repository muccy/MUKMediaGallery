//
//  ImageFetcherViewController.m
//  MUKMediaGalleryExample
//
//  Created by Marco Muccinelli on 09/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageFetcherViewController.h"
#import <MUKMediaGallery/MUKMediaGallery.h>

@interface ImageFetcherPhoto_ : NSObject 
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *title;

+ (id)photoWithTitle:(NSString *)title URL:(NSString *)URLString;
@end

@implementation ImageFetcherPhoto_
@synthesize title = title_;
@synthesize URL = URL_;

+ (id)photoWithTitle:(NSString *)title URL:(NSString *)URLString {
    ImageFetcherPhoto_ *photo = [[[self class] alloc] init];
    photo.title = title;
    photo.URL = [NSURL URLWithString:URLString];
    return photo;
}

@end

#pragma mark - 
#pragma mark - 

@interface ImageFetcherViewController ()
@property (nonatomic, strong) NSArray *photos_;
@property (nonatomic, strong) MUKImageFetcher *imageFetcher_;
@property (nonatomic, strong) NSMutableDictionary *cellsPerURL_;

- (void)loadPhotosForVisibleCells_;
- (void)tableViewScrollingFinished_;
@end

@implementation ImageFetcherViewController
@synthesize photos_ = photos__;
@synthesize imageFetcher_ = imageFetcher__;
@synthesize cellsPerURL_ = cellsPerURL__;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        photos__ = [[NSArray alloc] initWithObjects:
                    [ImageFetcherPhoto_ photoWithTitle:@"B-1 Bomber" URL:@"http://farm5.staticflickr.com/4013/4255994218_258e428f5e_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Molière" URL:@"http://farm6.staticflickr.com/5169/5282437338_b8a6641e47_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Guitar" URL:@"http://farm6.staticflickr.com/5244/5343236121_63a192ee5e_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Bass Player" URL:@"http://farm6.staticflickr.com/5191/7001948910_992ca47e77_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Rabbit" URL:@"http://farm5.staticflickr.com/4124/5205069586_ef963d539b_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Don't Flash" URL:@"http://farm4.staticflickr.com/3219/3029895753_8e960bafdb_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Girl & Dog" URL:@"http://farm8.staticflickr.com/7253/6903019948_e71f3cd950_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Doll" URL:@"http://farm4.staticflickr.com/3204/2807903715_36b7a67e64_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Car" URL:@"http://farm7.staticflickr.com/6110/6312589363_5ed55bb1c5_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Felouque" URL:@"http://farm6.staticflickr.com/5236/7061366429_91a0b25c1e_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Street" URL:@"http://farm3.staticflickr.com/2402/5748798183_3555f922be_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Waterfall" URL:@"http://farm7.staticflickr.com/6024/6015050385_9341ccdf73_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Chrysanthemums" URL:@"http://farm8.staticflickr.com/7125/7123894151_c6e1282522_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Landscape" URL:@"http://farm6.staticflickr.com/5345/7160165138_727ba5195a_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Faro" URL:@"http://farm8.staticflickr.com/7126/7006571278_d8e65cb330_s.jpg"],
                    [ImageFetcherPhoto_ photoWithTitle:@"Hop" URL:@"http://farm8.staticflickr.com/7237/6969715530_a39f44a816_s.jpg"],
                    nil];
        
        __unsafe_unretained ImageFetcherViewController *weakSelf = self;
        imageFetcher__ = [[MUKImageFetcher alloc] init];
        
        imageFetcher__.shouldStartConnectionHandler = ^(MUKURLConnection *connection)
        {            
            NSInteger photoIndex = [weakSelf.photos_ indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
            {
                ImageFetcherPhoto_ *photo = obj;
                return [photo.URL isEqual:connection.request.URL];
            }];
            
            // Don't start photos I can't find
            if (photoIndex == NSNotFound) return NO;
            
            // Don't start invisible photos
            NSArray *visibleIndexPaths = [weakSelf.tableView indexPathsForVisibleRows];
            __block BOOL photoIsVisible = NO;
            [visibleIndexPaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
            {
                NSIndexPath *indexPath = obj;
                if (indexPath.row == photoIndex) {
                    photoIsVisible = YES;
                    *stop = YES;
                }
            }];
            
            return photoIsVisible;
        };
        
        cellsPerURL__ = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
        
    [self loadPhotosForVisibleCells_];
}

#pragma mark - Private

- (void)loadPhotosForVisibleCells_ {
    [[self.tableView indexPathsForVisibleRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
     {
         NSIndexPath *visibleIndexPath = obj;
         ImageFetcherPhoto_ *photo = [self.photos_ objectAtIndex:visibleIndexPath.row];
         
         [self.imageFetcher_ loadImageForURL:photo.URL searchDomains:MUKImageFetcherSearchDomainEverywhere cacheToLocations:MUKObjectCacheLocationLocal completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomain) 
          {
              // Memory case already treated in cellForRowAtIndexPath
              if (resultDomain != MUKImageFetcherSearchDomainMemoryCache)
              {
                  // Handler is called asyncrounously
                  UITableViewCell *cell = [self.cellsPerURL_ objectForKey:photo.URL];
                  cell.imageView.image = image;
                  [cell setNeedsLayout];
              }
          }];
     }];
}

- (void)tableViewScrollingFinished_ {
    [self loadPhotosForVisibleCells_];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photos_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    ImageFetcherPhoto_ *photo = [self.photos_ objectAtIndex:indexPath.row];
    cell.textLabel.text = photo.title;
    
    // Load image only from memory, so completion handler is called 
    // synchrounoulsy
    [self.imageFetcher_ loadImageForURL:photo.URL searchDomains:MUKImageFetcherSearchDomainMemoryCache cacheToLocations:MUKObjectCacheLocationNone completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomain) 
    {
        cell.imageView.image = image;
    }];
    
    [self.cellsPerURL_ setObject:cell forKey:photo.URL];
    
    return cell;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self tableViewScrollingFinished_];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self tableViewScrollingFinished_];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self tableViewScrollingFinished_];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self tableViewScrollingFinished_];
}

@end
