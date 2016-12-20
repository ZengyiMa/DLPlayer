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
@property (nonatomic, strong) NSURLSessionConfiguration *config;
@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSString *md5Key;
@property (nonatomic, strong) NSString *tempFilePath;
@property (nonatomic, strong) NSString *cacheFilePath;
@property (nonatomic, strong) NSDictionary *fakeSchemeDictionary;

@property (nonatomic, strong) NSMutableDictionary *requestDictionary;

@property (nonatomic, strong) NSMutableData *videoData;
@property (nonatomic, strong) NSString *videoUrl;

@end

@implementation DLPlayerAVAssetResourceLoader
#pragma mark - initialize

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestDictionary = [NSMutableDictionary dictionary];
        self.config = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.videoData = [NSMutableData data];
//        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        self.session = [NSURLSession sessionWithConfiguration:self.config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (void)initialize
{
}


#pragma mark - public

- (NSURL *)videoUrlWithPlayUrl:(NSURL *)url
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = [NSString stringWithFormat:@"%@-%@", DLPlayerAVAssetResourceLoaderPrefix, components.scheme];
    return [components URL];
}


#pragma mark - private

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"didCancelLoadingRequest");
    //[self.requests removeObject:resourceLoader];
}


-(BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"loadingRequest = %@", loadingRequest.request.allHTTPHeaderFields);
    NSString *requestUrlString = loadingRequest.request.URL.absoluteString;
    if (![requestUrlString hasPrefix:DLPlayerAVAssetResourceLoaderPrefix]) {
        return NO;
    }
    
    requestUrlString = [requestUrlString substringFromIndex:DLPlayerAVAssetResourceLoaderPrefix.length + 1];
    NSMutableDictionary *requests = self.requestDictionary[requestUrlString];
    if (!requests) {
        requests = [NSMutableDictionary dictionary];
        self.requestDictionary[requestUrlString] = requests;
    }
    self.videoUrl = requestUrlString;
   
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrlString]];
    request.allHTTPHeaderFields = loadingRequest.request.allHTTPHeaderFields;
    
    
    
    NSURLSessionDataTask *requestDataTask = [self.session dataTaskWithRequest:request];
//    NSURLSessionDataTask *requestDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
//            
//            NSDictionary *fields = httpResp.allHeaderFields;
//            
//            NSDictionary *dic = self.requestDictionary[request.URL.absoluteString];
//            
//            NSString *contentRange = [fields valueForKey:@"Content-Range"];
//            NSArray *array = [contentRange componentsSeparatedByString:@"/"];
//            NSString *length = array.lastObject;
//            NSUInteger contentLength = 0;
//            if ([length integerValue] == 0) {
//                contentLength = (NSUInteger)httpResp.expectedContentLength;
//            } else {
//                contentLength = [length integerValue];
//            }
//            
//            
//            AVAssetResourceLoadingRequest *playerLoadingRequest = dic[[request valueForHTTPHeaderField:@"DLPlayerTaskID"]];
//            NSString *mimeType = fields[@"Content-Type"];
//            CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
//            playerLoadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
//            playerLoadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
//            playerLoadingRequest.contentInformationRequest.contentLength = contentLength;
//            [playerLoadingRequest.dataRequest respondWithData:data];
//            [playerLoadingRequest finishLoading];
//
//        });
//    }];
    
    [request setValue:@(requestDataTask.taskIdentifier).stringValue forHTTPHeaderField:@"DLPlayerTaskID"];
    requests[[NSString stringWithFormat:@"%lu", (unsigned long)requestDataTask.taskIdentifier]] = loadingRequest;
    [requestDataTask resume];
    return YES;
}

- (void)fillRequest
{
    NSDictionary *videoUrldic = self.requestDictionary[self.videoUrl];
    
    for (AVAssetResourceLoadingRequest *loadRequest in videoUrldic.allValues) {
        
        long long startOffset = loadRequest.dataRequest.requestedOffset;
        if (loadRequest.dataRequest.currentOffset != 0) {
            startOffset = loadRequest.dataRequest.currentOffset;
        }
        
        long long endOffset = startOffset + loadRequest.dataRequest.requestedLength;
        
        [loadRequest.dataRequest respondWithData:[self.videoData subdataWithRange:NSMakeRange(startOffset, loadRequest.dataRequest.requestedLength)]];

//        if (endOffset <= self.videoData.length) {
//            // 满足的request
//            NSLog(@"loadRequest");
//            [loadRequest.dataRequest respondWithData:[self.videoData subdataWithRange:NSMakeRange(startOffset, loadRequest.dataRequest.requestedLength)]];
//            [loadRequest finishLoading];
//        }
        
        
      
        
        
        
        
    }
    
   
}


