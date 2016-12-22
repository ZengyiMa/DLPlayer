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


- (void)addPreloadUrl:(NSURL *)url;




@end
