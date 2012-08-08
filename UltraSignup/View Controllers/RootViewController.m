//
//  RootViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 7/7/11.
//  Copyright 2011. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "Settings.h"
#import "AboutViewController.h"
#import "EventDrilldownViewController.h"
#import "PersonViewController.h"
#import "RecentEventsViewController.h"
#import "ResultsViewController.h"
#import "RootViewController.h"
#import "SearchViewController.h"
#import "NewsItem.h"
#import "NewsListViewController.h"
#import "NewsViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "SBJson.h"
#import "RXMLElement.h"
#import "NSDate+UltraSignup.h"
#import "FlurryAnalytics.h"
#import "JKBorderedLabel.h"

@implementation RootViewController

@synthesize tableView = _tableView;
@synthesize eventDatesArray = _eventDatesArray;
@synthesize localEventDatesArray = _localEventDatesArray;
@synthesize newsArray = _newsArray;
@synthesize activeRequest;
@synthesize location;


- (void)dealloc
{
    [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)showAboutController
{
    AboutViewController *avc = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
    [self.navigationController pushViewController:avc animated:YES];
    [avc release]; 
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    isUsingDeviceSimulator = NO;            
#if TARGET_IPHONE_SIMULATOR
    isUsingDeviceSimulator = YES;
#endif 
    
    // Access the location manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    locationManager.delegate = self;
    locationManager.distanceFilter = 100000.0f;  // 100km
    locationManager.purpose = @"Ultra Signup will use your current location to show you results from events in your area."; 
    [locationManager startUpdatingLocation];
    
    
    // initialize storage arrays
    self.localEventDatesArray   = [NSMutableArray arrayWithCapacity:0];
    self.newsArray              = [NSMutableArray arrayWithCapacity:0];
         
    
    // set nav bar color to yellow-green
    self.navigationController.navigationBar.tintColor = kUltraSignupColor;
    
    
    // insert logo into nav bar
    UIImageView* logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UltraSignup_Logo.png"]];    
    self.navigationItem.titleView = logo;
    self.navigationItem.title = @"Home";
    [logo release];

    
    // add Settings Button
    UIImage *settingsImage = [UIImage imageNamed:@"UIButtonBarSettings.png"];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithImage:settingsImage 
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self 
                                                                   action:@selector(showAboutController)];
    self.navigationItem.leftBarButtonItem = leftButton;
    [leftButton release];
    

    // add Search button
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UIButtonBarSearch.png"]
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self 
                                                                   action:@selector(showSearchViewController)];
    self.navigationItem.rightBarButtonItem = rightButton;
    [rightButton release];
 
    
    // get most recent events
    //   exclude any that are missing a name
    NSDate* today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    NSString* urlString = [NSString stringWithFormat:@"%@/EventDates?$filter=event_date%%20lt%%20datetime'%@'%%20and%%20vwMobileEvent/name%%20ne%%20''&$expand=vwMobileEvent,vwMobileEventDistances/vwMobileEventDate/vwMobileEvent&$top=100&$orderby=event_date%%20desc&$format=json", kUltraSignupMobileServiceURI, [dateFormatter stringFromDate:today]];
    [dateFormatter release];
        
    NSLog(@"%@",urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request startSynchronous]; 
    
    //note: TODO maybe change this to be done asynchronously instead? - might speed loading time
    
    NSError *error = [request error];
    if (!error) {

        NSString* response = [request responseString]; 
        
        if ([request didUseCachedResponse]) {
            NSLog(@"%@", @"Used cache");
        } else {
            NSLog(@"%@", @"Did not use cache");            
        }
        
        SBJsonParser *json = [[SBJsonParser new] autorelease];
        NSError *jsonError = nil;
        NSDictionary *parsedJSON = [json objectWithString:response error:&jsonError];
        
        if (jsonError) {
            NSLog(@"%@",[jsonError description]);
        }
        
        
        self.eventDatesArray = [NSMutableArray arrayWithCapacity:0];    
        NSDictionary *eventDate;
        NSDictionary *eventDistance;
        
        // loop through returned eventdates and only include ones that have results
        for (eventDate in [parsedJSON objectForKey:@"d"]) {
            NSArray *eventDistances = [eventDate objectForKey:@"vwMobileEventDistances"];
            for (eventDistance in eventDistances) {
                if ([[eventDistance objectForKey:@"results"] intValue] == 1) {
                    [self.eventDatesArray addObject:eventDate];
                    break;
                }            
            }
        }
        [self updateLocalEventDatesArray];
    }
    
    // get ultrarunning news
    url = [NSURL URLWithString:@"http://www.ultrarunning.com/ultra/affiliate/rssLatest.rss"];
    ASIHTTPRequest *newsRequest = [ASIHTTPRequest requestWithURL:url];
    [newsRequest setURL:url];
    [newsRequest setTag:REQUEST_TYPE_NEWS];
    [newsRequest setDelegate:self];
    [newsRequest startAsynchronous];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)showSearchViewController
{
    
     UIViewController* searchViewController = [[SearchViewController alloc] 
                                               initWithNibName:@"SearchViewController"
                                               bundle:nil];
    searchViewController.title = @"Search";
    [self.navigationController pushViewController:searchViewController animated:YES];
    [searchViewController release];  
     
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = 0;

    switch (section) {
        case 0:
            if ([self.localEventDatesArray count] > 0) {
                numRows = [self.localEventDatesArray count] + 1;  // +1 is for the "Show All Recent Events" row
            } else {
                numRows = 0;
            }
            break;


        case 1:
            if ([self.newsArray count] > 0) {
                numRows = 2; // one news items and one link to "more news"
            } else {
                numRows = 0;
            }
            break;

        default:
            numRows = 0;
            break;
    }

    return numRows;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: return 44; break;
        case 1: 
            switch (indexPath.row) {
                case 0: 
                {
                    NewsItem *newsItem = [self.newsArray objectAtIndex:[indexPath row]];
                    
                    NSString* text = [NSString stringWithFormat:@"%@", newsItem.title];
                    
                    int CELL_CONTENT_WIDTH = 320;
                    int CELL_CONTENT_MARGIN_X = 20;
                    int CELL_CONTENT_MARGIN_Y = 10;
                    int DATELINE_HEIGHT = 20;
                    
                    CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN_X * 2), 20000.0f);
                    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:16] 
                                   constrainedToSize:constraint
                                       lineBreakMode:UILineBreakModeWordWrap];
                    
                    
                    return size.height + DATELINE_HEIGHT + (CELL_CONTENT_MARGIN_Y * 2); break;  // news item
                
                }
                
                case 1: return 44; break;
            }
            break;
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier;
    UITableViewCell *cell = nil;
    
    switch (indexPath.section) {
        case 0:
            
            if (indexPath.row < MIN([[self localEventDatesArray] count],4)) {
            
                CellIdentifier = @"EventDateCell";
                
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil) {
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
                }
                
                NSDictionary* eventDate = [[self localEventDatesArray] objectAtIndex:[indexPath row]];   
                NSDictionary* event = (NSDictionary*)[eventDate objectForKey:@"vwMobileEvent"];
               
                NSDate* theDate = [NSDate dateFromJSONString:[eventDate objectForKey:@"event_date"]];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"MMM d, YYYY"];
                
                cell.textLabel.text = [event objectForKey:@"name"];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ • %@", 
                                             [event objectForKey:@"city"], 
                                             [event objectForKey:@"state"], 
                                             [dateFormatter stringFromDate:theDate]];
                
                [dateFormatter release];
                
            
            } else {

                CellIdentifier = @"MoreCell";
                
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil) {
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
                }
                cell.textLabel.text = @"Additional Recent Events";
            }
 
            break;
            
        case 1:
            
            if (indexPath.row == 0) {
                
                CellIdentifier = @"NewsCell";
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                if (cell == nil) {
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                   reuseIdentifier:CellIdentifier] autorelease];
                } else {
                    // remove old values from cell
                    // if we were were using a Nib file for the cell layout we wouldn't need to do this
                    for (UIView *view in [cell subviews]) {
                        if ([view isMemberOfClass:[UILabel class]]) { 
                            [view removeFromSuperview];
                        }
                    }
                    cell.textLabel.text = @"";
                }
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"EEEE, MMM d, yyyy"]; 
                
                NewsItem *newsItem = [self.newsArray objectAtIndex:[indexPath row]];
                
                UILabel* headlineLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                headlineLabel.lineBreakMode = UILineBreakModeWordWrap;
                headlineLabel.numberOfLines = 0;
                headlineLabel.highlightedTextColor = [UIColor whiteColor];
                headlineLabel.backgroundColor = [UIColor clearColor];
                headlineLabel.font = [UIFont boldSystemFontOfSize:16];
                headlineLabel.textAlignment = UITextAlignmentLeft;
                
                NSString* text = [NSString stringWithFormat:@"%@", newsItem.title];
                int CELL_CONTENT_WIDTH = 300;
                int CELL_CONTENT_MARGIN_X = 20;
                int CELL_CONTENT_MARGIN_Y = 10;
                int DATELINE_HEIGHT = 20;
                
                CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN_X * 2), 20000.0f);
                CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:16] 
                               constrainedToSize:constraint
                                   lineBreakMode:UILineBreakModeWordWrap];
                

                [headlineLabel setText:text];
                [headlineLabel setFrame:CGRectMake(CELL_CONTENT_MARGIN_X, 
                                                   CELL_CONTENT_MARGIN_Y, 
                                                   size.width, 
                                                   size.height)];

                UILabel* dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,size.height + CELL_CONTENT_MARGIN_Y,300,DATELINE_HEIGHT)];
                dateLabel.text = [dateFormatter stringFromDate:newsItem.date];    
                dateLabel.highlightedTextColor = [UIColor whiteColor];
                dateLabel.font = [UIFont systemFontOfSize:14];
                dateLabel.backgroundColor = [UIColor clearColor];
                dateLabel.textColor = [UIColor grayColor];
                
                [cell addSubview:headlineLabel];
                [cell addSubview:dateLabel];
 
                [headlineLabel release];
                [dateLabel release];
                [dateFormatter release];
                
            } else {

                CellIdentifier = @"MoreNewsCell";
                
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil) {
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                   reuseIdentifier:CellIdentifier] autorelease];
                }
                
                cell.textLabel.text = @"More News";            
                
            }
            
            break;
    }

    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString* title = @"";
        
    switch (section)
    {
        case 0:
            if ([self.localEventDatesArray count] > 0 ) {
                if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
                    title = @"Recent Local Events";
                } else {
                    title = @"Recent Events";
                }
            }
            break;
            
        case 1:
            if ([self.newsArray count] > 0 ) {
                title = @"Ultrarunning.com News";
            } else {
                title = @"";                    
            }
            break;
    }
        
    return title;
}


