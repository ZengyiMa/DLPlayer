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
    DLPlayerStatusPrepareIdle,      ///<<< 初始状态
    DLPlayerStatusPrepareStart,     ///<<< 准备开始
    DLPlayerStatusPrepareEnd,       ///<<< 准备完毕
    DLPlayerStatusReadyToPlay,      ///<<< 可以播放
    DLPlayerStatusPlaying,          ///<<< 播放中
    DLPlayerStatusPause,            ///<<< 暂停
    DLPlayerStatusStop,             ///<<< 播放停止
    DLPlayerStatusStalledStart,     ///<<< 卡顿开始，loading中，播放队列空了
    DLPlayerStatusStalledEnd,       ///<<< 卡顿结束
    DLPlayerStatusSeekStart,        ///<<< 拖动开始
    DLPlayerStatusSeekEnd,          ///<<< 拖动结束
    DLPlayerStatusFailed,           ///<<< 拖动失败，有错误发生导致播放器无法继续
};


@protocol DLPlayerDelegate <NSObject>

@optional
- (void)playerView:(DLPlayerView *)playerView didChangedStatus:(DLPlayerStatus)status;
- (void)playerView:(DLPlayerView *)playerView didPlayToSecond:(CGFloat)second;
- (BOOL)shouldSeekToStartWhenPlayToEndTimeOfPlayerView:(DLPlayerView *)playerView;
@end

@interface DLPlayerView : UIView
@property (nonatomic, assign) BOOL enableCache;
@property (nonatomic, weak) id<DLPlayerDelegate> delegate;
@property (nonatomic, assign, readonly) DLPlayerStatus status;
@property (nonatomic, assign, readonly) CGFloat duration;
#pragma mark - play
- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay;
- (void)resume;
- (void)pause;
- (void)stop;
- (void)stopWithSeekToStart:(BOOL)seekToStart;
- (void)replay;
#pragma mark - seek
- (void)beginSeek;
- (void)seekToSecond:(CGFloat)second;
- (void)endSeek;

@end
