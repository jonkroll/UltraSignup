//
//  ResultsViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 7/3/11.
//  Copyright 2011. All rights reserved.
//

#import "Settings.h"
#import "EventViewController.h"
#import "PersonViewController.h"
#import "ResultsViewController.h"
#import "SearchViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "SBJson.h"
#import "NSDate+UltraSignup.h"


@implementation ResultsViewController

@synthesize eventDistance;
@synthesize tableView = _tableView;
@synthesize resultsFilter;
@synthesize resultsArray;
@synthesize filteredResultsArray;
@synthesize eventDistanceMasthead = _eventDistanceMasthead;
@synthesize labelEventName = _labelEventName;
@synthesize labelEventLocation = _labelEventLocation;
@synthesize labelEventDateDistance = _labelEvenDatetDistance;
@synthesize activeRequest;
@synthesize masthead = _masthead;

- (id)initWithNibName:(NSString *)nibNameOrNil 
    withEventDistance:(NSDictionary *)eventDist
               bundle:(NSBundle *)nibBundleOrNil;
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.eventDistance = eventDist;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSDictionary* eventDate = (NSDictionary*)[eventDistance objectForKey:@"vwMobileEventDate"];
    NSDictionary* event = (NSDictionary*)[eventDate objectForKey:@"vwMobileEvent"];
    
    // set title for View
    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:[event objectForKey:@"name"]];
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
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, YYYY"];

    NSString* dateString = [dateFormatter stringFromDate:[NSDate dateFromJSONString:[eventDate objectForKey:@"event_date"]]];
    [dateFormatter release];
    
    self.labelEventName.text = [event objectForKey:@"name"];
    self.labelEventLocation.text = [NSString stringWithFormat:@"%@ %@", [event objectForKey:@"city"], [event objectForKey:@"state"]];
    self.labelEventDateDistance.text = [NSString stringWithFormat:@"%@ • %@", dateString, [eventDistance objectForKey:@"distance"]];
    
    self.masthead.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"mastheadBackground.png"]];
    
    [self loadResults];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


