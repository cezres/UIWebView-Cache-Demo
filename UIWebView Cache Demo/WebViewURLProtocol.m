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

static NSString *URLProtocolHandledKey = @"WebViewURLHasHandle";


@interface WebViewURLProtocol ()
<NSURLConnectionDelegate>

@property (strong, nonatomic) NSURLConnection *connection;

@property (strong, nonatomic) NSMutableData *mutableData;

@end



@implementation WebViewURLProtocol


+ (BOOL)canInitWithRequest:(NSURLRequest *)request; {
    if ([request.URL.absoluteString rangeOfString:@"png"].length || [request.URL.absoluteString rangeOfString:@"jpg"].length) {
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}


+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading; {
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableReqeust];
    
    NSData *data = [self cacheForRequest:self.request];
    if (data) {
        NSString *MIMEType;
        if ([mutableReqeust.URL.absoluteString rangeOfString:@"jpg"].length) {
            MIMEType = @"image/jpeg";
        }
        else if ([mutableReqeust.URL.absoluteString rangeOfString:@"png"].length) {
            MIMEType = @"image/png";
        }
        printf("Cache\t\t%s\n", [self.request.URL.absoluteString cStringUsingEncoding:NSUTF8StringEncoding]);
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[self.request.URL copy] MIMEType:MIMEType expectedContentLength:data.length textEncodingName:NULL];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    }
    else {
        printf("Network\t\t%s\n", [mutableReqeust.URL.absoluteString cStringUsingEncoding:NSUTF8StringEncoding]);
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
    [self.client URLProtocol:self didLoadData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    [self storeCache:_mutableData atRequest:self.request];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}


#pragma mark - Tool

- (NSData *)cacheForRequest:(NSURLRequest *)request; {
    return [NSData dataWithContentsOfFile:[self cachePathWithRequest:request]];
}

- (NSString *)cachePathWithRequest:(NSURLRequest *)request; {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *urlString = self.request.URL.absoluteString;
    return [NSString stringWithFormat:@"%@/%@", documentsPath, urlString.MD5];
}

- (void)storeCache:(NSData *)cache atRequest:(NSURLRequest *)request; {
    [cache writeToFile:[self cachePathWithRequest:request] atomically:YES];
}


@end
