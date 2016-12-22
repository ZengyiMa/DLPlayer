//
//  ViewController.m
//  DLPlayerExample
//
//  Created by famulei on 14/12/2016.
//
//

#import "ViewController.h"
#import "DLPlayerView.h"

@interface ViewController ()<DLPlayerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet DLPlayerView *playerView;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (nonatomic, strong) NSDictionary *statusDic;
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet DLPlayerView *player2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    self.player2.hidden = YES;
    self.slider.value = 0;
    [self.slider addTarget:self action:@selector(slideValueChange) forControlEvents:UIControlEventValueChanged];
    [self.slider addTarget:self action:@selector(beginSeek) forControlEvents:UIControlEventTouchDown];
    [self.slider addTarget:self action:@selector(endSeek) forControlEvents:UIControlEventTouchCancel];
    [self.slider addTarget:self action:@selector(endSeek) forControlEvents:UIControlEventTouchUpInside];
    [self.slider addTarget:self action:@selector(endSeek) forControlEvents:UIControlEventTouchUpOutside];

//    self.playerView.enableCache = YES;
    self.playerView.delegate = self;
    self.statusDic = @{@(DLPlayerStatusPrepareStart):@"准备开始",
                       @(DLPlayerStatusPrepareEnd):@"准备结束",
                       @(DLPlayerStatusReadyToPlay):@"准备播放",
                       @(DLPlayerStatusPlaying):@"播放中",
                       @(DLPlayerStatusPause):@"播放暂停",
                       @(DLPlayerStatusStop):@"播放结束",
                       @(DLPlayerStatusSeekStart):@"开始拖动",
                       @(DLPlayerStatusSeekEnd):@"结束拖动",
                       @(DLPlayerStatusStalledStart):@"卡顿开始",
                       @(DLPlayerStatusStalledEnd):@"卡顿结束",
                       @(DLPlayerStatusPrepareIdle):@"默认状态",
                       @(DLPlayerStatusFailed):@"错误",
                       };
    [self.playerView playWithURL:[NSURL URLWithString:@"http://img1.famulei.com/video/20160814/XMTQ5NzcyODIxNg==.mp4"] autoPlay:YES];
//    [self.playerView playWithURL:[NSURL URLWithString:@"http://krtv.qiniudn.com/150522nextapp"] autoPlay:YES intialSecond:10];
}

- (IBAction)statr:(id)sender {
    [self.playerView resume];
}
- (IBAction)pause:(id)sender {
    [self.playerView pause];
}
- (IBAction)stop:(id)sender {
    [self.playerView stop];
}
- (IBAction)replay:(id)sender {
    [self.playerView replay];
}

- (void)beginSeek
{
    [self.playerView beginSeek];
}

- (void)endSeek
{
    [self.playerView endSeek];
}

- (void)slideValueChange
{
    [self.playerView seekToSecond:self.slider.value];
}
- (IBAction)player2Show:(id)sender {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.playerView stop];
        self.player2.hidden = NO;
    });
    
    [self.player2 playWithURLAsset:self.playerView.currentItem.asset autoPlay:YES intialSecond:CMTimeGetSeconds(self.playerView.currentItem.currentTime)];
}

- (void)playerView:(DLPlayerView *)playerView didPlayToSecond:(CGFloat)second
{
    self.slider.value = second;
    self.timeLabel.text = [NSString stringWithFormat:@"当前时间：%fs, 总时间：%fs",second, playerView.duration];
}

- (void)playerView:(DLPlayerView *)playerView didChangedStatus:(DLPlayerStatus)status
{
    if (self.player2 == playerView) {
        return;
    }
    
    
    if (status == DLPlayerStatusReadyToPlay) {
        self.slider.maximumValue = self.playerView.duration;
    }
    NSLog(@"播放器状态:%@", self.statusDic[@(status)]);
    self.statusLabel.text = [NSString stringWithFormat:@"播放器状态：%@", self.statusDic[@(status)]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
