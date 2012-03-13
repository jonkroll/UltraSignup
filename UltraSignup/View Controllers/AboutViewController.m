//
//  AboutViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 7/11/11.
//  Copyright 2011. All rights reserved.
//

#import "AboutViewController.h"
#import "SearchViewController.h"
#import "ASIDownloadCache.h"
#import "Settings.h"


@implementation AboutViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // insert logo into nav bar
    UIImageView* logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UltraSignup_Logo.png"]];    
    self.navigationItem.titleView = logo;
    self.navigationItem.title = @"Back";
    [logo release];

    // add version label
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 380, 320, 20)];
    versionLabel.numberOfLines = 1;
    versionLabel.text = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    versionLabel.textAlignment = UITextAlignmentCenter;
    versionLabel.font = [UIFont systemFontOfSize:12];
    versionLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:versionLabel];
    [versionLabel release];

    // disable scrolling
    self.tableView.scrollEnabled = NO;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -

- (void)segmentAction:(UISegmentedControl*)sender 
{
    switch ([sender selectedSegmentIndex])
    {
        case 0: // search
        {
            SearchViewController *svc = [[SearchViewController alloc] init];
            [self.navigationController pushViewController:svc animated:YES];
            [svc release];
            break;
        }
        case 1: // home
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        }
    }
}

- (IBAction)pushDisclaimer:(NSString*)disclaimerHTML withTitle:(NSString*)title
{
    // create a view controller to hold the web view
    UIViewController *vc = [[UIViewController alloc] init];
    
    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:title];
    vc.navigationItem.titleView = myLabel;
    [myLabel release];    
    
    // create a web view
    CGRect webFrame = [[UIScreen mainScreen] applicationFrame];
    webFrame.origin.y -= 20; // shift display up so it covers the default open space from the content view
    webFrame.size.height -= 40; 
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:webFrame];
    [webView loadHTMLString:disclaimerHTML baseURL:nil];
    [webView setBackgroundColor:[UIColor whiteColor]];
    
    [[vc view] addSubview:webView];
    
    [self.navigationController pushViewController:vc animated:YES];
    
    [vc release];
    [webView release];
}


- (IBAction)showEmailModalView
{
    //if([MFMailComposeViewController canSendText]) {
        
        MFMailComposeViewController *mcvc = [[MFMailComposeViewController alloc] init];
        mcvc.mailComposeDelegate = self;
        mcvc.navigationBar.tintColor = kUltraSignupColor;
        mcvc.title = @"Send Email";
        [mcvc setSubject:@"Ultra Signup iPhone App"];
        //[mcvc setMessageBody:@"\n\n\nSent from Ultra Signup iPhone App" isHTML:YES];
        [mcvc setToRecipients:[NSArray arrayWithObject:kUltraSignupEmailAddress]];
        
        [self.navigationController presentModalViewController:mcvc animated:YES];
        [mcvc release];
    /*
     } else {
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"Unable to send mail"
                                   message:@"Mail sending in unavailable." 
                                  delegate:self 
                         cancelButtonTitle:@"Cancel"
                         otherButtonTitles:nil];
        [alert show];        
    }
     */
}


- (IBAction)showClearCacheAlertView
{
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:@"Clear Cached Data"
                               message:@"Are you sure you want to clear all cached data for this app?" 
                              delegate:self 
                     cancelButtonTitle:@"Cancel"
                     otherButtonTitles:@"OK",nil];
    [alert show];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case 0: return 3; break;
        case 1: return 1; break;  // "contact ultrasignup" button
        case 2: return 1; break;  // "clear cached data" buton
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: cell.textLabel.text = @"About Ultra Signup"; break;
            case 1: cell.textLabel.text = @"Terms of Use"; break;
            case 2: cell.textLabel.text = @"Privacy Policy"; break;                
        }
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"Contact Ultra Signup";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    } else if (indexPath.section == 2) {
        cell.textLabel.text = @"Clear Cached Data";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {

        NSString *detailHTML = @"";
        switch (indexPath.row) {
            case 0: detailHTML = kUltraSignupHTMLAbout; break;
            case 1: detailHTML = kUltraSignupHTMLTerms; break;
            case 2: detailHTML = kUltraSignupHTMLPrivacy; break;
        }
        NSString *title = [[[self.tableView cellForRowAtIndexPath:indexPath] textLabel] text];
        [self pushDisclaimer:(NSString*)detailHTML withTitle:(NSString*)title];                
    
    } else if (indexPath.section == 1) {
        
        [self showEmailModalView];
        
    } else if (indexPath.section == 2) {
        
        [self showClearCacheAlertView];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        
    }
}


#pragma mark - MFMailComposeViewController delegate

// Dismisses the email composition interface when users tap Cancel or Send. 
// Proceeds to update the message field with the result of the operation.
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
            UIAlertView *alert = 
                [[UIAlertView alloc] initWithTitle:@"Email" 
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

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        
        // clear cached data
        [[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
        
    }
    
}

@end