#pragma mark - Table view delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController* detailViewController;
    NSDictionary* eventDate;
    NSDictionary* event;
    NewsItem* newsItem;
    
    switch (indexPath.section)
    {
        case 0:

             if (indexPath.row < MIN([[self localEventDatesArray] count],4)) {


                eventDate = (NSDictionary*)[[self localEventDatesArray] objectAtIndex:[indexPath row]];
                event = (NSDictionary*)[eventDate objectForKey:@"vwMobileEvent"];

                 NSMutableArray* eventDistances = [eventDate objectForKey:@"vwMobileEventDistances"];
                if ([eventDistances count] == 1) {
                    
                    NSDictionary* eventDist = (NSDictionary*)[eventDistances objectAtIndex:0];
                    UIViewController* resultsViewController = [[ResultsViewController alloc] 
                                                               initWithNibName:@"ResultsViewController"
                                                               withEventDistance:eventDist 
                                                               bundle:nil];
                    
                    [self.navigationController pushViewController:resultsViewController animated:YES];
                    [resultsViewController release];
            
                } else {
                    
                    // need to go to drilldown controller to pick a distance
                    EventDrilldownViewController* eventDrilldownViewController 
                    = [[EventDrilldownViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                       withEventDistances:eventDistances];
                    
                    
                    eventDrilldownViewController.eventName = [event objectForKey:@"name"];
                    [self.navigationController pushViewController:eventDrilldownViewController animated:YES];
                    [eventDrilldownViewController release];
                    
                }

            } else {
                
                // show "additional recent results" cell
                
                 RecentEventsViewController* vc 
                =  [[RecentEventsViewController alloc] initWithRecentEvents:[self eventDatesArray]];
                [self.navigationController pushViewController:vc animated:YES];
                [vc release];
                                    
            }

             
            break;
/*                
            
        case 1:
        
            switch (indexPath.row)
            {   
                case 0:
                    detailViewController = [[AboutViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    [self.navigationController pushViewController:detailViewController animated:YES];
                    [detailViewController release];
                    break;
            }
            break;
*/            
        case 1:
            
            // handle click on news story
            if (indexPath.row == 0) {
                newsItem = [self.newsArray objectAtIndex:[indexPath row]];
                
                detailViewController = [[NewsViewController alloc] initWithNewsItem:newsItem];
                detailViewController.title = newsItem.title;   
                [self.navigationController pushViewController:detailViewController animated:YES];
                [detailViewController release];
            } else {

                detailViewController = [[NewsListViewController alloc] initWithNewsArray:self.newsArray];
                detailViewController.title = @"News";
                [self.navigationController pushViewController:detailViewController animated:YES];
                [detailViewController release];
                break;
            }
            break;
            
    }
        
}


