//
//  SearchViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 1/17/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "SearchViewController.h"
#import "EventViewController.h"
#import "PersonViewController.h"
#import "ASIHTTPRequest.h"
#import "SBJson.h"
#import "NSDate+UltraSignup.h"
#import "Settings.h"


@implementation SearchViewController

@synthesize tempSearchData = _tempSearchData;
@synthesize searchData = _searchData;
@synthesize activePersonRequest;
@synthesize activeEventRequest;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        displayRequestTag = 0;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (UINavigationController *)navigationController {
    
    // trick the UISearchController into thinking there isn't a UINavigationController
    // so that it won't be able to hide the nav bar when the search bar becomes active
    // if you need to access the vaigation controller in this class, use [super navigationController] instead
    
    // found this idea here: http://stackoverflow.com/a/5860412/663476
    
    return nil;
}

- (void) prepareToUpdateTable
{
    // sort the search results
    [self.tempSearchData sortUsingComparator:^(id obj1, id obj2) {
        
        NSString *str1;
        NSString *str2;
        
        if ([obj1 objectForKey:@"name"]) {
            str1 = [obj1 objectForKey:@"name"];
        } else {
            str1 = [NSString stringWithFormat:@"%@ %@", [obj1 objectForKey:@"first_name"], [obj1 objectForKey:@"last_name"]];
        }
        if ([obj2 objectForKey:@"name"]) {
            str2 = [obj2 objectForKey:@"name"];
        } else {
            str2 = [NSString stringWithFormat:@"%@ %@", [obj2 objectForKey:@"first_name"], [obj1 objectForKey:@"last_name"]];
        }
        
        return [str1 compare:str2];
    }];
    
    [self.searchData removeAllObjects];
    [self.searchData addObjectsFromArray:self.tempSearchData];
    [self.tempSearchData removeAllObjects];
    
    [self.searchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) 
                                                                          withObject:nil 
                                                                       waitUntilDone:NO];
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.searchData  = [NSMutableArray arrayWithObjects: nil]; 

    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:@"Search"];
    self.navigationItem.titleView = myLabel;
    [myLabel release];
    
    self.searchDisplayController.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchDisplayController.searchBar.placeholder = @"Search for Person or Event";
    self.searchDisplayController.searchBar.tintColor = kUltraSignupColor;
    self.searchDisplayController.searchBar.showsScopeBar = NO; 
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidAppear:(BOOL)animated
{
    // check for selected row in table view
    // (a row will be selected if the user clicked back to return to the search view)
    UITableViewCell *cell = (UITableViewCell *)[self.searchDisplayController.searchResultsTableView 
                                                cellForRowAtIndexPath:self.searchDisplayController.searchResultsTableView.indexPathForSelectedRow];
    [cell setSelected:NO];
    
    if (!cell) {
        // no previously selected table cell, so we must be here for first time
        // give focus to search bar, which will also activate keyboard  
        [self.searchDisplayController.searchBar becomeFirstResponder];        
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return  1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.searchData count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSString *cellIdentifier = @"SearchCell";
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:cellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
        
    NSDictionary* searchResult = (NSDictionary*)[_searchData objectAtIndex:indexPath.row];         
    
    // detect if the search result is an event or a person by looking for a "name" property (which would indicate an event
    
    if ([searchResult objectForKey:@"name"]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [searchResult objectForKey:@"name"]];
    } 
    else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", 
                               [searchResult objectForKey:@"first_name"], 
                               [searchResult objectForKey:@"last_name"]];            
    }
    return cell;
}



#pragma mark - Table view delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // hide the keyboard
    [self.searchDisplayController.searchBar resignFirstResponder];

    NSDictionary* dictObj = (NSDictionary*)[_searchData objectAtIndex:indexPath.row];
    
    if ([dictObj objectForKey:@"name"]) {
        
        EventViewController *eventViewController = [[EventViewController alloc] 
                                                    initWithNibName:@"PersonViewController" 
                                                    withEvent:dictObj
                                                    bundle:nil];
        [super.navigationController pushViewController:eventViewController animated:YES];
        [eventViewController release];
        
    } else {
        
        PersonViewController *personViewController = [[PersonViewController alloc] 
                                                      initWithNibName:@"PersonViewController"
                                                      withParticipant:dictObj 
                                                      bundle:nil];
        
        [super.navigationController pushViewController:personViewController animated:YES];
        [personViewController release];            
        
    }
    
    // hide the search controller
    //[self.searchController setActive:NO animated:YES];

}



#pragma mark - Search bar delegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{      
    // clear any results from last search
    if (searchBar.text.length == 0) {
        [self.searchData removeAllObjects];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    
    //searchBar.showsScopeBar = YES;  
    //[searchBar sizeToFit];  
    
    // needed to do this to make the Scope Bar appear under the search bar
    // when the search text box gets focus
    //[[searchBar superview] bringSubviewToFront:searchBar];
    
    [searchBar setShowsCancelButton:NO animated:NO];  
    
    return YES;  
}  


