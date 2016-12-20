//
//  DLPlayerManager.h
//  DLPlayer
//
//  Created by famulei on 20/12/2016.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


// 播放管理类
@interface DLPlayerManager: NSObject

+ (instancetype)manager;

- (id<AVAssetResourceLoaderDelegate, NSURLSessionDataDelegate>)assetResourceLoader;
- (dispatch_queue_t)queue;


- (NSURL *)videoUrlWithPlayUrl:(NSURL *)playUrl cache:(BOOL)cache;


@end
