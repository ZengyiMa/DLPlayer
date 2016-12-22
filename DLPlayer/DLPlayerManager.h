//
//  DLPlayerManager.h
//  DLPlayer
//
//  Created by famulei on 20/12/2016.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


FOUNDATION_EXTERN NSString *DLPlayerManagerPreloadCompleteNotification;






// 播放管理类
@interface DLPlayerManager: NSObject

+ (instancetype)manager;


- (void)addPreloadUrl:(NSURL *)url;


- (AVURLAsset *)getPreloadUrl:(NSURL *)url;


@end
