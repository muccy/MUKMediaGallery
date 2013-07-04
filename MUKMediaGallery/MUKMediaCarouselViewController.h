#import <UIKit/UIKit.h>
#import <MUKMediaGallery/MUKMediaImageKind.h>

@class MUKMediaCarouselViewController;
@class MUKMediaAttributes;
@protocol MUKMediaCarouselViewControllerDelegate <NSObject>

@required
- (NSInteger)numberOfItemsInCarouselViewController:(MUKMediaCarouselViewController *)viewController;
- (void)carouselViewController:(MUKMediaCarouselViewController *)viewController loadImageOfKind:(MUKMediaImageKind)imageKind forItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *image))completionHandler;
- (NSURL *)carouselViewController:(MUKMediaCarouselViewController *)viewController mediaURLForItemAtIndex:(NSInteger)idx;

@optional
- (MUKMediaAttributes *)carouselViewController:(MUKMediaCarouselViewController *)viewController attributesForItemAtIndex:(NSInteger)idx;
- (void)carouselViewController:(MUKMediaCarouselViewController *)viewController cancelLoadingForImageOfKind:(MUKMediaImageKind)imageKind atIndex:(NSInteger)idx;
- (void)carouselViewController:(MUKMediaCarouselViewController *)viewController loadThumbnailImageForItemAtIndex:(NSInteger)idx completionHandler:(void (^)(UIImage *image))completionHandler;

@end




@interface MUKMediaCarouselViewController : UICollectionViewController
@property (nonatomic, weak) id<MUKMediaCarouselViewControllerDelegate> delegate;

- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated;
@end
