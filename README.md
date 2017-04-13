# DLPlayer
DLPlayer 是基于 AVPlayer 封装的视频播放器，它是一个 UIView，你可以分方便的进行集成，支持使用 Xib 来进行设置。

# 使用说明

## 基本使用
创建 Player 对象

```
DLPlayerView *view =  [DLPlayerView new];

```
调用播放方法（支持 Url 地址和 AVURLAsset 来直接进行播放）

```
- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay;
- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay intialSecond:(CGFloat)second;
- (void)playWithURLAsset:(AVURLAsset *)asset autoPlay:(BOOL)autoPlay;
- (void)playWithURLAsset:(AVURLAsset *)asset autoPlay:(BOOL)autoPlay intialSecond:(CGFloat)second;
```


控制播放(暂停，恢复，停止，重播)

```
- (void)resume;
- (void)pause;
- (void)stop;
- (void)replay;
```

拖动进度条控制

```
- (void)beginSeek;
- (void)seekToSecond:(CGFloat)second;
- (void)endSeek;
```

从视频中截图

```
+ (UIImage *)imageFromAVAsset:(AVAsset *)avasset atTime:(CMTime)time;
```

## 代理方法
有3个代理方法，分别是

```

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
```

## 播放器状态
DLPlayer 提供精确的播放状态来让你完整的控制播放时候发生了什么。

```
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

```

# 集成方式
1. pod （待添加）
2. 直接将文件拖到项目中即可




