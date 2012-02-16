//
//  NewsViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 12/30/11.
//  Copyright (c) 2011. All rights reserved.
//

#import "NewsItem.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"

@interface NewsViewController : UIViewController <UIWebViewDelegate, ASIHTTPRequestDelegate> {

    NewsItem *newsItem;
    UIWebView *webView;
    ASIHTTPRequest *activeRequest;  // save reference to request so we can cancel if user leaves view before it completes
    MBProgressHUD *hud;

}

@property (nonatomic, retain) NewsItem *newsItem;
@property (nonatomic, copy) UIWebView *webView;
@property (nonatomic, retain) ASIHTTPRequest *activeRequest;

- (id)initWithNewsItem:(NewsItem *)item;

+ (NSString*)modifyHTML:(NSString*)html;

@end
