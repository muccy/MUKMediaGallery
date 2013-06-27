#import <UIKit/UIKit.h>

@class MUKMediaCarouselViewController;
@protocol MUKMediaCarouselViewControllerDelegate <NSObject>

@end




@interface MUKMediaCarouselViewController : UICollectionViewController
@property (nonatomic, weak) id<MUKMediaCarouselViewControllerDelegate> delegate;
@end
