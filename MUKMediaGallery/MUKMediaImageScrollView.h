#import <UIKit/UIKit.h>

@class MUKMediaImageScrollView;
@protocol MUKMediaImageScrollViewDelegate <NSObject>
@optional
- (void)imageScrollView:(MUKMediaImageScrollView *)imageScrollView didReceiveTaps:(NSInteger)tapCount withGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer;
@end

@interface MUKMediaImageScrollView : UIScrollView
@property (nonatomic, weak) id<MUKMediaImageScrollViewDelegate> imageDelegate;
@property (nonatomic) float maximumZoomFactor;
@property (nonatomic) float doubleTapZoomFactor;

- (void)displayImage:(UIImage *)image;
@end
