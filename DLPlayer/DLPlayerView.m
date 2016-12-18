//
//  DLPlayerView.m
//  DLPlayer
//
//  Created by famulei on 14/12/2016.
//
//

#import "DLPlayerView.h"
#import <AVFoundation/AVFoundation.h>


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
//        __strong typeof(self) strongSelf = self;
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



- (void)addObserver
{
    
}

- (void)removeObserver
{
    
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
