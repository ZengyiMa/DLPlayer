//
//  DLPlayerView.m
//  DLPlayer
//
//  Created by famulei on 14/12/2016.
//
//

#import "DLPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "DLPlayerManager.h"
#import "DLPlayerAVAssetResourceLoader.h"

static NSString *DLPlayerItemStatus = @"player.currentItem.status";
static NSString *DLPlayerItemDuration = @"player.currentItem.duration";

@interface DLPlayerView () <DLPlayerAVAssetResourceLoaderDelegate>
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) DLPlayerStatus status;
@property (nonatomic, strong) AVURLAsset *currentAsset;
@property (nonatomic, strong) AVPlayerItem *currentItem;
@property (nonatomic, assign) CGFloat currentSecond;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, strong) id timeToken;
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) CGFloat intialSecond;

@property (nonatomic, strong) DLPlayerAVAssetResourceLoader *resourceLoader;



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


- (void)preparePlayerWithPlayerItem:(AVPlayerItem *)item
{
    self.player = [AVPlayer playerWithPlayerItem:item];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.layer addSublayer:self.playerLayer];
    self.playerLayer.frame = self.bounds;
    
    
    __weak typeof(self) weakSelf = self;
    self.timeToken =  [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        if (weakSelf.player.rate == 0) {
            // 播放没播放,暂停的状态
            return ;
        }
        CGFloat second = CMTimeGetSeconds(time);
        // 防止状态提前改变
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


- (void)releasePlayer
{
    [self.playerLayer removeFromSuperlayer];
    [self.player pause];
    self.player = nil;
    self.playerLayer = nil;
    [self removeObserver:self forKeyPath:DLPlayerItemStatus];
    [self removeObserver:self forKeyPath:DLPlayerItemDuration];
    if (self.timeToken) {
        [self.player removeTimeObserver:self.timeToken];
    }
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


- (void)initPlayerView
{
    // KVO
    [self addObserver:self
           forKeyPath:DLPlayerItemStatus
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:nil];
    
    [self addObserver:self
           forKeyPath:DLPlayerItemDuration
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:nil];

    // Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAVPlayerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAVPlayerItemPlaybackStalledNotification) name:AVPlayerItemPlaybackStalledNotification object:nil];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}


- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay
{
    [self playWithURL:url autoPlay:autoPlay enableCache:self.enableCache intialSecond:0];
}

- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay intialSecond:(CGFloat)second
{
    [self playWithURL:url autoPlay:autoPlay enableCache:self.enableCache intialSecond:second];
}


- (void)playWithURL:(NSURL *)url autoPlay:(BOOL)autoPlay enableCache:(BOOL)enableCache intialSecond:(CGFloat)second
{
    self.status = DLPlayerStatusPrepareStart;
    self.intialSecond = second;
    self.autoPlay = autoPlay;
    if (self.currentAsset) {
        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    
    if (enableCache) {
        [self.resourceLoader prepareWithPlayUrl:url];
        self.currentAsset = [AVURLAsset assetWithURL:self.resourceLoader.mediaUrl];
        [self.resourceLoader start];
    }
    else
    {
        self.currentAsset = [AVURLAsset assetWithURL:url];
    }
    
   self.currentItem = [AVPlayerItem playerItemWithAsset:self.currentAsset];
    __weak typeof(self) weakSelf = self;
    [self.currentAsset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration", @"playable"] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.currentAsset.playable) {
                // 可以播放了
                [weakSelf preparePlayerWithPlayerItem:weakSelf.currentItem];
                self.status = DLPlayerStatusPrepareEnd;
            }
        });
    }];
}

- (void)playWithURLAsset:(AVURLAsset *)asset autoPlay:(BOOL)autoPlay
{
    [self playWithURLAsset:asset autoPlay:autoPlay intialSecond:0];
}

- (void)playWithURLAsset:(AVURLAsset *)asset autoPlay:(BOOL)autoPlay intialSecond:(CGFloat)second
{
    self.status = DLPlayerStatusPrepareStart;
    self.intialSecond = second;
    self.autoPlay = autoPlay;
    if (self.currentAsset) {
        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    self.currentAsset = asset;
    self.currentItem = [AVPlayerItem playerItemWithAsset:self.currentAsset];
    self.status = DLPlayerStatusPrepareEnd;
    
    if (self.intialSecond != 0) {
        // 需要 seek
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.playerLayer.hidden = YES;
        [CATransaction commit];
    }
    [self preparePlayerWithPlayerItem:self.currentItem];
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
    [self releasePlayer];
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

- (void)forceSeekToSecond:(CGFloat)second
{
    int32_t timeScale = self.player.currentItem.asset.duration.timescale;
    CMTime time = CMTimeMakeWithSeconds(second, timeScale);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    __weak typeof(self) weakSelf = self;
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
            if (self.intialSecond != 0) {
                int32_t timeScale = self.player.currentItem.asset.duration.timescale;
                CMTime time = CMTimeMakeWithSeconds(self.intialSecond, timeScale);
                [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                    
                    [CATransaction begin];
                    [CATransaction setDisableActions:YES];
                    self.playerLayer.hidden = NO;
                    [CATransaction commit];
                    [weakSelf.player play];

                }];
                return;
            }

            if (self.autoPlay) {
                [self.player play];
            }

        }
        else if(status == AVPlayerStatusFailed)
        {
            self.status = DLPlayerStatusFailed;
        }
    }
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
}


- (void)dealloc
{
    
}


+ (UIImage *)imageFromAVAsset:(AVAsset *)avasset atTime:(CMTime)time
{
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:avasset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    return image;
}




#pragma mark - delegate
- (void)storageSpaceNotEnoughOfResourceLoader:(DLPlayerAVAssetResourceLoader *)resourceLoader
{
    // 缓存空间不足，用 AVPlayer 自己的策略
    [self playWithURL:self.resourceLoader.originMediaUrl autoPlay:self.autoPlay enableCache:NO intialSecond:0];
}


#pragma mark - seter

- (void)setCurrentAsset:(AVURLAsset *)currentAsset
{
    _currentAsset = currentAsset;
    if (self.enableCache) {
        [_currentAsset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
    }
}



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
    _currentSecond = second;
    if ([self.delegate respondsToSelector:@selector(playerView:didPlayToSecond:)]) {
        [self.delegate playerView:self didPlayToSecond:second];
    }
}


- (DLPlayerAVAssetResourceLoader *)resourceLoader
{
    if (!_resourceLoader) {
        _resourceLoader = [DLPlayerAVAssetResourceLoader new];
        _resourceLoader.delegate = self;
    }
    return _resourceLoader;
}






@end