- (void)dealloc
{    
    [activeRequest clearDelegatesAndCancel];
    [activeRequest release];
    
    [super dealloc];
}


 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)loadResults
{
    
    NSString* urlString = [NSString stringWithFormat:@"%@/Results?$filter=event_distance_id%%20eq%%20%@&$expand=Participant&$orderby=place&$top=100&$format=json",
                           kUltraSignupMobileServiceURI,
                           [[eventDistance objectForKey:@"event_distance_id"] stringValue]
                           ];
    
    NSLog(@"%@",urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
        
    //[req setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy];
    [req setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [req setSecondsToCache:60*60*24*30]; // Cache for 30 days
    [req setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy]; // save search between sessions
    
    [req setDelegate:self];
    [req setTimeOutSeconds:15];
    
    [req startAsynchronous];
    
    self.activeRequest = req;
    
}


- (void)reloadTableData
{
    if (self.resultsArray.count > 0) {
        
        // add filter to top of tableview
        
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        
        UISegmentedControl* genderFilter = [[UISegmentedControl alloc] initWithFrame:CGRectMake(6, 6, 308, 32)];
        
        [genderFilter insertSegmentWithTitle:@"All" atIndex:0 animated:NO];
        [genderFilter insertSegmentWithTitle:@"Men" atIndex:1 animated:NO];
        [genderFilter insertSegmentWithTitle:@"Women" atIndex:2 animated:NO];
        
        genderFilter.segmentedControlStyle = UISegmentedControlStyleBar;
        genderFilter.tintColor = kUltraSignupColor;
        genderFilter.selectedSegmentIndex = 0;
        [genderFilter addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventValueChanged];
        
        self.resultsFilter = genderFilter;
        
        [containerView addSubview:genderFilter];
        self.tableView.tableHeaderView = containerView;
        
        [genderFilter release];
        [containerView release];
    }
    
    [self.tableView reloadData];
    
    // scroll table header so filters will appear off screen at the start     
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
}

- (void)changeFilter:(id)sender
{
    UISegmentedControl* segControl = sender;
        
    self.filteredResultsArray = [NSMutableArray arrayWithArray:resultsArray];
    
    switch(segControl.selectedSegmentIndex)
    {
        case RESULTS_FILTER_TYPE_ALL:
            // show all results
            break;
        case RESULTS_FILTER_TYPE_MEN:{
            // show men results
            NSPredicate *predicate = [NSPredicate predicateWithBlock: ^BOOL(id obj, NSDictionary *bind){
                return [[(NSDictionary *)[(NSDictionary *)obj objectForKey:@"Participant"] objectForKey:@"gender"] isEqualToString:@"M"];
            }];
            [filteredResultsArray filterUsingPredicate:predicate];
            break;
        }
        case RESULTS_FILTER_TYPE_WOMEN: {
            // show women results
            NSPredicate *predicate = [NSPredicate predicateWithBlock: ^BOOL(id obj, NSDictionary *bind){
                return [[(NSDictionary *)[(NSDictionary *)obj objectForKey:@"Participant"] objectForKey:@"gender"] isEqualToString:@"F"];
            }];
            [filteredResultsArray filterUsingPredicate:predicate];
            break;
        }
    }
    [self.tableView reloadData];
    
}


- (IBAction)goToEventView: (id) sender;
{
    
    NSDictionary* eventDate = (NSDictionary*)[self.eventDistance objectForKey:@"vwMobileEventDate"];
    NSDictionary* event = (NSDictionary*)[eventDate objectForKey:@"vwMobileEvent"];
    
    
    EventViewController *eventViewController = [[EventViewController alloc] 
                                                initWithNibName:@"PersonViewController"  
                                                withEvent:event
                                                bundle:nil];
    
    [self.navigationController pushViewController:eventViewController animated:YES];
    [eventViewController release];
    
}

#pragma mark - table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.resultsArray count] == 0)
    {
        return 1;
    } else {
    
    return [self.filteredResultsArray count];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    UITableViewCell *cell;
    
    if (resultsArray == nil) {
        
        CellIdentifier = @"SpinnerCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                           reuseIdentifier:CellIdentifier] autorelease];
        } 
        
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(75, 12, 20, 20)]; 
        [activityIndicator startAnimating]; 
        [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray]; 
        [[cell contentView] addSubview:activityIndicator]; 
        [activityIndicator release]; 
        
        UILabel *loadingText = [[UILabel alloc] initWithFrame:CGRectMake(105, 12, 170, 20)];
        loadingText.text = @"Loading Results...";
        [[cell contentView] addSubview:loadingText];
        [cell.textLabel setFont:[UIFont systemFontOfSize:20]];
        [loadingText release];                        
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
    } else if ([resultsArray
                count] == 0) {
        
        CellIdentifier = @"NoResultCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                           reuseIdentifier:CellIdentifier] autorelease];
        } 
        
        cell.textLabel.text = @"No Results Available";
        [cell.textLabel setFont:[UIFont systemFontOfSize:20]];
        [cell.textLabel setTextColor:[UIColor grayColor]];
        [cell.textLabel setTextAlignment:UITextAlignmentCenter];

        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
    } else {
    
        CellIdentifier = @"ResultCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
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

         
        NSDictionary *result = [filteredResultsArray objectAtIndex:[indexPath row]];
        NSDictionary* participant = (NSDictionary*)[result objectForKey:@"Participant"];
            
   
        // Configure the cell
        
        UILabel* placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,32,21)];
        placeLabel.textAlignment = UITextAlignmentCenter;
        placeLabel.highlightedTextColor = [UIColor whiteColor];
        
        if (self.resultsFilter.selectedSegmentIndex == RESULTS_FILTER_TYPE_ALL) {
            placeLabel.text = [NSString stringWithFormat:@"%@", [result objectForKey:@"place"]];
        } else {
            // show gender place instead of overall place
            placeLabel.text = [NSString stringWithFormat:@"%d%@", indexPath.row + 1, [participant objectForKey:@"gender"]];
            placeLabel.textColor = [UIColor redColor];
            placeLabel.font = [UIFont systemFontOfSize:14];
            placeLabel.lineBreakMode = UILineBreakModeClip;
        }
        
        
        UILabel* nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(44,0,190,21)];
        nameLabel.text = [NSString stringWithFormat:@"%@ %@", [participant objectForKey:@"first_name"], [participant objectForKey:@"last_name"]];    
        nameLabel.highlightedTextColor = [UIColor whiteColor];
        nameLabel.font = [UIFont boldSystemFontOfSize:16];
        nameLabel.lineBreakMode = UILineBreakModeTailTruncation;

        
        NSMutableString* categoryText = [[NSMutableString alloc] initWithString:@""];
        if ([participant objectForKey:@"gender"] != nil) {
            [categoryText appendString:[participant objectForKey:@"gender"]];
        }
        if ([result objectForKey:@"age"] != nil && ![[result objectForKey:@"age"] isEqualToString:@"0"]) {
            [categoryText appendString:[result objectForKey:@"age"]];
        }
        if (![categoryText isEqualToString:@""]) {
            // show separator dot if there is a city or a state in the location
            BOOL showSeparator = false;
            if ([[result objectForKey:@"city"] isKindOfClass:[NSString class]]) {
                if (![[result objectForKey:@"city"] isEqualToString:@""]) {
                    showSeparator = true;
                }
            }
            if ([[result objectForKey:@"state"] isKindOfClass:[NSString class]]) {
                if (![[result objectForKey:@"state"] isEqualToString:@""]) {
                    showSeparator = true;
                }
            }
            if (showSeparator) {
                [categoryText appendString:@" • "];
            }
        }
        if (![[result objectForKey:@"city"] isEqual:[NSNull null]]) {
            [categoryText appendString:[NSString stringWithFormat:@"%@ ",[result objectForKey:@"city"]]];
        }
        if (![[result objectForKey:@"state"] isEqual:[NSNull null]]) {
            [categoryText appendString:[result objectForKey:@"state"]];
        }
        if (![[participant objectForKey:@"photo"] isEqual:[NSNull null]]) {
            [categoryText appendString:@" • "];
        }
        
        UILabel* categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(44,20,220,21)];
        categoryLabel.text = categoryText;
        categoryLabel.font = [UIFont systemFontOfSize:13];
        categoryLabel.textColor = [UIColor lightGrayColor];
        categoryLabel.highlightedTextColor = [UIColor whiteColor];
    

        UILabel* timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(232,0,76,43)];
        timeLabel.text = [result objectForKey:@"time"];
        timeLabel.textAlignment = UITextAlignmentRight;
        timeLabel.highlightedTextColor = [UIColor whiteColor];


        
        
        
        [cell addSubview:placeLabel];
        [cell addSubview:nameLabel];
        [cell addSubview:categoryLabel];
        [cell addSubview:timeLabel];   

        
        if (![[participant objectForKey:@"photo"] isEqual:[NSNull null]]) {
            
            // add photo icon
            
            CGSize lineTwoSize = [categoryText sizeWithFont:categoryLabel.font constrainedToSize:CGSizeMake(320, 20) lineBreakMode:categoryLabel.lineBreakMode];
            
            
            UIImage *photoImg = [UIImage imageNamed:@"photo.png"];
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake((lineTwoSize.width+46),27,7,9)];
            imgView.alpha = 0.5;
            imgView.image = photoImg;
            
            [cell addSubview:imgView];
            
        }
        
        
        [categoryText release];
        [placeLabel release];
        [nameLabel release];
        [categoryLabel release];
        [timeLabel release];
    
    }
    
    return cell;
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[[tv cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:@"ResultCell"]) {

        NSDictionary* result = (NSDictionary*)[self.filteredResultsArray objectAtIndex:[indexPath row]];
        NSDictionary* participant = (NSDictionary*)[result objectForKey:@"Participant"];
        
        PersonViewController *personViewController = [[PersonViewController alloc] 
                                                        initWithNibName:@"PersonViewController" 
                                                        withParticipant:participant
                                                        bundle:nil];
        
        // Pass the selected object to the new view controller.
        [self.navigationController pushViewController:personViewController animated:YES];
        [personViewController release];

    }
}


