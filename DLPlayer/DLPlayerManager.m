//
//  DLPlayerManager.m
//  DLPlayer
//
//  Created by famulei on 20/12/2016.
//
//



#import "DLPlayerManager.h"
#import "DLPlayerAVAssetResourceLoader.h"


NSString *DLPlayerManagerPreloadCompleteNotification = @"DLPlayerManagerPreloadCompleteNotification";


@interface DLPlayerManager ()

@property (nonatomic, strong) NSMutableDictionary *assetDictionry;
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
        self.assetDictionry = [NSMutableDictionary dictionary];
    }
    return self;
}


- (AVURLAsset *)getPreloadUrl:(NSURL *)url
{
    if (url.absoluteString.length == 0) {
        return nil;
    }
    return self.assetDictionry[url.absoluteString];
}

- (void)addPreloadUrl:(NSURL *)url
{
    if (url.absoluteString.length == 0) {
        return;
    }
    
    AVURLAsset *assets = [AVURLAsset assetWithURL:url];
    self.assetDictionry[url.absoluteString] = assets;
    __weak typeof(assets) weakAsset = assets;
    [assets loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^{
        AVKeyValueStatus status = [weakAsset statusOfValueForKey:@"playable" error:nil];
        switch (status) {
            case AVKeyValueStatusLoaded:
            {
                [[NSNotificationCenter defaultCenter]postNotificationName:DLPlayerManagerPreloadCompleteNotification object:weakAsset];
                // loaded
            }
                break;
            case AVKeyValueStatusUnknown:
            case AVKeyValueStatusFailed:
            case AVKeyValueStatusCancelled:
                // Loading cancelled
                break;
            case AVKeyValueStatusLoading:
                // loading
                break;
        }

    }];
    
    
    
}




@end
