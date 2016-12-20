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


NSString *DLPlayerAVAssetResourceLoaderPrefix = @"DLPlayer";

@interface DLPlayerAVAssetResourceLoader()

@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableArray *loadingRequests;

@property (nonatomic, strong) NSMutableData *videoData;

@property (nonatomic, strong) NSURL *originMediaUrl;
@property (nonatomic, strong) NSURL *mediaUrl;

@property (nonatomic, assign) BOOL isStart;

@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, assign) NSUInteger contentLength;

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
    }
    return self;
}

- (void)initialize
{
}


#pragma mark - public

- (void)prepareWithPlayUrl:(NSURL *)url
{
    self.originMediaUrl = url;
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = [NSString stringWithFormat:@"%@-%@", DLPlayerAVAssetResourceLoaderPrefix, components.scheme];
    self.mediaUrl = [components URL];
}

- (void)start
{
    [[self dataTaskWithOffset:0] resume];
}

- (void)stop
{
    
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
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
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
        
        NSUInteger startOffset = loadingRequest.dataRequest.requestedOffset;
        
        if (loadingRequest.dataRequest.currentOffset != 0) {
            startOffset = loadingRequest.dataRequest.currentOffset;
        }
        
        if (startOffset < downloadedBytes) {
           
            if (startOffset + loadingRequest.dataRequest.requestedLength < downloadedBytes) {
                // 这个request 完全加载完成了
               
                [loadingRequest.dataRequest respondWithData: [self.videoData subdataWithRange:NSMakeRange(startOffset, loadingRequest.dataRequest.requestedLength)]];
                [loadingRequest finishLoading];
                [removeRequests addObject:loadingRequest];
            }
            else{
                [loadingRequest.dataRequest respondWithData:[self.videoData subdataWithRange:NSMakeRange(startOffset, downloadedBytes - startOffset)]];
            }
        }
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
        self.contentType = fields[@"Content-Type"];
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
    }
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.videoData appendData:data];
    NSLog(@"down data size = %lu", (unsigned long)self.videoData.length);
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

@end
