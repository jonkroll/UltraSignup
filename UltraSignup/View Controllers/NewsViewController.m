//
//  NewsViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 12/30/11.
//  Copyright (c) 2011. All rights reserved.
//

#import "NewsViewController.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"

@implementation NewsViewController

@synthesize newsItem;
@synthesize webView;
@synthesize activeRequest;


- (id)initWithNewsItem:(NewsItem *)item
{
    self = [super init];
    if (self) {
        self.newsItem = item;
    }
    return self;    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    [activeRequest clearDelegatesAndCancel];
    [activeRequest release];
    
    [super dealloc];
}


+ (NSString*)modifyHTML:(NSString*)html
{
    
    NSString *beginPattern = @"<!-- ===================== BEGIN DOCUMENT CONTENT ===================== -->";
    NSString *endPattern   = @"<!-- ===================== END DOCUMENT CONTENT ===================== -->";
    
    NSRange beginPatternRange = [html rangeOfString:beginPattern];
    NSRange endPatternRange = [html rangeOfString:endPattern];
    
    if (beginPatternRange.location == NSNotFound || endPatternRange.location == NSNotFound) {
        return html;
    }
    
    int contentLocation = beginPatternRange.location + beginPatternRange.length;
    int contentLength = endPatternRange.location - contentLocation;
    
    NSRange contentRange = NSMakeRange(contentLocation, contentLength);
    NSString *htmlContent = [html substringWithRange:contentRange];
    

    // remove articletools div
    
    beginPattern = @"<div class=\"articletools\">";
    endPattern   = @"<div style=\"clear:both\">&nbsp;</div></div>";

    beginPatternRange = [htmlContent rangeOfString:beginPattern];
    endPatternRange = [htmlContent rangeOfString:endPattern];
    
    if (beginPatternRange.location == NSNotFound || endPatternRange.location == NSNotFound) {
        return htmlContent;
    }
    
    contentLocation = beginPatternRange.location;
    contentLength = endPatternRange.location + endPatternRange.length -  beginPatternRange.location;
    
    contentRange = NSMakeRange(contentLocation, contentLength);
    
    NSString *articletoolsDivHTML = [htmlContent substringWithRange:contentRange];

    htmlContent = [htmlContent stringByReplacingOccurrencesOfString:articletoolsDivHTML withString:@""];     
    
    // this is a little ghetto - adding this here to make well-formed HTML, since when parsing out the articletools we left an extra close div tag
    htmlContent = [NSString stringWithFormat:@"<div>%@", htmlContent];
 
    // TODO:  insert link to stylesheet for font, etc
    
    
    htmlContent = [NSString stringWithFormat:@"<style>*{font-family:Helvetica} h1{font-size:16pt;color:green}</style>%@", htmlContent];
    
    
    // TODO:  insert link at bottom to article page on ultrasignup (will open in Safari)
    
    
    return htmlContent;    
}



#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:newsItem.title];
    self.navigationItem.titleView = myLabel;
    [myLabel release];
    
    
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];
    webView.delegate = self;
    [[self view] addSubview:webView];
    [webView release];
    
    NSURL *url = [NSURL URLWithString:self.newsItem.url];

    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
    
    //[req setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy];
    [req setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [req setSecondsToCache:60*60*24*30]; // Cache for 30 days
    [req setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy]; // save search between sessions

    [req setDelegate:self];
    [req setTag:0];
    [req startAsynchronous];
    
    self.activeRequest = req;

}


#pragma mark - ASIHTTPrequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSString *html = [[self class] modifyHTML:[request responseString]];
    [webView loadHTMLString:html baseURL:nil];        
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
    
    //NSError *error = [request error];
    
    // TODO: stop spinner and report error
    
}

#pragma mark - UIWebView Delegate

// open clicks on links in safari instead on in the UIWebview
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        // open links from within the article in Safari instead of this webview
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;  
        
    } else {
        
        // add a "loading" indicator to webview when first loads
        hud = [MBProgressHUD showHUDAddedTo:self.webView animated:YES];
        hud.labelText = @"Loading...";  
        hud.removeFromSuperViewOnHide = YES;
        hud.minShowTime = 1.0;
        hud.taskInProgress = YES;        
    }
    return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    hud.taskInProgress = NO;
    [MBProgressHUD hideHUDForView:self.webView animated:NO];
    
}

@end