- (void)startSearch:(UISearchBar *)searchBar
{
    // cancel any existing requests
    [self.activePersonRequest clearDelegatesAndCancel];
    [self.activeEventRequest clearDelegatesAndCancel];
    
    // trim whitespace from text that was entered
    NSString* searchString = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // need to url encode the search string in case there is a space character
    searchString = [searchString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSString* urlString;
    NSURL *url;
        
    urlString = [NSString stringWithFormat:@"%@/Events?$filter=startswith(name,%%20'%@')%%20eq%%20true&$top=%d&$format=json", kUltraSignupMobileServiceURI, searchString, kMaxSearchResults];

    url = [NSURL URLWithString:urlString];
    ASIHTTPRequest *req1 = [ASIHTTPRequest requestWithURL:url];
    [req1 setDelegate:self];
    [req1 setTag:displayRequestTag+1];
    [req1 startAsynchronous];
    
    self.activeEventRequest = req1;
        
        
    // check if both a first and last name have been given
    // this is a little kludgy, maybe a better solution can be found...
    
    searchString = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray* names = [searchString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([names count] > 1) {       
        
        urlString = [NSString stringWithFormat:@"%@/Participants?$filter=startswith(first_name,%%20'%@')%%20eq%%20true%%20and%%20startswith(last_name,%%20'%@')%%20eq%%20true&$top=%d&$format=json", kUltraSignupMobileServiceURI, [names objectAtIndex:0], [names objectAtIndex:1], kMaxSearchResults];
    } else {
        
        urlString = [NSString stringWithFormat:@"%@/Participants?$filter=startswith(first_name,%%20'%@')%%20eq%%20true%%20or%%20startswith(last_name,%%20'%@')%%20eq%%20true&$top=%d&$format=json", kUltraSignupMobileServiceURI, searchString, searchString, kMaxSearchResults];         
    }
    
    url = [NSURL URLWithString:urlString];
    ASIHTTPRequest *req2 = [ASIHTTPRequest requestWithURL:url];
    [req2 setDelegate:self];
    [req2 setTag:displayRequestTag+1];
    [req2 startAsynchronous];
    
    self.activePersonRequest = req2;
    
}


-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{ 
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (searchBar.text.length > 0) {
        [self performSelector:@selector(startSearch:) withObject:searchBar afterDelay:0.25];
    } else {
        [self.searchData removeAllObjects];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self.searchData removeAllObjects];
}


#pragma mark - Search display delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{   
/*
     if (self.searchData.count == 0) {
        

 // use this to hide the test "No Results" before any results come back
        // see stackoverflow: http://stackoverflow.com/questions/1214185/uisearchdisplaycontroller-with-no-results-tableview
        [controller.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
        [controller.searchResultsTableView setRowHeight:800];
        [controller.searchResultsTableView setScrollEnabled:NO];
        for (UIView *subview in controller.searchResultsTableView.subviews) { [subview removeFromSuperview];
        }
    }
*/
        
    // reload will be done after web request returns
    return NO;
}


- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
    [self.searchData removeAllObjects];
    
    // cancel any existing requests
    [self.activeEventRequest clearDelegatesAndCancel];
    [self.activePersonRequest clearDelegatesAndCancel];
/*    
    [controller.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
    [controller.searchResultsTableView setRowHeight:800];
    [controller.searchResultsTableView setScrollEnabled:NO];
*/
}


#pragma mark - ASIHTTPRequest delegate methods

- (void)requestFinished:(ASIHTTPRequest *)request
{            
    NSString* response = [request responseString];
    
    SBJsonParser *json;
    NSError *jsonError = nil;
        
    static NSDateFormatter *dateFormatter;    
    if (dateFormatter == nil) {
        
        // format example:  Tue, 05 Dec 2011 00:54:00 GMT
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"]; 
    }
                
    // parse JSON string into NSDictionary
    json = [[SBJsonParser new] autorelease];
    NSDictionary *parsedJSON = [json objectWithString:response error:&jsonError];
    
    if (jsonError) {
        NSLog(@"%@",[jsonError description]);
    }
    
    NSMutableArray *data = [parsedJSON objectForKey:@"d"];

    BOOL shouldUpdateTable = NO;
    if (request.tag == displayRequestTag) {
        [self.tempSearchData addObjectsFromArray:data];
        shouldUpdateTable = YES;
    } else {
        self.tempSearchData = data;
        displayRequestTag++;
    }
    
/*    
    // undo changes made in shouldReloadTableForSearchString:
    [searchTable setBackgroundColor:[UIColor whiteColor]];
    [searchTable setRowHeight:44];
    [searchTable setScrollEnabled:YES];
*/    
    
    // we won't update the table until search results for both people and results for events have been returned
    if (shouldUpdateTable) {
        [self prepareToUpdateTable];
    }

}


- (void)requestFailed:(ASIHTTPRequest *)request
{
    //NSError *error = [request error];
    
    // TODO:  report error
    
    // this will be triggered if either of the queries is bad (could maybe happen if search term breaks the url)

    BOOL shouldUpdateTable = NO;
    if (request.tag == displayRequestTag) {
        shouldUpdateTable = YES;
    } else {
        [self.tempSearchData removeAllObjects];
        displayRequestTag++;
    }
    
    if (shouldUpdateTable) {
        [self prepareToUpdateTable];
    }
}

@end
