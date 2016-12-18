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
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAVPlayerItemDidPlayToEndTimeNotification) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAVPlayerItemPlaybackStalledNotification) name:AVPlayerItemPlaybackStalledNotification object:nil];
}




- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}


- (void)playWithURL:(NSURL *)url
{
    if (self.currentAsset) {
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    self.currentAsset = [AVAsset assetWithURL:url];
    __weak typeof(self) weakSelf = self;
    [self.currentAsset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration", @"playable"] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.currentAsset.playable) {
                // 可以播放了
                AVPlayerItem *playItem = [AVPlayerItem playerItemWithAsset:weakSelf.currentAsset];
                [weakSelf.player replaceCurrentItemWithPlayerItem:playItem];
                [weakSelf.player play];
            }
        });
    }];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:DLPlayerItemDuration]) {
        
    }
    else if ([keyPath isEqualToString:DLPlayerItemStatus])
    {
        
    }
}

#pragma mark - Selector
- (void)didReceiveAVPlayerItemDidPlayToEndTimeNotification
{
    
}

- (void)didReceiveAVPlayerItemPlaybackStalledNotification
{
    
}




- (void)dealloc
{
    [self removeObserver:self forKeyPath:DLPlayerItemStatus];
    [self removeObserver:self forKeyPath:DLPlayerItemDuration];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}





#pragma mark - seter
- (void)setStatus:(DLPlayerStatus)status
{
    if (_status == status) {
        return;
    }
    _status = status;
    if ([self.delegate respondsToSelector:@selector(playerView:statusDidChanged:)]) {
        [self.delegate playerView:self statusDidChanged:_status];
    }
}






@end

