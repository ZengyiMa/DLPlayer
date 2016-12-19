//
//  DLPlayerView.h
//  DLPlayer
//
//  Created by famulei on 14/12/2016.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class DLPlayerView;

typedef NS_ENUM(NSUInteger, DLPlayerStatus) {
    DLPlayerStatusPrepareIdle,
    DLPlayerStatusPrepareStart,    
    DLPlayerStatusPrepareEnd,
    DLPlayerStatusReadyToPlay,
    DLPlayerStatusPlaying,
    DLPlayerStatusPause,
    DLPlayerStatusStop,
    DLPlayerStatusSeekStart,
    DLPlayerStatusSeekEnd
};


@protocol DLPlayerDelegate <NSObject>

@optional
- (void)playerView:(DLPlayerView *)playerView didChangedStatus:(DLPlayerStatus)status;
- (void)playerView:(DLPlayerView *)playerView didPlayToSecond:(CGFloat)second;
- (BOOL)shouldSeekToStartWhenPlayToEndTimeOfPlayerView:(DLPlayerView *)playerView;
@end



@interface DLPlayerView : UIView

@property (nonatomic, assign, readonly) DLPlayerStatus status;
@property (nonatomic, assign, readonly) CGFloat duration;

@property (nonatomic, weak) id<DLPlayerDelegate> delegate;

- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay;

- (void)resume;
- (void)pause;
- (void)stop;
- (void)stopWithSeekToStart:(BOOL)seekToStart;
- (void)replay;


@end
