//
//  DLPlayerManager.m
//  DLPlayer
//
//  Created by famulei on 20/12/2016.
//
//

#import "DLPlayerManager.h"
#import "DLPlayerAVAssetResourceLoader.h"


@interface DLPlayerManager ()
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) DLPlayerAVAssetResourceLoader *loader;

@end



@implementation DLPlayerManager

+ (instancetype)manager
{
    static DLPlayerManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [DLPlayerManager new];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.loader = [DLPlayerAVAssetResourceLoader new];
        self.queue = dispatch_queue_create("com.mazengyi.playerloader", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (id<AVAssetResourceLoaderDelegate,NSURLSessionDataDelegate>)assetResourceLoader
{
    return self.loader;
}

- (dispatch_queue_t)queue
{
   return _queue;
}

- (NSURL *)videoUrlWithPlayUrl:(NSURL *)playUrl cache:(BOOL)cache
{
    if (cache) {
        return [self.loader videoUrlWithPlayUrl:playUrl];
    }
    return playUrl;
}


@end
