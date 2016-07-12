//
//  ViewController.m
//  UIWebView Cache Demo
//
//  Created by 翟泉 on 2016/7/11.
//  Copyright © 2016年 云之彼端. All rights reserved.
//

#import "ViewController.h"
#import "WebViewURLProtocol.h"

#import "UIImageView+WebCache.h"

@interface ViewController ()
{
    NSTimeInterval start;
}

@end



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [NSURLProtocol registerClass:[WebViewURLProtocol class]];
    
    UIWebView *webView = [[UIWebView alloc] init];
    webView.frame = self.view.bounds;
    [self.view addSubview:webView];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://m.d2cmall.com/page/summersale"]]];
    
    
    
//    UIImageView *imageView = [[UIImageView alloc] init];
//    imageView.frame = self.view.bounds;
//    [self.view addSubview:imageView];
//    
//    [imageView sd_setImageWithURL:[NSURL URLWithString:@"http://static.d2c.cn/img/topic/160705/712/lou/life_mb/34.jpg"] placeholderImage:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//        //
//    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
