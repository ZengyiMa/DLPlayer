//
//  DLPlayerManager.h
//  DLPlayer
//
//  Created by famulei on 20/12/2016.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


typedef void(^DLPlayerManagerAssetBlock)(AVURLAsset *asset);

FOUNDATION_EXTERN NSString *DLPlayerManagerPreloadCompleteNotification;

// 播放管理类
@interface DLPlayerManager: NSObject

+ (instancetype)manager;


- (void)addPreloadAsset:(AVURLAsset *)asset;
- (void)getPreloadAsset:(NSString *)url withBlock:(DLPlayerManagerAssetBlock)block;
- (void)removePreloadUrl:(NSString *)url;

@end
