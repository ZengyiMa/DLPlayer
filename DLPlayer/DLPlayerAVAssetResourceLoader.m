//
//  DLPlayerAVAssetResourceLoader.m
//  DLPlayer
//
//  Created by famulei on 20/12/2016.
//
//

#import "DLPlayerAVAssetResourceLoader.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CommonCrypto/CommonDigest.h>
#include <mach/mach.h>

NSString *DLPlayerAVAssetResourceLoaderPrefix = @"DLPlayer";

@interface DLPlayerAVAssetResourceLoader()

@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *currentDataTask;


@property (nonatomic, strong) NSMutableArray *loadingRequests;

@property (nonatomic, strong) NSMutableData *videoData;
@property (nonatomic, strong) NSURL *originMediaUrl;
@property (nonatomic, strong) NSURL *mediaUrl;
@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, assign) NSUInteger contentLength;

@property (nonatomic, assign) NSUInteger threshold;
// reqeust
@property (nonatomic, assign) NSUInteger requestOffset;

// cache
@property (nonatomic, strong) NSFileHandle *fileHandler;
@property (nonatomic, strong) NSString *cacheFileName;

@end

@implementation DLPlayerAVAssetResourceLoader
#pragma mark - initialize

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoData = [NSMutableData data];
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self.loadingRequests = [NSMutableArray array];
        self.threshold = 5 * 1024 * 1024; // 5MB
    }
    return self;
}


#pragma mark - public


- (void)prepareWithPlayUrl:(NSURL *)url
{
    [self prepareWithPlayUrl:url threshold:self.threshold];
}


- (void)prepareWithPlayUrl:(NSURL *)url threshold:(NSUInteger)bytes
{
    [self stop];
    self.cacheFileName = [DLPlayerAVAssetResourceLoader md5StringFromString:url.absoluteString];
    self.originMediaUrl = url;
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = [NSString stringWithFormat:@"%@-%@", DLPlayerAVAssetResourceLoaderPrefix, components.scheme];
    self.mediaUrl = [components URL];
    
}

- (void)start
{
    if (self.isStart) {
        return;
    }
    self.isStart = YES;
    self.currentDataTask = [self dataTaskWithOffset:0];
    [self.currentDataTask resume];
}

- (void)stop
{
    self.isStart = NO;
    if (self.currentDataTask) {
        [self.currentDataTask cancel];
        self.currentDataTask = nil;
    }
}


#pragma mark - private

- (NSURLSessionDataTask *)dataTaskWithOffset:(NSUInteger)offset
{
    if (offset == 0) {
        return [self.session dataTaskWithURL:self.originMediaUrl];
    }
    return nil;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.loadingRequests removeObject:resourceLoader];
}


-(BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    
    self.requestOffset =  loadingRequest.dataRequest.requestedOffset;
    
    
    [self.loadingRequests addObject:loadingRequest];
    [self fillRequest];
    return YES;
}


- (void)fillRequest
{
    NSUInteger downloadedBytes = self.videoData.length;
    NSMutableArray *removeRequests = [NSMutableArray array];
    
    for (AVAssetResourceLoadingRequest *loadingRequest in self.loadingRequests) {
        
        loadingRequest.contentInformationRequest.contentType = self.contentType;
        loadingRequest.contentInformationRequest.contentLength = self.contentLength;
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        

        NSUInteger startOffset = loadingRequest.dataRequest.requestedOffset;
        if (loadingRequest.dataRequest.currentOffset != 0) {
            startOffset = loadingRequest.dataRequest.currentOffset;
        }
        if (downloadedBytes < startOffset){
            continue;
        }
        
        NSUInteger unreadBytes = downloadedBytes - ((NSInteger)startOffset);
        NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)loadingRequest.dataRequest.requestedLength, unreadBytes);
        [loadingRequest.dataRequest respondWithData:[self.videoData subdataWithRange:NSMakeRange((NSUInteger)startOffset, (NSUInteger)numberOfBytesToRespondWith)]];

        long long endOffset = loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength;
        BOOL didRespondFully = (downloadedBytes) >= endOffset;


        if (didRespondFully) {
            [loadingRequest finishLoading];
            [removeRequests addObject:loadingRequest];
        }
//        if (startOffset < downloadedBytes) {
//           
//            if (startOffset + loadingRequest.dataRequest.requestedLength < downloadedBytes) {
//                // 这个request 完全加载完成了
//               
//                [loadingRequest.dataRequest respondWithData: [self.videoData subdataWithRange:NSMakeRange(startOffset, loadingRequest.dataRequest.requestedLength)]];
//                [loadingRequest finishLoading];
//                [removeRequests addObject:loadingRequest];
//            }
//            else{
//                NSLog(@"request length = %ld, request offset = %lld", loadingRequest.dataRequest.requestedLength, loadingRequest.dataRequest.currentOffset);
//                [loadingRequest.dataRequest respondWithData:[self.videoData subdataWithRange:NSMakeRange(loadingRequest.dataRequest.requestedOffset, downloadedBytes - loadingRequest.dataRequest.requestedOffset)]];
//            }
//        }
        

    }
    
    [self.loadingRequests removeObjectsInArray:removeRequests];
}


#pragma mark - NSURLSessionDataTaskDelegate


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)dataTask.response;
    NSDictionary *fields = (NSDictionary *)[httpResponse allHeaderFields] ;
    if (!self.contentType) {
        NSString *mimetype = fields[@"Content-Type"];
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)(mimetype), NULL);
        self.contentType = CFBridgingRelease(contentType);
    }
    
    if (self.contentLength == 0) {
        NSString *contentRange = [fields valueForKey:@"Content-Range"];
        NSArray *arrayRange = [contentRange componentsSeparatedByString:@"/"];
        NSString *contentLength = arrayRange.lastObject;
        if ([contentLength integerValue] == 0) {
            self.contentLength = httpResponse.expectedContentLength;
        } else {
            self.contentLength = [contentLength longLongValue];
        }
        
        if (self.contentLength > [DLPlayerAVAssetResourceLoader diskSpaceFree]) {
            if ([self.delegate respondsToSelector:@selector(storageSpaceNotEnoughOfResourceLoader:)]) {
                [self.delegate storageSpaceNotEnoughOfResourceLoader:self];
                if (completionHandler) {
                    completionHandler(NSURLSessionResponseCancel);
                }
                return;
            }
        }
    }

    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.videoData appendData:data];
//    NSLog(@"download offset = %lu", self.videoData.length);
    [self fillRequest];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self fillRequest];
}

#pragma mark - helper
+ (NSString *)md5StringFromString:(NSString *)string {
    if(string == nil || [string length] == 0)
        return nil;
    const char *value = [string UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    return outputString;
}


+ (int64_t)diskSpaceFree {
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    int64_t space =  [[attrs objectForKey:NSFileSystemFreeSize] longLongValue];
    if (space < 0) space = -1;
    return space;
}

@end