#pragma mark - ASIHTTPRequest delegate methods

- (void)requestFinished:(ASIHTTPRequest *)request
{        
    NSString* response = [request responseString];
    
    RXMLElement *rxml;
    static NSDateFormatter *dateFormatter;
        
    if (dateFormatter == nil) {
        
        // format example:  Tue, 05 Dec 2011 00:54:00 GMT
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"]; 
        
    }


    switch(request.tag) {
            
        case REQUEST_TYPE_NEWS:
            
            rxml = [RXMLElement elementFromXMLString:response];
                        
            [rxml iterate:@"channel.item" with: ^(RXMLElement *item) {
                
                // only include "feature" news articles in Ultrarunning rss feed
                if ([[[item child:@"link"] text] hasPrefix:@"http://www.ultrarunning.com/ultra/features/news/"]) {
                
                    NewsItem *newsItem = [[NewsItem alloc] initWithTitle:[[item child:@"title"] text]
                                               withDescription:[[item child:@"description"] text]
                                                      withDate:[dateFormatter dateFromString:[[item child:@"pubDate"] text]] 
                                                       withURL:[[item child:@"link"] text]];
                    
                    [self.newsArray addObject:newsItem];
                    [newsItem release];
                }
                
            }];  
            
            [self.tableView performSelectorOnMainThread:@selector(reloadData) 
                                             withObject:nil 
                                          waitUntilDone:NO];
            
            break;
    }
    
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
    //NSError *error = [request error];
        
    // TODO:  report error
    
}


