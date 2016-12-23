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


@interface  DLPlayerManagerPreloadAsset: NSObject

@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) NSMutableArray *blocks;


@end

@implementation DLPlayerManagerPreloadAsset

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.blocks = [NSMutableArray array];
    }
    return self;
}

@end





@interface DLPlayerManager ()

@property (nonatomic, strong) NSMutableDictionary *assetDictionry;

@property (nonatomic, strong) NSMutableDictionary *blocksDictionary;
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


- (void)getPreloadAsset:(NSString *)url withBlock:(DLPlayerManagerAssetBlock)block;
{
    if (self.assetDictionry[url]) {
        // 存在
        DLPlayerManagerPreloadAsset *asset =  self.assetDictionry[url];
        AVKeyValueStatus status = [asset.asset statusOfValueForKey:@"playable" error:nil];
        if (status == AVKeyValueStatusLoaded) {
            [asset.blocks removeAllObjects];
            if (block) {
                block(asset.asset);
            }
        }
        else
        {
            [asset.blocks addObject:block];
        }
    }
    else
    {
        // 不存在
        if (block) {
            block(nil);
        }
    }
}


- (void)addPreloadAsset:(AVURLAsset *)urlAssets;
{
    if (urlAssets.URL.absoluteString.length == 0) {
        return;
    }
    
    if (self.assetDictionry[urlAssets.URL.absoluteString]) {
        return;
    }
    
    DLPlayerManagerPreloadAsset *asset = [DLPlayerManagerPreloadAsset new];
    asset.asset = urlAssets;
    self.assetDictionry[urlAssets.URL.absoluteString] = asset;
    __weak typeof(asset.asset) weakAsset = asset.asset;
    __weak typeof(asset) weakPreloadAssset = asset;
    [asset.asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^{
        AVKeyValueStatus status = [weakAsset statusOfValueForKey:@"playable" error:nil];
        switch (status) {
            case AVKeyValueStatusLoaded:
            {
                for (DLPlayerManagerAssetBlock block in weakPreloadAssset.blocks) {
                    block(weakAsset);
                }
            }
                break;
           default:
            {
                [self.assetDictionry removeObjectForKey:weakAsset.URL.absoluteString];
            }
                break;
        }
    }];
}


- (void)removePreloadUrl:(NSString *)url
{
    [self.assetDictionry removeObjectForKey:url];
}




@end
