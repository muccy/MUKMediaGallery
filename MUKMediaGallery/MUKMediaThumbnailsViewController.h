#import <UIKit/UIKit.h>

@class MUKMediaThumbnailsViewController;
@protocol MUKMediaThumbnailsViewControllerDelegate <NSObject>

@required
- (NSInteger)numberOfItemsInThumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController;
- (void)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController loadImageForItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *image))completionHandler;

@optional
- (BOOL)thumbnailsViewController:(MUKMediaThumbnailsViewController *)viewController cancelLoadingForImageAtIndex:(NSInteger)idx;

@end

@interface MUKMediaThumbnailsViewController : UICollectionViewController
@property (nonatomic, weak) id<MUKMediaThumbnailsViewControllerDelegate> delegate;
@end