#pragma mark - Core Location delegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation

{
    location = newLocation;
    [location retain];
    
    [FlurryAnalytics setLatitude:location.coordinate.latitude            
                       longitude:location.coordinate.longitude            
              horizontalAccuracy:location.horizontalAccuracy            
                verticalAccuracy:location.verticalAccuracy];
    
    [self updateLocalEventDatesArray];
    
}

- (void)updateLocalEventDatesArray
{
    
    if (isUsingDeviceSimulator || [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
    
        // core location not enabled, just show the top 4 events in the list, regardless of location
        int howmany = MIN([self.eventDatesArray count], 4);        
        self.localEventDatesArray = [NSMutableArray arrayWithArray:[self.eventDatesArray subarrayWithRange:NSMakeRange( 0, howmany )]];
                
    } else {
   
        if (location != nil && self.eventDatesArray != nil) {
    
            // clear localEventDatesArray
            [self.localEventDatesArray removeAllObjects];
            
            NSDictionary *eventDate;
            for(eventDate in self.eventDatesArray) {
                
                NSDictionary *event = [eventDate objectForKey:@"vwMobileEvent"];
                        
                // add a maximum of 4 local events
                // and watch out for events will a NULL location
                if ([self.localEventDatesArray count] < 4 && ![[event objectForKey:@"latitude"] isEqual:[NSNull null]]
                    && ![[event objectForKey:@"latitude"] isEqualToString:@""]) {

                    NSString *latitudeString = [event objectForKey:@"latitude"];
                    
                    if ([latitudeString characterAtIndex:0] == '+') {
                        latitudeString = [latitudeString substringFromIndex:1];
                    }
                    
                    double latitude  = [latitudeString doubleValue];
                    double longitude = [[event objectForKey:@"longitude"] doubleValue];

                    // create CLLocation object for event using lat/long            
                    CLLocation *eventLocation = [[CLLocation alloc] initWithLatitude:latitude
                                                                           longitude:longitude];
                    
                    // compare location of event to user's location
                    // if < 500 km, add eventDate to localEventDates
                    CLLocationDistance distance = [eventLocation distanceFromLocation:self.location];                    
                    if ((distance / 1000.0) < 500.0) {
                        [self.localEventDatesArray addObject:eventDate];
                    }
                    
                    [eventLocation release];
                    
                }    
                
            }
        
            if ([self.localEventDatesArray count] == 0) {
                // there were no nearby events in top 100 most recent events
                // so show default top 4
                self.localEventDatesArray = [NSMutableArray arrayWithArray:[self.eventDatesArray subarrayWithRange:NSMakeRange( 0, 4 )]];               
            
            }
        }
        
    }

    [self.tableView reloadData];
}

@end
