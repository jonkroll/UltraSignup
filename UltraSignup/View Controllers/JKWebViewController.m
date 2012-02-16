//
//  USWebViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 1/5/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "JKWebViewController.h"
#import "Settings.h"

@implementation JKWebViewController

@synthesize url = _url;
@synthesize webView = _webView;
@synthesize toolbar = _toolbar;
@synthesize activityIndicator = _activityIndicator;

-(id)initWithURL:(NSURL*)url
{
    self = [super init];
    if (self) {
        _url = url;    
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
    [self.webView stopLoading];
    [self.webView setDelegate:nil];
    
    [super dealloc];
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // height = 480
    //   status bar = 20
    //   nav bar = 44
    //   web view = 367
    //   tool bar = 49
    
    UIWebView *wv = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 367)];
    
    self.webView = wv;
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    
    
    
    UIToolbar *browserbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 367, 320, 49)];    
    //browserbar.tintColor = [UIColor blackColor];
    browserbar.tintColor = kUltraSignupColor;
    
    
    UIBarButtonItem *backButton 
    = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AssistPrevious.png"]
                                       style:UIBarButtonItemStylePlain 
                                      target:self
                                      action:@selector(backButtonPressed:)];
    backButton.enabled = NO;
    
    UIBarButtonItem *forwardButton 
    = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AssistNext.png"]
                                       style:UIBarButtonItemStylePlain 
                                      target:self 
                                      action:@selector(forwardButtonPressed:)];
    forwardButton.enabled = NO;
    
    UIBarButtonItem *emptyButton = [[UIBarButtonItem alloc] init];
    
    
    UIBarButtonItem *actionButton 
    = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UIButtonBarAction.png"]
                                       style:UIBarButtonItemStylePlain 
                                      target:self 
                                      action:@selector(actionButtonPressed:)];
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    spacer.enabled = NO;
    
    
    NSArray *buttonItems = [NSArray arrayWithObjects:backButton, spacer, forwardButton, spacer, emptyButton, spacer, emptyButton, spacer, actionButton, nil];
    
    [browserbar setItems:buttonItems animated:YES];
    
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(220, 12, 24, 24)];
    self.activityIndicator = spinner;    
    [browserbar addSubview:spinner];
    [spinner release];
    
    
    [self.view addSubview:browserbar];
    self.toolbar = browserbar;
    
    [forwardButton release];
    [backButton release];
    [actionButton release];
    [emptyButton release];
    [spacer release];
    [browserbar release];
    [wv release];
    
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)updateNavigationButtons 
{
    UIBarButtonItem *backButton = [[self.toolbar items] objectAtIndex:0];
    UIBarButtonItem *forwardButton = [[self.toolbar items] objectAtIndex:2];  // index 1 is a spacer
    
    [backButton setEnabled:(self.webView.canGoBack)];
    [forwardButton setEnabled:(self.webView.canGoForward)];    
}

-(void)backButtonPressed:(id)sender
{
    if (self.webView.canGoBack) {
        [self.webView goBack];
    }
}

-(void)forwardButtonPressed:(id)sender
{
    if (self.webView.canGoForward) {
        [self.webView goForward];
    }
}

-(void)actionButtonPressed:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"%@", self.webView.request.mainDocumentURL]]
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Open in Safari", @"Mail Link to this Page", nil];
    
    [actionSheet showFromBarButtonItem:sender animated:YES];
    [actionSheet release];
    
}




#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
                                                navigationType:(UIWebViewNavigationType)navigationType
{
    [self updateNavigationButtons];

    // do not start activity indicator if user clicks on a link
    // that is anchor link within the page already loaded
    BOOL isHyperlinkWithinPage = [[[request URL] absoluteString] isEqualToString:[NSString stringWithFormat:@"%@#%@", self.webView.request.mainDocumentURL, [[request URL] fragment]]];
    
    if (!isHyperlinkWithinPage) {
                                                          
        [self.activityIndicator startAnimating];
    }
    return true;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{    
    [self updateNavigationButtons];
    if (!self.webView.isLoading) {
        [self.activityIndicator stopAnimating];
    }
}



#pragma mark - UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{    

    MFMailComposeViewController *picker;
    
    switch (buttonIndex) {
        case 0:
            // open in safari
            [[UIApplication sharedApplication] openURL:self.webView.request.mainDocumentURL];            
            break;
            
        case 1:
            // mail link to this page
            picker = [[MFMailComposeViewController alloc] init];
            picker.mailComposeDelegate = self;             
            picker.navigationBar.tintColor = kUltraSignupColor;
            
            [picker setTitle:@"Mail Link to this Page"];
            [picker setMessageBody:[NSString stringWithFormat:@"%@", self.webView.request.mainDocumentURL] isHTML:YES];

            [self presentModalViewController:picker animated:YES];

            
            // TODO: can we set firstResponder on the picker??
            // something like:
            //[[[[picker.view.subviews objectAtIndex:3] subviews] objectAtIndex:2] becomeFirstResponder];
            
            
            
            [picker release];

            break;
    }
    
}

#pragma mark - MFMailComposeViewController methods

// Dismisses the email composition interface when users tap Cancel or Send. 
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{ 
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultFailed:
            break;
            
        default:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email" 
                                                            message:@"Sending Failed - Unknown Error"
                                                           delegate:self 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles: nil];
            [alert show];
            [alert release];
        }
            
            break;
    }
    [self dismissModalViewControllerAnimated:YES];
}



@end