- (void)processRequests
{
//    NSMutableArray *completedRequests = [NSMutableArray array];
//    for (AVAssetResourceLoadingRequest *loadingRequest in self.requests)
//    {
//        ///填充头部
//        NSString *mimeType = self.mimeType;
//        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
//        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
//        loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
//        loadingRequest.contentInformationRequest.contentLength = self.contentLength;
//        long long startOffset = loadingRequest.dataRequest.requestedOffset;
//        if (loadingRequest.dataRequest.currentOffset != 0) {
//            startOffset = loadingRequest.dataRequest.currentOffset;
//        }
//        
//        if ((self.offset +self.downloadedOffset) < startOffset)
//        {
//            continue;
//        }
//        
//        if (startOffset < self.offset) {
//            continue;
//        }
//        
//        NSData *fileData = [NSData dataWithContentsOfFile:self.tempFilePath options:NSDataReadingMappedIfSafe error:nil];
//        long long unreadBytes = self.downloadedOffset - (startOffset - self.offset);
//        long long numberOfBytesToRespondWith = MIN(loadingRequest.dataRequest.requestedLength, unreadBytes);
//        [loadingRequest.dataRequest respondWithData:[fileData subdataWithRange:NSMakeRange((NSUInteger)(startOffset - self.offset), (NSUInteger)numberOfBytesToRespondWith)]];
//        long long endOffset = loadingRequest.dataRequest.requestedLength;
//        BOOL didRespondFully = (self.offset + self.downloadedOffset) >= endOffset;
//        if (didRespondFully) {
//            [loadingRequest finishLoading];
//            [completedRequests addObject:loadingRequest];
//        }
//    }
//    [self.requests removeObjectsInArray:completedRequests];
}

#pragma mark - NSURLSessionDataTaskDelegate


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSDictionary *videoUrldic = self.requestDictionary[dataTask.currentRequest.URL.absoluteString];
    AVAssetResourceLoadingRequest *playerLoadingRequest = videoUrldic[@(dataTask.taskIdentifier).stringValue];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)dataTask.response;
    NSDictionary *dic = (NSDictionary *)[httpResponse allHeaderFields] ;
    NSString *content = [dic valueForKey:@"Content-Range"];
    NSArray *array = [content componentsSeparatedByString:@"/"];
    NSString *length = array.lastObject;
    if ([length integerValue] == 0) {
        playerLoadingRequest.contentInformationRequest.contentLength = httpResponse.expectedContentLength;
    } else {
        playerLoadingRequest.contentInformationRequest.contentLength = [length integerValue];
    }
    NSString *mimeType = dic[@"Content-Type"];
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    playerLoadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    playerLoadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.videoData appendData:data];
    NSLog(@"video data size = %lu", (unsigned long)self.videoData.length);
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
   
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




#pragma mark - file cache
- (void)prepareCache
{
    
    BOOL isDirectory = NO;
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:kFMLMediaFolder];
    ///判断目录有没有存在
    if (![[NSFileManager defaultManager]fileExistsAtPath:cachePath isDirectory:&isDirectory]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *filePath = self.tempFilePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
}

+ (NSString *)filePathForKey:(NSString *)key pathExtension:(NSString *)pathExtension
{
    NSString *md5Key = [self md5StringFromString:key];
    NSString *fileFolder = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    fileFolder = [fileFolder stringByAppendingPathComponent:kFMLMediaFolder];
    NSString *filePath = [fileFolder stringByAppendingPathComponent:[md5Key stringByAppendingPathExtension:pathExtension]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return filePath;
    }
    return nil;
}

+ (void)clearCache
{
    NSString *fileFolder = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    fileFolder = [fileFolder stringByAppendingPathComponent:kFMLMediaFolder];
    if([[NSFileManager defaultManager]fileExistsAtPath:fileFolder])
    {
        [[NSFileManager defaultManager]removeItemAtPath:fileFolder error:nil];
    }
}
@end
