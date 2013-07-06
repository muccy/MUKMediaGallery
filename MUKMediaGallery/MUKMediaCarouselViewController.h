#import <UIKit/UIKit.h>
#import <MUKMediaGallery/MUKMediaImageKind.h>

@class MUKMediaCarouselViewController;
@class MUKMediaAttributes;
/**
 A set of methods used by MUKMediaCarouselViewController to present media items
 properly.
 */
@protocol MUKMediaCarouselViewControllerDelegate <NSObject>

@required
/**
 Requests how many items should be presented. This method is required.
 
 @param viewController The carousel view controller which requests this info.
 @return Total number of media items which carousel view controller will present.
 */
- (NSInteger)numberOfItemsInCarouselViewController:(MUKMediaCarouselViewController *)viewController;

/**
 Requests to load an image. This method is required. It is also required to call
 completionHandler when image is loaded.
 This method is called also of audios or videos (only with MUKMediaImageKindThumbnail).
 
 @param viewController The carousel view controller which requests this info.
 @param imageKind Kind of requested image. It could be a thumbnail or a full image.
 @param idx Media item index in carousel.
 @param completionHandler A block (which takes a UIImage parameter) which has to be called
 as image is loaded.
 */
- (void)carouselViewController:(MUKMediaCarouselViewController *)viewController loadImageOfKind:(MUKMediaImageKind)imageKind forItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *image))completionHandler;

/**
 Requests media URL for an audio or video item. This method is required.
 
 @param viewController The carousel view controller which requests this info.
 @param idx Media item index in carousel.
 @return Media item URL. This will be used to load video/audio internally.
 */
- (NSURL *)carouselViewController:(MUKMediaCarouselViewController *)viewController mediaURLForItemAtIndex:(NSInteger)idx;

@optional
/**
 Requests attributes for a media item. This method is optional.
 
 @param viewController The carousel view controller which requests this info.
 @param idx Media item index in carousel.
 @return Attributes for requested media item. If this method is not implemented or
 if it returns nil, it assumes the item is an image with no caption.
 */
- (MUKMediaAttributes *)carouselViewController:(MUKMediaCarouselViewController *)viewController attributesForItemAtIndex:(NSInteger)idx;

/**
 Requests to cancel image loading. This method is optional, but you should implement
 it in order to optimize network usage.
 
 @param viewController The carousel view controller which sends this info.
 @param imageKind Kind of requested image. It could be a thumbnail or a full image.
 @param idx Media item index in carousel.
 */
- (void)carouselViewController:(MUKMediaCarouselViewController *)viewController cancelLoadingForImageOfKind:(MUKMediaImageKind)imageKind atIndex:(NSInteger)idx;

@end



/**
 A view controller which presents a paginated list of media items.
 */
@interface MUKMediaCarouselViewController : UICollectionViewController

/**
 The object that acts as the delegate of the receiving carousel view controller.
 */
@property (nonatomic, weak) id<MUKMediaCarouselViewControllerDelegate> delegate;

/**
 Scrolls the carousel to a media item at given index.
 
 @param index Media item index to reveal.
 @param animated If `YES` transition is animated. Otherwise, scroll is immediate.
 */
- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated;
@end