#pragma mark - ASIHTTPRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{      
    if ([request didUseCachedResponse]) {
        NSLog(@"Cache used!");
    } else {
        NSLog(@"Cache NOT used!");
    }
    
    
    NSString* response = [request responseString];
    
    // parse JSON string into NSDictionary
    SBJsonParser *json = [[SBJsonParser new] autorelease];
    NSError *jsonError = nil;
    NSDictionary *parsedJSON = [json objectWithString:response error:&jsonError];
    
    if (jsonError) {
        NSLog(@"%@",[jsonError description]);
    }
    
    NSMutableArray *data = [parsedJSON objectForKey:@"d"];
    
    self.resultsArray = data;
    self.filteredResultsArray = [NSMutableArray arrayWithArray:data];
    
    [self performSelectorOnMainThread:@selector(reloadTableData) 
                           withObject:nil 
                        waitUntilDone:NO];  
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSLog(@"request failed: %@", [error localizedDescription]);
    
    // set results to an empty array
    self.resultsArray = [NSMutableArray arrayWithCapacity:0];
    self.filteredResultsArray = [NSMutableArray arrayWithCapacity:0];
    
    [self performSelectorOnMainThread:@selector(reloadTableData) 
                           withObject:nil 
                        waitUntilDone:NO]; 
    
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
