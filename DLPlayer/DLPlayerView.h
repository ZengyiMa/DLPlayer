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
    DLPlayerStatusPrepareStart,     ///<<< 准备开始  播放器在准备中
    DLPlayerStatusPrepareEnd,       ///<<< 准备完毕  播放器在准备完毕了，不一定可以播放
    DLPlayerStatusReadyToPlay,      ///<<< 可以播放  播放器就绪可以立即播放
    DLPlayerStatusPlaying,          ///<<< 播放中    播放在播放中
    DLPlayerStatusPause,            ///<<< 暂停     手动暂停，不是卡顿
    DLPlayerStatusStop,             ///<<< 播放停止  播放器停止了会释放所有的资源
    DLPlayerStatusStalledStart,     ///<<< 卡顿开始，可能网络，或者播放队列空，当前播放器从播放到停止
    DLPlayerStatusStalledEnd,       ///<<< 卡顿结束, 从卡顿中恢复
    DLPlayerStatusSeekStart,        ///<<< 拖动开始
    DLPlayerStatusSeekEnd,          ///<<< 拖动结束
    DLPlayerStatusFailed,           ///<<< 拖动失败，有错误发生导致播放器无法继续
};


@protocol DLPlayerDelegate <NSObject>

@optional

/**
 播放器状态发生了改变，具体状态可以看 DLPlayerStatus

 @param playerView 播放器对象
 @param status     改变的状态
 */
- (void)playerView:(DLPlayerView *)playerView didChangedStatus:(DLPlayerStatus)status;

/**
 播放器播放进度
 
 @param playerView 播放器对象
 @param second     播放器当前的进度
 */
- (void)playerView:(DLPlayerView *)playerView didPlayToSecond:(CGFloat)second;

/**
 当前播放器完全播放结束，询问是否需要 seek 到第一帧， 返回 YES 会回到第一帧

 @param playerView 播放器对象
 @return           YES or NO
 */
- (BOOL)shouldSeekToStartWhenPlayToEndTimeOfPlayerView:(DLPlayerView *)playerView;
@end


@interface DLPlayerView : UIView


/**
 开启缓存，默认为 NO
 */
@property (nonatomic, assign) BOOL enableCache;

/**
 回调委托
 */
@property (nonatomic, weak) id<DLPlayerDelegate> delegate;

/**
 播放器当前的状态
 */
@property (nonatomic, assign, readonly) DLPlayerStatus status;

/**
 但是播放的多媒体的时间长度，需要状态 DLPlayerStatusReadyToPlay 可以获取
 */
@property (nonatomic, assign, readonly) CGFloat duration;

/**
 当前播放Item
 */
@property (nonatomic, strong, readonly) AVPlayerItem *currentItem;

#pragma mark - play
- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay;
- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay intialSecond:(CGFloat)second;
- (void)playWithURLAsset:(AVURLAsset *)asset autoPlay:(BOOL)autoPlay;
- (void)playWithURLAsset:(AVURLAsset *)asset autoPlay:(BOOL)autoPlay intialSecond:(CGFloat)second;
#pragma mark - control
- (void)resume;
- (void)pause;
- (void)stop;
- (void)replay;
#pragma mark - seek
- (void)beginSeek;
- (void)seekToSecond:(CGFloat)second;
- (void)endSeek;
#pragma mark - preload
#pragma mark - tools
+ (UIImage *)imageFromAVAsset:(AVAsset *)avasset atTime:(CMTime)time;

@end
