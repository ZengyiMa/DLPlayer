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
    DLPlayerStatusIdle,
    DLPlayerStatusPlaying,
    DLPlayerStatusPause,
    DLPlayerStatusStop,
    DLPlayerStatusSeekStart,
    DLPlayerStatusSeekEnd
};


@protocol DLPlayerDelegate <NSObject>

@optional
- (void)playerView:(DLPlayerView *)playerView didChangedStatus:(DLPlayerStatus)status;

- (void)playerView:(DLPlayerView *)playerView didPlayToTime:(CMTime)time;

@end



@interface DLPlayerView : UIView

@property (nonatomic, assign, readonly) DLPlayerStatus status;

@property (nonatomic, weak) id<DLPlayerDelegate> delegate;

- (void)playWithURL:(NSURL *)url;


@end
