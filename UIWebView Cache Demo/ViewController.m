//
//  ViewController.m
//  UIWebView Cache Demo
//
//  Created by 翟泉 on 2016/7/11.
//  Copyright © 2016年 云之彼端. All rights reserved.
//

#import "ViewController.h"
#import "WebViewURLProtocol.h"

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
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
