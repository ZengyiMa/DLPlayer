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
    }
    return self;
}




@end
