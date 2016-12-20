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
@interface DLPlayerAVAssetResourceLoader()
@property (nonatomic, strong) NSMutableArray *requests;
@property (nonatomic, assign) NSUInteger downloadedOffset;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, assign) NSUInteger contentLength;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSURLSessionConfiguration *config;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) long long offset;
@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, strong) NSURL *originURL;

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSString *md5Key;
@property (nonatomic, strong) NSString *tempFilePath;
@property (nonatomic, strong) NSString *cacheFilePath;
@property (nonatomic, strong) NSDictionary *fakeSchemeDictionary;
@end

@implementation DLPlayerAVAssetResourceLoader
#pragma mark - initialize

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.requests = [NSMutableArray array];
    self.fakeSchemeDictionary = @{@"http":@"fakeHttp",
                                  @"https" : @"fakeHttps"};
}


#pragma mark - public

- (NSURL *)videoUrlWithPlayUrl:(NSURL *)url
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = self.fakeSchemeDictionary[components.scheme];
    return [components URL];
}







- (void)setOriginURL:(NSURL *)originURL pathExtension:(NSString *)pathExtension;
{
    _originURL = originURL;
    [self restoreState];
    self.md5Key = [DLPlayerAVAssetResourceLoader md5StringFromString:_originURL.absoluteString];
    self.tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.md5Key stringByAppendingPathExtension:pathExtension]];
    self.cacheFilePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:kFMLMediaFolder] stringByAppendingPathComponent:[self.md5Key stringByAppendingPathExtension:pathExtension]];
    [self prepareCache];
}

- (NSURL *)schemeVideoURL:(NSURL *)url
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = self.fakeSchemeDictionary[components.scheme];
    return [components URL];
}

- (void)restoreState
{
    ///重置状态，准备开始新的
    self.isStart = NO;
    [self.dataTask cancel];
    self.dataTask = nil;
    self.downloadedOffset = 0;
    if (self.fileHandle) {
        [self.fileHandle closeFile];
        self.fileHandle = nil;
    }
}

#pragma mark - private

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.requests removeObject:resourceLoader];
}


-(BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if (!self.originURL) {
        return YES;
    }
    
    if (self.isStart && loadingRequest.dataRequest.requestedOffset == 2 && loadingRequest.dataRequest.requestedLength == 2) {
    }
    else
    {
        ///只添加一次
        [self.requests addObject:loadingRequest];
    }
    
    if (self.downloadedOffset > 0) {
        [self processRequests];
    }
    
    if (!self.dataTask) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.originURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
        self.config = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:self.config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self.dataTask = [self.session dataTaskWithRequest:request];
        [self.dataTask resume];
    }
    return YES;
}


- (void)processRequests
{
    NSMutableArray *completedRequests = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.requests)
    {
        ///填充头部
        NSString *mimeType = self.mimeType;
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
        loadingRequest.contentInformationRequest.contentLength = self.contentLength;
        long long startOffset = loadingRequest.dataRequest.requestedOffset;
        if (loadingRequest.dataRequest.currentOffset != 0) {
            startOffset = loadingRequest.dataRequest.currentOffset;
        }
        
        if ((self.offset +self.downloadedOffset) < startOffset)
        {
            continue;
        }
        
        if (startOffset < self.offset) {
            continue;
        }
        
        NSData *fileData = [NSData dataWithContentsOfFile:self.tempFilePath options:NSDataReadingMappedIfSafe error:nil];
        long long unreadBytes = self.downloadedOffset - (startOffset - self.offset);
        long long numberOfBytesToRespondWith = MIN(loadingRequest.dataRequest.requestedLength, unreadBytes);
        [loadingRequest.dataRequest respondWithData:[fileData subdataWithRange:NSMakeRange((NSUInteger)(startOffset - self.offset), (NSUInteger)numberOfBytesToRespondWith)]];
        long long endOffset = loadingRequest.dataRequest.requestedLength;
        BOOL didRespondFully = (self.offset + self.downloadedOffset) >= endOffset;
        if (didRespondFully) {
            [loadingRequest finishLoading];
            [completedRequests addObject:loadingRequest];
        }
    }
    [self.requests removeObjectsInArray:completedRequests];
}

#pragma mark - NSURLSessionDataTaskDelegate
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)dataTask.response;
    NSDictionary *dic = (NSDictionary *)[httpResponse allHeaderFields] ;
    NSString *content = [dic valueForKey:@"Content-Range"];
    NSArray *array = [content componentsSeparatedByString:@"/"];
    NSString *length = array.lastObject;
    if ([length integerValue] == 0) {
        self.contentLength = (NSUInteger)httpResponse.expectedContentLength;
    } else {
        self.contentLength = [length integerValue];
    }
    self.mimeType = httpResponse.MIMEType;
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    self.downloadedOffset += data.length;
    [self.fileHandle seekToEndOfFile];
    [self.fileHandle writeData:data];
    [self processRequests];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self processRequests];
    [self.fileHandle closeFile];
    if (!error) {
        ///出错了, 不错操作
    }
    
    NSError *fileError = nil;
    if ([[NSFileManager defaultManager]moveItemAtPath:self.tempFilePath toPath:self.cacheFilePath error:&fileError]) {
        ///移动完全
        NSLog(@"完成 = file == %@", self.cacheFilePath);
    }
    else
    {
        NSLog(@"失败");
    }
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
