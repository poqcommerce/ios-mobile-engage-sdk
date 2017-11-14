//
// Copyright (c) 2017 Emarsys. All rights reserved.
//

#import "MEIAMViewController.h"
#import "MEJSBridge.h"

@interface MEIAMViewController () <WKNavigationDelegate>

@property(nonatomic, strong) MECompletionHandler completionHandler;
@property(nonatomic, strong) WKWebView *webView;
@property(nonatomic, weak) MEJSBridge *bridge;

@end

@implementation MEIAMViewController

#pragma mark - ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:UIColor.clearColor];
    [self.bridge setJsResultBlock:^(NSDictionary<NSString *, NSObject *> *result) {
        [self respondToJS:result];
    }];
}

#pragma mark - Public methods

- (instancetype)initWithJSBridge:(MEJSBridge *)bridge {
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}

- (void)loadMessage:(NSString *)message
  completionHandler:(MECompletionHandler)completionHandler {
    _completionHandler = completionHandler;
    if (!self.webView) {
        _webView = [self createWebView];
        [self addFullscreenView:self.webView];
    }
    [self.webView loadHTMLString:message
                         baseURL:nil];
}

#pragma mark - WKNavigationDelegate

- (void)    webView:(WKWebView *)webView
didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    if (self.completionHandler) {
        self.completionHandler();
    }
}

#pragma mark - Private methods

- (WKWebView *)createWebView {
    WKProcessPool *processPool = [WKProcessPool new];
    WKWebViewConfiguration *webViewConfiguration = [WKWebViewConfiguration new];
    [webViewConfiguration setProcessPool:processPool];
    [webViewConfiguration setUserContentController:self.bridge.userContentController];

    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero
                                            configuration:webViewConfiguration];
    [webView setNavigationDelegate:self];
    [webView setOpaque:NO];
    [webView setBackgroundColor:UIColor.clearColor];
    [webView.scrollView setBackgroundColor:UIColor.clearColor];
    [webView.scrollView setScrollEnabled:NO];
    [webView.scrollView setBounces:NO];
    [webView.scrollView setBouncesZoom:NO];
    return webView;
}

- (void)addFullscreenView:(UIView *)view {
    [self.view addSubview:view];
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1
                                                                        constant:0];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.view
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1
                                                                         constant:0];
    [self.view addConstraints:@[widthConstraint, heightConstraint]];
    [self.view layoutIfNeeded];
}

- (void)respondToJS:(NSDictionary<NSString *, NSObject *> *)result {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result
                                                       options:0
                                                         error:&error];
    NSString *js = [NSString stringWithFormat:@"callback(%@);", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    [self.webView evaluateJavaScript:js
                   completionHandler:nil];
}

@end