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
    NSMutableString *modified = [NSMutableString stringWithString:html];
    
    
    // remove any content in HTML between the open body tag and the first <h1> tag
    NSString *regexPattern = @"<body[^>]*>(.*)<h1>";
    NSRegularExpression *regex = 
    [NSRegularExpression regularExpressionWithPattern:regexPattern 
                                              options:NSRegularExpressionDotMatchesLineSeparators 
                                                error:nil];
    
    NSTextCheckingResult *firstMatch = [regex firstMatchInString:modified
                                                         options:NSRegularExpressionCaseInsensitive
                                                           range:NSMakeRange(0, [modified length])];
    
    if (firstMatch) {
        
        NSString *siteLinkHTML = [modified substringWithRange:[firstMatch rangeAtIndex:1]];
        
        [modified deleteCharactersInRange:[firstMatch rangeAtIndex:1]];
        
        // now insert the text we removed at the end of the article
        NSRegularExpression *regex2 = 
        [NSRegularExpression regularExpressionWithPattern:@"</body>" 
                                                  options:NSRegularExpressionDotMatchesLineSeparators 
                                                    error:nil];
        
        NSTextCheckingResult *closeBodyMatch = [regex2 firstMatchInString:modified
                                                                  options:NSRegularExpressionCaseInsensitive
                                                                    range:NSMakeRange(0, [modified length])];
        
        if (closeBodyMatch) {
            
            [modified insertString:[NSString stringWithFormat:@"%@<br><br>", siteLinkHTML] 
                           atIndex:[closeBodyMatch range].location];
        }
        
    }
    
    return modified;
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
    NSString *response = [request responseString];
    NSString *regexPattern;
    NSString *html;
    
    switch (request.tag) {
            
        case 0:
            // extract print URL from html of the main page using a regular expression
            // example print url format: "http://www.ultrarunning.com/cgi-bin/moxiebin/bm_tools.cgi?print=1603;s=2_1;site=1"
            // note: need to use double backslash for escaping in NSString (i.e. not for escaping in regex)
            
            regexPattern = @"http:[A-Za-z0-9\\/\\.\\?&:\\-\\_\\=;]*print=[A-Za-z0-9\\/\\.\\?&:\\-\\_\\=;]*"; 
            
            NSRegularExpression *regex = 
                    [NSRegularExpression regularExpressionWithPattern:regexPattern 
                                                              options:NSRegularExpressionCaseInsensitive 
                                                                error:nil];
            
            NSTextCheckingResult *firstMatch = [regex firstMatchInString:response
                                                                 options:NSRegularExpressionCaseInsensitive
                                                                   range:NSMakeRange(0, [response length])];
            
            if (firstMatch) {
                
                NSString *printURL = [response substringWithRange:[firstMatch range]];
                NSURL *url = [NSURL URLWithString:printURL];
            
                ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
                [req setDelegate:self];
                [req setTag:1];
                [req startAsynchronous];
                
                self.activeRequest = req;
                
                
            } else {
                
                // could not find print URL
                
                // TODO: handle this case
                
            }
            break;
            
        case 1:
     
            html = [NewsViewController modifyHTML:[request responseString]];
            
            [webView loadHTMLString:html baseURL:nil];
            break;
            
    }
        
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
