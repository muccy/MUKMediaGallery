#import <UIKit/UIKit.h>

@class MUKMediaThumbnailsViewController;
@class MUKMediaCarouselViewController;
@class MUKMediaAttributes;
@protocol MUKMediaThumbnailsViewControllerDelegate <NSObject>

@required
- (NSInteger)numberOfItemsInThumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController;
- (void)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController loadImageForItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *image))completionHandler;

@optional
- (void)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController cancelLoadingForImageAtIndex:(NSInteger)idx;
- (MUKMediaAttributes *)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController attributesForItemAtIndex:(NSInteger)idx;
- (MUKMediaCarouselViewController *)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController carouselToPushAfterSelectingItemAtIndex:(NSInteger)idx;

@end



@interface MUKMediaThumbnailsViewController : UICollectionViewController
@property (nonatomic, weak) id<MUKMediaThumbnailsViewControllerDelegate> delegate;

// Remember to cancel your downloads before to call this method, because
// -thumbnailsViewController:cancelLoadingForImageAtIndex: won't be
// invoked
- (void)reloadData;
@end
