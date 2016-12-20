//
//  DLPlayerAVAssetResourceLoader.h
//  DLPlayer
//
//  Created by famulei on 20/12/2016.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kFMLMediaFolder @"com.famulei.media.cache"
@interface DLPlayerAVAssetResourceLoader : NSObject<AVAssetResourceLoaderDelegate, NSURLSessionDataDelegate>

- (NSURL *)videoUrlWithPlayUrl:(NSURL *)url;

@end
