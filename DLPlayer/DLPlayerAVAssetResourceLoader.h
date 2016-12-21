//
//  DLPlayerAVAssetResourceLoader.h
//  DLPlayer
//
//  Created by famulei on 20/12/2016.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class DLPlayerAVAssetResourceLoader;

@protocol DLPlayerAVAssetResourceLoaderDelegate <NSObject>

@optional
- (void)storageSpaceNotEnoughOfResourceLoader:(DLPlayerAVAssetResourceLoader *)resourceLoader;


@end





@interface DLPlayerAVAssetResourceLoader : NSObject<AVAssetResourceLoaderDelegate, NSURLSessionDataDelegate>
@property (nonatomic, strong, readonly) NSURL *mediaUrl;
@property (nonatomic, strong, readonly) NSURL *originMediaUrl;


@property (nonatomic, weak) id<DLPlayerAVAssetResourceLoaderDelegate> delegate;

- (void)prepareWithPlayUrl:(NSURL *)url;
- (void)start;
- (void)stop;

@end
