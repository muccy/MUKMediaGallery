#import <UIKit/UIKit.h>

@class MUKMediaThumbnailsViewController;
@class MUKMediaAttributes;
@protocol MUKMediaThumbnailsViewControllerDelegate <NSObject>

@required
- (NSInteger)numberOfItemsInThumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController;
- (void)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController loadImageForItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *image))completionHandler;

@optional
- (BOOL)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController cancelLoadingForImageAtIndex:(NSInteger)idx;
- (MUKMediaAttributes *)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController attributesForItemAtIndex:(NSInteger)idx;

@end

@interface MUKMediaThumbnailsViewController : UICollectionViewController
@property (nonatomic, weak) id<MUKMediaThumbnailsViewControllerDelegate> delegate;
@property (nonatomic, readonly) NSCache *imagesCache;
@end
