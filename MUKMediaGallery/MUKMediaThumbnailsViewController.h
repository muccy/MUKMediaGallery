#import <UIKit/UIKit.h>

@class MUKMediaThumbnailsViewController;
@class MUKMediaCarouselViewController;
@class MUKMediaAttributes;
/**
 A set of methods used by MUKMediaThumbnailsViewController to present media items
 properly.
 */
@protocol MUKMediaThumbnailsViewControllerDelegate <NSObject>

@required
/**
 Requests how many items should be presented. This method is required.
 
 @param viewController The thumbnails view controller which requests this info.
 @return Total number of media items which thumbnails view controller will present.
 */
- (NSInteger)numberOfItemsInThumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController;

/**
 Requests to load an image. This method is required. It is also required to call
 completionHandler when image is loaded.
 
 @param viewController The thumbnails view controller which requests this info.
 @param idx Media item index in grid.
 @param completionHandler A block (which takes a UIImage parameter) which has to be called
 as image is loaded.
 */
- (void)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController loadImageForItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *image))completionHandler;

@optional
/**
 Requests to cancel image loading. This method is optional, but you should implement
 it in order to optimize network usage.
 
 @param viewController The thumbnails view controller which sends this info.
 @param idx Media item index in grid.
 */
- (void)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController cancelLoadingForImageAtIndex:(NSInteger)idx;

/**
 Requests attributes for a media item. This method is optional.
 
 @param viewController The thumbnails view controller which requests this info.
 @param idx Media item index in carousel.
 @return Attributes for requested media item. If this method is not implemented or
 if it returns nil, it assumes the item is an image with no caption.
 */
- (MUKMediaAttributes *)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController attributesForItemAtIndex:(NSInteger)idx;

/**
 Requests a carousel to display bigger selected image. This method is optional.
 
 @param viewController The thumbnails view controller which requests this info.
 @param idx Media item index in carousel.
 @return An initialized carousel view controller. If this method is not implemented
 (or it returns nil), no carousel will be pushed.
 -[MUKMediaCarouselViewController scrollToItemAtIndex:animated:] is automatically
 called on returned instance.
 */
- (MUKMediaCarouselViewController *)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController carouselToPushAfterSelectingItemAtIndex:(NSInteger)idx;

@end



/**
 A view controller which presents a grid of media item thumbnails.
 */
@interface MUKMediaThumbnailsViewController : UICollectionViewController

/**
 The object that acts as the delegate of the receiving thumbnails view controller.
 */
@property (nonatomic, weak) id<MUKMediaThumbnailsViewControllerDelegate> delegate;

/**
 Empties caches and reloads underlying collection view, requesting every info
 from scratch.
 Remember to cancel your image loadings before to call this method.
 */
- (void)reloadData;
@end
