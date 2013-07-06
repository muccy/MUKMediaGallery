#import <UIKit/UIKit.h>

@class MUKMediaImageScrollView;
/**
 A set of methods used by MUKMediaImageScrollView to communicate with its delegate
 instance.
 */
@protocol MUKMediaImageScrollViewDelegate <NSObject>
@optional
/**
 Notifies taps on image. This method is optional.
 
 @param imageScrollView The image scroll view which sends this info.
 @param tapCount Number of taps (it could be 1 or 2).
 @param gestureRecognizer The tap gesture recognizer which has intercepted the gesture.
 */
- (void)imageScrollView:(MUKMediaImageScrollView *)imageScrollView didReceiveTaps:(NSInteger)tapCount withGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer;
@end



/**
 A scroll view configured to host a zoomable image.
 
 This class sets itself as delegate implementing only
 - (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
 */
@interface MUKMediaImageScrollView : UIScrollView

/**
 The object that acts as the delegate of the receiving image scroll view.
 */
@property (nonatomic, weak) id<MUKMediaImageScrollViewDelegate> imageDelegate;

/**
 Maximum magnifing factor applicable to unzoomed image. Defaults to 3.0f.
 */
@property (nonatomic) float maximumZoomFactor;

/**
 Zoom applied to unzoomed image when a double tap gesture is detected. Defaults to 2.0f.
 */
@property (nonatomic) float doubleTapZoomFactor;

/**
 Shows image unzoomed.
 
 @param image Image to display.
 */
- (void)displayImage:(UIImage *)image;
@end
