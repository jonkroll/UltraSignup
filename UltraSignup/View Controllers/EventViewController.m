//
//  EventViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 7/4/11.
//  Copyright 2011. All rights reserved.
//

#import "Settings.h"
#import "ASIHTTPRequest.h"
#import "EventDrilldownViewController.h"
#import "EventViewController.h"
#import "ResultsViewController.h"
#import "SearchViewController.h"
#import "JKWebViewController.h"
#import "SBJson.h"
#import "NSDate+UltraSignup.h"


@implementation EventViewController

@synthesize event = _event;
@synthesize eventImage;
@synthesize eventDatesArray;

@synthesize upcomingDate;
@synthesize latestDate;
@synthesize previousDates;

@synthesize activeRequest;

- (id)initWithNibName:(NSString *)nibNameOrNil 
            withEvent:(NSDictionary *)event 
                bundle:(NSBundle *)bundleOrNil
{
    self = [super initWithNibName:nibNameOrNil 
                           bundle:bundleOrNil];
    if (self) {
        // Custom initialization
        self.event = event;        
        
        hasMap = (![[event objectForKey:@"latitude"] isEqual:[NSNull null]] && ![[[event objectForKey:@"latitude"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]);

        hasWebsite = ([event objectForKey:@"url"] != [NSNull null]);
                
        [self loadResults];

    }
    return self;    
}

- (void)dealloc
{
    [activeRequest clearDelegatesAndCancel];
    [activeRequest release];
    
    [super dealloc];
}


- (void)loadResults
{
    NSString* urlString = [NSString stringWithFormat:@"%@/EventDates?$filter=event_id%%20eq%%20%@&$expand=vwMobileEventDistances/vwMobileEventDate/vwMobileEvent&$orderby=event_date%%20desc&$format=json",
                           kUltraSignupMobileServiceURI,
                           [[self.event objectForKey:@"event_id"] stringValue]
                           ];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
    
    //[req setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy];
    [req setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [req setSecondsToCache:60*60*24*30]; // Cache for 30 days
    [req setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy]; // save search between sessions

    [req setDelegate:self];
    [req startAsynchronous];
    
    self.activeRequest = req;
    
}

- (void)reloadResultsSection
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)showMap
{    
    MKMapView * map = [[MKMapView alloc] initWithFrame:
           CGRectMake(0, 0, 320, 480)];
    
    CLLocationCoordinate2D coords;
    coords.latitude = [[self.event objectForKey:@"latitude"] doubleValue];
    coords.longitude =  [[self.event objectForKey:@"longitude"] doubleValue];
    MKCoordinateSpan span = MKCoordinateSpanMake(0.5, 0.5);
    MKCoordinateRegion region = MKCoordinateRegionMake(coords, span);
    [map setRegion:region animated:YES];
    
    MKPointAnnotation* pin = [[MKPointAnnotation alloc] init];
    pin.coordinate = coords;
    pin.title = [self.event objectForKey:@"name"];
    pin.subtitle = [NSString stringWithFormat:@"%@ %@",[self.event objectForKey:@"city"],[self.event objectForKey:@"state"]];
    [map addAnnotation:pin];
    
    [map selectAnnotation:pin animated:YES];
    [pin release];
    
    UIViewController *vc = [[UIViewController alloc] init];
    [vc.view addSubview:map];
    
    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:[self.event objectForKey:@"name"]];
    vc.navigationItem.titleView = myLabel;
    [myLabel release];
    
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
    [map release];    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
     
    // set title for View
    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:[self.event objectForKey:@"name"]];
    self.navigationItem.titleView = myLabel;
    [myLabel release];
    
    // add multi-button to upper right                            
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
                                            [NSArray arrayWithObjects:
                                             [UIImage imageNamed:@"UIButtonBarSearch.png"],
                                             [UIImage imageNamed:@"UIButtonBarHome.png"],
                                             nil]];
    segmentedControl.frame = CGRectMake(0, 0, 90, 30);
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.momentary = YES;
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];    
    self.navigationItem.rightBarButtonItem = segmentBarItem;
    [segmentedControl release];
    [segmentBarItem release];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
            numRows = 1;  // top cell
            if (hasWebsite) numRows++;
            if (upcomingDate != nil) numRows++;
            break;
        case 1:
            if ([self.eventDatesArray count] == 0) {
                numRows = 1;
            } else {
                numRows = 0;
                if (latestDate    != nil)  numRows++;                
                if (previousDates != nil)  numRows++;
            }
            break;
    }
    return numRows;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0 && [indexPath row] == 0) {
        
        int rowHeight = 102;
        if (hasMap) { rowHeight += 110; }
        
        return rowHeight;
    } else {
        return 44;
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 1 : return @"Past Results"; break;
    }
    return Nil;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if ([indexPath section] == 0 && [indexPath row] == 0) {

        static NSString *CellIdentifier = @"EventDetailsCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                           reuseIdentifier:CellIdentifier] autorelease];
        }
 
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        // event name
        UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 280, 20)];
        labelName.numberOfLines = 1;
        labelName.lineBreakMode = UILineBreakModeTailTruncation;
        labelName.text = [self.event objectForKey:@"name"];        
        labelName.font = [UIFont boldSystemFontOfSize:20];
        labelName.backgroundColor = [UIColor clearColor];
        
        // location
        UILabel *labelLocation = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 280, 20)];
        labelLocation.numberOfLines = 1;
        labelLocation.textColor = [UIColor grayColor];
        labelLocation.font = [UIFont systemFontOfSize:14];
        labelLocation.lineBreakMode = UILineBreakModeTailTruncation;
        labelLocation.backgroundColor = [UIColor clearColor];
        labelLocation.text = [NSString stringWithFormat:@"%@ %@%", 
                                [self.event objectForKey:@"city"], 
                                [self.event objectForKey:@"state"]];
        
        // country
        UILabel *labelCountry = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, 280, 20)];
        labelCountry.numberOfLines = 1;
        labelCountry.textColor = [UIColor grayColor];
        labelCountry.font = [UIFont systemFontOfSize:14];
        labelCountry.lineBreakMode = UILineBreakModeTailTruncation;
        labelCountry.backgroundColor = [UIColor clearColor];
        labelCountry.text = [self.event objectForKey:@"country"];
        
        
        // add subviews
        [[cell contentView] addSubview:labelName];
        [[cell contentView] addSubview:labelLocation];
        [[cell contentView] addSubview:labelCountry];
        
        
        // cleanup
        [labelName release];
        [labelLocation release];
        [labelCountry release];
        //[labelLatLong release];

        // note: image will be added later after it loads (asynchronously)  
        
        
        if (hasMap) {
            
            MKMapView * map = nil;
            MKPointAnnotation* pin;
        
            
            map = [[MKMapView alloc] initWithFrame:CGRectMake(10, 80, 280, 120)];
            
            CLLocationCoordinate2D coords;
            coords.latitude = [[self.event objectForKey:@"latitude"] doubleValue];
            coords.longitude =  [[self.event objectForKey:@"longitude"] doubleValue];
            MKCoordinateSpan span = MKCoordinateSpanMake(0.5, 0.5);
            MKCoordinateRegion region = MKCoordinateRegionMake(coords, span);
            [map setRegion:region animated:YES];
            
            pin = [[MKPointAnnotation alloc] init];
            pin.coordinate = coords;
            pin.title = [self.event objectForKey:@"name"];
            pin.subtitle = [NSString stringWithFormat:@"%@ %@",[self.event objectForKey:@"city"],[self.event objectForKey:@"state"]];
            [map addAnnotation:pin];
            map.scrollEnabled = NO;
            
            [map selectAnnotation:pin animated:YES];
            [pin release];
            
            map.layer.borderColor = [[UIColor lightGrayColor] CGColor];
            map.layer.borderWidth = 1.0;
            map.layer.cornerRadius = 5.0;
            map.layer.masksToBounds = YES;

            [cell.contentView addSubview:map];
            
            [map release];
            
            // add a clear UIButton over the map so we can capture a click on the map
            
            UIButton *mapButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 80, 280, 120)];
            [cell.contentView addSubview:mapButton];
            [cell.contentView bringSubviewToFront:mapButton];
            [mapButton addTarget:self action:@selector(showMap) forControlEvents:UIControlEventTouchUpInside];
            
            // TODO: not sure about this one...
            //[mapButton addTarget:self action:@selector(highlightMap) forControlEvents:UIControlEventTouchDown];
            
            [mapButton release];
            
        }
        
        
    } else if ([indexPath section] == 0) {

        if ([indexPath row] == 1) {

            static NSString *cellIdentifier = @"EventWebsiteCell";
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:cellIdentifier] autorelease];
            }

            cell.textLabel.text = @"Event Website";                
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
        } else {
            
            static NSString *cellIdentifier = @"UpcomingDateCell";
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:cellIdentifier] autorelease];
            }

            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MMM d, YYYY"];
            
            cell.textLabel.text = [NSString stringWithFormat:@"Next Date %@", [dateFormatter stringFromDate:[NSDate dateFromJSONString:[upcomingDate objectForKey:@"event_date"]]]];               
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            [dateFormatter release];
        }
        
    } else {
        
        if (eventDatesArray == nil) {

            static NSString *CellIdentifier = @"SpinnerCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier] autorelease];
            } 

            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 16, 16, 16)]; 
            [activityIndicator startAnimating]; 
            [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray]; 
            [[cell contentView] addSubview:activityIndicator]; 
            [activityIndicator release]; 
            
            UILabel *loadingText = [[UILabel alloc] initWithFrame:CGRectMake(60, 12, 180, 20)];
            loadingText.text = @"Loading Event Dates...";
            loadingText.backgroundColor = [UIColor clearColor];
            [[cell contentView] addSubview:loadingText];
            [cell.textLabel setFont:[UIFont systemFontOfSize:20]];
            [loadingText release];                        
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
        } else if ([eventDatesArray count] == 0) {
            
            static NSString *CellIdentifier = @"NoEventDatesCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier] autorelease];
            } 
            
            cell.textLabel.text = @"No Event Dates Found";
            [cell.textLabel setFont:[UIFont systemFontOfSize:20]];
            [cell.textLabel setTextColor:[UIColor grayColor]];
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

            
        } else {
        
            static NSString *CellIdentifier = @"EventDatesCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:CellIdentifier] autorelease];
            }

            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MMM d, YYYY"];
            
            switch ([indexPath row]) {
                case 0:
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ Results", [dateFormatter stringFromDate:[NSDate dateFromJSONString:[latestDate objectForKey:@"event_date"]]]];
                    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                    break;
                    
               case 1:
                    if (previousDates != nil) {
                        cell.textLabel.text = [NSString stringWithFormat:@"%d Previous Date%@", [previousDates count], (([previousDates count] != 1) ? @"s" : @"") ];
                        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                        break;
                    }           
            }
            
            [dateFormatter release]; 
        }             
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *urlAddress = [self.event objectForKey:@"url"];
    
    if (indexPath.section == 0) {
                
        if (indexPath.row == 1) {
            
            // handle click on event website button
            if (false) {
                // open in Mobile Safari - not using this option
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlAddress]];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                // open using custom in-app browser (UIWebView)
                JKWebViewController *usweb = [[JKWebViewController alloc] initWithURL:[NSURL URLWithString:urlAddress]];
                
                JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:[self.event objectForKey:@"name"]];
                usweb.navigationItem.titleView = myLabel;
                [myLabel release];
                
                [self.navigationController pushViewController:usweb animated:YES];
                [usweb release];
            }
        } else if (indexPath.row == 2) {
            
            // handle click on upcoming event date row

            
             UITableViewController *registrantsViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
            
            JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:[self.event objectForKey:@"name"]];
            registrantsViewController.navigationItem.titleView = myLabel;
            [myLabel release];
            
            [self.navigationController pushViewController:registrantsViewController animated:YES];
            [registrantsViewController release];
                         
        }
    
    } else if (indexPath.section == 1) {
        
        if (indexPath.row == 0) {
             
            // handle click on latest results button

            NSMutableArray* eventDistances = [latestDate objectForKey:@"vwMobileEventDistances"];
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
                
                
                eventDrilldownViewController.eventName = [self.event objectForKey:@"name"];
                [self.navigationController pushViewController:eventDrilldownViewController animated:YES];
                [eventDrilldownViewController release];
                
            }
           
            
        } else if (indexPath.row == 1) {
            
            // handle click on "previous dates" button
            
            // need to go to drilldown controller to pick a date 
            EventDrilldownViewController* eventDrilldownViewController 
                        = [[EventDrilldownViewController alloc] initWithStyle:UITableViewStyleGrouped   
                                                              withEventDates:(NSMutableArray*)previousDates];
        
            eventDrilldownViewController.eventName = [self.event objectForKey:@"name"];
            [self.navigationController pushViewController:eventDrilldownViewController animated:YES];
            [eventDrilldownViewController release];
            
        }
    }

}


