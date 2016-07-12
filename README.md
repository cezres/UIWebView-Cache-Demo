# UIWebView-Cache-Demo
UIWebView 缓存图片到本地

我们这边下载网络图片用的是SDWebImage，SDWebImage下载图片用的是NSURLSession。
所以WebViewURLProtocol不会影响到它。
如果影响到了其它地方，可以尝试请求头加参数然后过滤掉。
