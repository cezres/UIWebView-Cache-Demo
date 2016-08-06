//
//  WebViewURLProtocol.m
//  UIWebView Cache Demo
//
//  Created by 翟泉 on 2016/7/11.
//  Copyright © 2016年 云之彼端. All rights reserved.
//

#import "WebViewURLProtocol.h"
#import "NSString+MD5.h"
#import <UIKit/UIKit.h>
#import "UIImage+WebP.h"

static NSString *URLProtocolHandledKey = @"WebViewURLHasHandle";
static NSTimeInterval CacheTimeout = 60 * 60 * 24 * 7;

static NSString *WebViewCachesDirectory;


@interface WebViewURLProtocol ()
<NSURLConnectionDelegate>

@property (strong, nonatomic) NSURLConnection *connection;

@property (strong, nonatomic) NSMutableData *mutableData;

@end



@implementation WebViewURLProtocol

+ (void)removeAllCache; {
    if (!WebViewCachesDirectory) {
        NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        WebViewCachesDirectory = [NSString stringWithFormat:@"%@/WebView", cachesDirectory];
    }
    [[NSFileManager defaultManager] removeItemAtPath:WebViewCachesDirectory error:NULL];
}


+ (BOOL)canInitWithRequest:(NSURLRequest *)request; {
    
    printf("%s\n", [request.URL.absoluteString cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if ([request.URL.absoluteString rangeOfString:@".png"].length || [request.URL.absoluteString rangeOfString:@".jpg"].length) {
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request; {
    /**
     *  如果是D2C的图片链接，添加webp参数
     */
    if ([request.URL.absoluteString hasPrefix:@"http://static.d2c.cn"]) {
        NSString *URLString = request.URL.absoluteString;
        if ([URLString rangeOfString:@"?"].length) {
            URLString = [URLString componentsSeparatedByString:@"?"][0];
        }
        
        if ([URLString rangeOfString:@"!"].length) {
            if ([URLString rangeOfString:@"format"].length <= 0) {
                URLString = [URLString stringByAppendingString:@"/format/webp"];
            }
        }
        else {
            URLString = [URLString stringByAppendingString:@"!/format/webp"];
        }
        return [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    }
    else {
        return request;
    }
}

- (void)startLoading; {
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableReqeust];
    
    NSData *data = [self cacheForRequest:self.request];
    if (data) {
//        printf("Cache\t\t%s\n", [self.request.URL.absoluteString cStringUsingEncoding:NSUTF8StringEncoding]);
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[self.request.URL copy] MIMEType:@"image/png" expectedContentLength:data.length textEncodingName:NULL];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    }
    else {
        _mutableData = [NSMutableData data];
        _connection = [NSURLConnection connectionWithRequest:mutableReqeust delegate:self];
    }
}

- (void)stopLoading {
    [_connection cancel];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(nonnull NSURLResponse *)response; {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(nonnull NSData *)data; {
    [_mutableData appendBytes:data.bytes length:data.length];
//    [self.client URLProtocol:self didLoadData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
//    printf("Network\t\t%s\n", [self.request.URL.absoluteString cStringUsingEncoding:NSUTF8StringEncoding]);
    
    NSData *data = _mutableData;
    if ([self.request.URL.absoluteString rangeOfString:@"webp"].length) {
        UIImage *image = [UIImage sd_imageWithWebPData:_mutableData];
        if (image) {
            data = UIImagePNGRepresentation(image);
        }
        else {
            printf("Error\t\t%s\n", [self.request.URL.absoluteString cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
    
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
    [self storeCache:data atRequest:self.request];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}


#pragma mark - Tool

- (NSData *)cacheForRequest:(NSURLRequest *)request; {
    NSString *path = [self cachePathWithRequest:request];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:true];
#pragma clang diagnostic pop
    if (!fileAttributes) {
        return NULL;
    }
    NSDate *fileModificationDate = [fileAttributes valueForKey:NSFileModificationDate];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:fileModificationDate];
    if (timeInterval > CacheTimeout) {
        // 缓存时间超时
        return NULL;
    }
    return [NSData dataWithContentsOfFile:path];
}

- (NSString *)cachePathWithRequest:(NSURLRequest *)request; {
    if (!WebViewCachesDirectory) {
        NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        WebViewCachesDirectory = [NSString stringWithFormat:@"%@/WebView", cachesDirectory];
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:WebViewCachesDirectory isDirectory:&isDirectory];
        if (!isDirectory) {
            [[NSFileManager defaultManager] createDirectoryAtPath:WebViewCachesDirectory withIntermediateDirectories:YES attributes:NULL error:NULL];
        }
    }
    NSString *urlString = self.request.URL.absoluteString;
    return [NSString stringWithFormat:@"%@/%@", WebViewCachesDirectory, urlString.MD5];
}

- (void)storeCache:(NSData *)cache atRequest:(NSURLRequest *)request; {
    [cache writeToFile:[self cachePathWithRequest:request] atomically:YES];
}



@end