#pragma mark - ASIHttpRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSString *response = [request responseString];
    
    // parse JSON string into NSDictionary
    SBJsonParser *json = [[SBJsonParser new] autorelease];
    NSError *jsonError = nil;
    NSDictionary *parsedJSON = [json objectWithString:response error:&jsonError];
    
    if (jsonError) {
        NSLog(@"%@",[jsonError description]);
    }
    
    NSMutableArray *data = [parsedJSON objectForKey:@"d"];
    
    self.eventDatesArray = data;
    

    // find next upcoming date
    NSInteger numDates = [data count];
    NSDate *today = [NSDate date];
    NSInteger startIndexOfEarlierDates = -1;
    NSInteger i;

     // scroll through date array backwards until we find the first future date
     for (i=numDates-1; i >= 0; i--) {
         NSDictionary* theDate = (NSDictionary*)[data objectAtIndex:i];
         if ([today compare:[NSDate dateFromJSONString:[theDate objectForKey:@"event_date"]]] == NSOrderedAscending) {
             upcomingDate = theDate;
             break;
         }
     }

     
     // scroll through date array forwards until we find the first past date
     for (i=0; i < numDates; i++) {
         NSDictionary* theDate = (NSDictionary*)[data objectAtIndex:i];
         if ([today compare:[NSDate dateFromJSONString:[theDate objectForKey:@"event_date"]]] == NSOrderedDescending) {
             latestDate = theDate;
             if (i < numDates-1) {
                 startIndexOfEarlierDates = i+1;
             }
             break;
        }
     }   
 

    if (startIndexOfEarlierDates > -1) {
        previousDates = [[data subarrayWithRange:NSMakeRange (startIndexOfEarlierDates, numDates-startIndexOfEarlierDates)] retain];
    }
    
    // only reload the section with the results
    [self.tableView performSelectorOnMainThread:@selector(reloadData) 
                                       withObject:nil 
                                    waitUntilDone:NO];
    
}


- (void)requestFailed:(ASIHTTPRequest *)request
{

    //NSError *error = [request error];
        
    // TODO: stop spinner and report error
    
}


#pragma mark - Segmented button methods

- (void)segmentAction:(UISegmentedControl*)sender 
{
    switch ([sender selectedSegmentIndex])
    {
        case 0: // search
        {
            SearchViewController *svc = [[SearchViewController alloc] 
                                         initWithNibName:@"SearchViewController"
                                         bundle:nil];
            svc.title = @"Search";
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

@end
