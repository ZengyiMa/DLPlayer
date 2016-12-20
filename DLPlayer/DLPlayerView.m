//
//  DLPlayerView.m
//  DLPlayer
//
//  Created by famulei on 14/12/2016.
//
//

#import "DLPlayerView.h"
#import <AVFoundation/AVFoundation.h>

static NSString *DLPlayerItemStatus = @"player.currentItem.status";
static NSString *DLPlayerItemDuration = @"player.currentItem.duration";

@interface DLPlayerView ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) DLPlayerStatus status;
@property (nonatomic, strong) AVAsset *currentAsset;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, strong) id timeToken;
@property (nonatomic, assign) BOOL autoPlay;
@end

@implementation DLPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initPlayerView];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initPlayerView];
    }
    return self;
}


- (void)initPlayerView
{
    self.backgroundColor = [UIColor blackColor];
    self.player = [AVPlayer new];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.layer addSublayer:self.playerLayer];
    
    // KVO
    [self addObserver:self
           forKeyPath:DLPlayerItemStatus
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:nil];
    
    [self addObserver:self
           forKeyPath:DLPlayerItemDuration
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:nil];
    
    [self addObserver:self
           forKeyPath:@"player.currentItem.playbackBufferEmpty"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:nil];
    
//    [self addObserver:self
//           forKeyPath:@"player.currentItem.playbackLikelyToKeepUp"
//              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
//              context:nil];
    
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAVPlayerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAVPlayerItemPlaybackStalledNotification) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAVPlayerItemNewAccessLogEntryNotification) name:AVPlayerItemNewAccessLogEntryNotification object:nil];

    __weak typeof(self) weakSelf = self;
    self.timeToken =  [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        if (weakSelf.player.rate == 0) {
            // 播放没播放,暂停的状态
            return ;
        }
        CGFloat second = CMTimeGetSeconds(time);
        // 一些视频会先开始走
        if (second > 0.1) {
            [weakSelf setPlayToTime:CMTimeGetSeconds(time)];
            
            switch (weakSelf.status) {
                case DLPlayerStatusStalledStart:
                    weakSelf.status = DLPlayerStatusStalledEnd;
                    break;
                case DLPlayerStatusSeekStart:
                    weakSelf.status = DLPlayerStatusSeekEnd;
                    break;
                case DLPlayerStatusPause:
                case DLPlayerStatusStop:
                break;
                default:
                    weakSelf.status = DLPlayerStatusPlaying;
                    break;
            }
            
            
        }
        
       
    }];
}



- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}


- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay
{
    self.autoPlay = autoPlay;
    if (self.currentAsset) {
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    self.currentAsset = [AVAsset assetWithURL:url];
    __weak typeof(self) weakSelf = self;
    self.status = DLPlayerStatusPrepareStart;
    [self.currentAsset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration", @"playable"] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.status = DLPlayerStatusPrepareEnd;
            if (weakSelf.currentAsset.playable) {
                // 可以播放了
                AVPlayerItem *playItem = [AVPlayerItem playerItemWithAsset:weakSelf.currentAsset];
                [weakSelf.player replaceCurrentItemWithPlayerItem:playItem];
            }
        });
    }];
}

- (void)resume
{
    [self.player play];
    self.status = DLPlayerStatusPlaying;
}

- (void)pause
{
    [self.player pause];
    self.status = DLPlayerStatusPause;
}

- (void)stop
{
    [self stopWithSeekToStart:NO];
}

- (void)stopWithSeekToStart:(BOOL)seekToStart
{
    [self.player pause];
    if (seekToStart) {
        [self.player seekToTime:kCMTimeZero];
    }
    self.status = DLPlayerStatusStop;
}

- (void)replay
{
    [self stopWithSeekToStart:YES];
    [self resume];
}


- (void)beginSeek
{
    self.status = DLPlayerStatusSeekStart;
    [self.player pause];
}

- (void)seekToSecond:(CGFloat)second
{
    if (self.status != DLPlayerStatusSeekStart) {
        return;
    }
    int32_t timeScale = self.player.currentItem.asset.duration.timescale;
    CMTime time = CMTimeMakeWithSeconds(second, timeScale);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)endSeek
{
    [self.player play];
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:DLPlayerItemDuration]) {
        NSValue *durationValue = change[NSKeyValueChangeNewKey];
        if (![durationValue isKindOfClass:[NSValue class]]) {
            return;
        }
        self.duration = CMTimeGetSeconds(durationValue.CMTimeValue);
    }
    else if ([keyPath isEqualToString:DLPlayerItemStatus])
    {
        NSNumber *statusValue = change[NSKeyValueChangeNewKey];
        if (![statusValue isKindOfClass:[NSNumber class]]) {
            return;
        }
        AVPlayerStatus status = statusValue.integerValue;
        if (status == AVPlayerStatusReadyToPlay) {
            self.status = DLPlayerStatusReadyToPlay;
            if (self.autoPlay) {
                [self.player play];
            }
        }
        else
        {
            self.status = DLPlayerStatusFailed;
        }
    }
//    else if ([keyPath isEqualToString:@"player.currentItem.playbackBufferEmpty"])
//    {
//       
//    }
//    else if ([keyPath isEqualToString:@"player.currentItem.playbackLikelyToKeepUp"])
//    {
//    }
}

#pragma mark - Selector
- (void)didReceiveAVPlayerItemDidPlayToEndTimeNotification:(NSNotification *)notification
{
    AVPlayerItem *item = notification.object;
    if (self.currentAsset != item.asset) {
        return;
    }
    
    // 播放完毕
    BOOL seekToStart = NO;
    if ([self.delegate respondsToSelector:@selector(shouldSeekToStartWhenPlayToEndTimeOfPlayerView:)]) {
        seekToStart = [self.delegate respondsToSelector:@selector(shouldSeekToStartWhenPlayToEndTimeOfPlayerView:)];
    }
    [self stopWithSeekToStart:seekToStart];
}

- (void)didReceiveAVPlayerItemPlaybackStalledNotification
{
    self.status = DLPlayerStatusStalledStart;
//    NSLog(@"didReceiveAVPlayerItemPlaybackStalledNotification");
}

//- (void)didReceiveAVPlayerItemNewAccessLogEntryNotification
//{
//    NSLog(@"didReceiveAVPlayerItemNewAccessLogEntryNotification");
//}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:DLPlayerItemStatus];
    [self removeObserver:self forKeyPath:DLPlayerItemDuration];
    [self.player removeTimeObserver:self.timeToken];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - seter
- (void)setStatus:(DLPlayerStatus)status
{
    if (_status == status) {
        return;
    }
    _status = status;
    if ([self.delegate respondsToSelector:@selector(playerView:didChangedStatus:)]) {
        [self.delegate playerView:self didChangedStatus:_status];
    }
}


- (void)setPlayToTime:(CGFloat)second
{
    if ([self.delegate respondsToSelector:@selector(playerView:didPlayToSecond:)]) {
        [self.delegate playerView:self didPlayToSecond:second];
    }
}






@end

