//
//  USWebViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 1/5/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JKWebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {

    NSURL *_url;
	UIWebView *_webView;
    UIToolbar *_toolbar;
	UIActivityIndicatorView *_activityIndicator;    

}

@property(nonatomic,retain) NSURL *url;
@property(nonatomic,retain) UIWebView *webView;
@property(nonatomic,retain) UIToolbar *toolbar;
@property(nonatomic,retain) UIActivityIndicatorView *activityIndicator;


-(id)initWithURL:(NSURL*)url;

-(void)actionButtonPressed:(id)sender;

@end