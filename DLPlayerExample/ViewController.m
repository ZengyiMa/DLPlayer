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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.playerView playWithURL:[NSURL URLWithString:@"http://img1.famulei.com/video/20160814/XMTQ5NzcyODIxNg==.mp4"]];
    self.playerView.delegate = self;
}

- (void)playerView:(DLPlayerView *)playerView didPlayToSecond:(CGFloat)second
{
    
    self.timeLabel.text = [NSString stringWithFormat:@"当前时间：%fs, 总时间：%fs",second, playerView.duration];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
