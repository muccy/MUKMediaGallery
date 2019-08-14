#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MUKMediaCarouselPlayerControlsView;
@protocol MUKMediaCarouselPlayerControlsViewDelegate <NSObject>
@required
- (void)carouselPlayerControlsViewDidPressPlayPauseButton:(MUKMediaCarouselPlayerControlsView *)controlsView;
- (void)carouselPlayerControlsViewDidStartTouchingSlider:(MUKMediaCarouselPlayerControlsView *)controlsView;
- (void)carouselPlayerControlsViewDidFinishTouchingSlider:(MUKMediaCarouselPlayerControlsView *)controlsView;
- (void)carouselPlayerControlsView:(MUKMediaCarouselPlayerControlsView *)controlsView didChangeSliderValue:(float)newValue;
@end

@interface MUKMediaCarouselPlayerControlsView : UIView
@property (nonatomic, weak) id<MUKMediaCarouselPlayerControlsViewDelegate> delegate;
@property (nonatomic, nullable) AVPlayer *player;
@end

NS_ASSUME_NONNULL_END
