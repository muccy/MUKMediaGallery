//
//  MUKMediaPlayerView.h
//  
//
//  Created by Marco Muccinelli on 14/08/2019.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import "MUKMediaCarouselPlayerControlsView.h"

NS_ASSUME_NONNULL_BEGIN

@class MUKMediaPlayerView;
@protocol MUKMediaPlayerViewDelegate <NSObject>
@required
- (void)playerViewDidChangeRate:(MUKMediaPlayerView *)view;
@end

@interface MUKMediaPlayerView : UIView <MUKMediaCarouselPlayerControlsViewDelegate>
@property (nonatomic, weak) id<MUKMediaPlayerViewDelegate> delegate;
@property (nonatomic, nullable) AVPlayer *player;
@property (nonatomic, readonly, weak) MUKMediaCarouselPlayerControlsView *controlsView;

- (void)setPlayerControlsHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^ _Nullable)(BOOL finished))completionHandler;
@end

NS_ASSUME_NONNULL_END
