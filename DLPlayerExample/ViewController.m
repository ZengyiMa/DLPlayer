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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    
    self.statusDic = @{@(DLPlayerStatusPrepareStart):@"准备开始",
                       @(DLPlayerStatusPrepareEnd):@"准备结束",
                       @(DLPlayerStatusPlaying):@"播放中",
                       @(DLPlayerStatusPause):@"播放暂停",
                       @(DLPlayerStatusStop):@"播放结束",
                       @(DLPlayerStatusSeekStart):@"开始拖动",
                       @(DLPlayerStatusSeekEnd):@"结束拖动",
                       };
    
    [self.playerView playWithURL:[NSURL URLWithString:@"http://img1.famulei.com/video/20160814/XMTQ5NzcyODIxNg==.mp4"]];
    self.playerView.delegate = self;
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

- (void)playerView:(DLPlayerView *)playerView didPlayToSecond:(CGFloat)second
{
    self.timeLabel.text = [NSString stringWithFormat:@"当前时间：%fs, 总时间：%fs",second, playerView.duration];
}

- (void)playerView:(DLPlayerView *)playerView didChangedStatus:(DLPlayerStatus)status
{
    
    NSLog(@"播放器状态:%@", self.statusDic[@(status)]);
    self.statusLabel.text = [NSString stringWithFormat:@"播放器状态：%@", self.statusDic[@(status)]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
