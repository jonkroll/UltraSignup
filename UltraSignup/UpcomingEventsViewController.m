//
//  UpcomingEventsViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 1/21/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "UpcomingEventsViewController.h"
#import "EventViewController.h"
#import "SearchViewController.h"
#import "NSDate+UltraSignup.h"


@implementation UpcomingEventsViewController

@synthesize upcomingEvents = _upcomingEvents;
@synthesize person = _person;

- (id)initWithUpcomingEvents:(NSMutableArray *)upcomingEvents forPerson:(NSDictionary *)person
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _upcomingEvents = upcomingEvents;
        [_upcomingEvents retain];        
        _person = person;
        [_person retain];      
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:238.0 / 255 green:238.0 / 255 blue:238.0 / 255 alpha:1.0];
    
    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:@"Upcoming Events"];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
     return [self.upcomingEvents count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%@ %@'s Upcoming Events", 
            [self.person objectForKey:@"first_name"],
             [self.person objectForKey:@"last_name"]];
             
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                       reuseIdentifier:CellIdentifier] autorelease];
    }

    NSDictionary* theresult = [self.upcomingEvents objectAtIndex:indexPath.row];
    NSDictionary* eventDist = (NSDictionary*)[theresult objectForKey:@"EventDistance"];
    NSDictionary* eventDate = (NSDictionary*)[eventDist objectForKey:@"vwMobileEventDate"];
    NSDictionary* event     = (NSDictionary*)[eventDate objectForKey:@"vwMobileEvent"];

    
    // event name
    UILabel *eventName = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, 280, 20)];
    eventName.numberOfLines = 1;
    eventName.lineBreakMode = UILineBreakModeTailTruncation;
    eventName.text = [NSString stringWithFormat:@"%@ %@", [event objectForKey:@"name"], [eventDist objectForKey:@"distance"]];        
    eventName.font = [UIFont boldSystemFontOfSize:16];
    eventName.highlightedTextColor = [UIColor whiteColor];
    eventName.backgroundColor = [UIColor clearColor];
    eventName.tag = 1;
    
    
    // event location
    NSString* city = @"";
    if (![[event objectForKey:@"city"] isEqual:[NSNull null]]) {
        city = [NSString stringWithFormat:@"%@ ", [event objectForKey:@"city"]];
    }
    NSString* state = @"";
    if (![[event objectForKey:@"state"] isEqual:[NSNull null]]) {
        state = [NSString stringWithFormat:@"%@", [event objectForKey:@"state"]];
    }
    UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 22, 280, 20)];
    locationLabel.numberOfLines = 1;
    locationLabel.lineBreakMode = UILineBreakModeWordWrap;
    locationLabel.text = [NSString stringWithFormat:@"%@%@", city, state];
    locationLabel.textColor = [UIColor grayColor];
    locationLabel.font = [UIFont systemFontOfSize:14];
    locationLabel.highlightedTextColor = [UIColor whiteColor];
    locationLabel.backgroundColor = [UIColor clearColor];
    locationLabel.tag = 2;
    
    // event date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, YYYY"];
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 280, 20)];
    dateLabel.numberOfLines = 1;
    dateLabel.lineBreakMode = UILineBreakModeWordWrap;
    dateLabel.text = [dateFormatter stringFromDate:[NSDate dateFromJSONString:[eventDate objectForKey:@"event_date"]]];
    dateLabel.font = [UIFont systemFontOfSize:14];
    dateLabel.textColor = [UIColor grayColor];
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.backgroundColor = [UIColor clearColor];
    dateLabel.tag = 3;
    [dateFormatter release];   
    
    
    // add subviews
    [[cell contentView] addSubview:eventName];
    [[cell contentView] addSubview:dateLabel];
    [[cell contentView] addSubview:locationLabel];

    // cleanup
    [eventName release];
    [dateLabel release];
    [locationLabel release];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary* theresult = [self.upcomingEvents objectAtIndex:indexPath.row];
    NSDictionary* eventDist = (NSDictionary*)[theresult objectForKey:@"EventDistance"];
    NSDictionary* eventDate = (NSDictionary*)[eventDist objectForKey:@"vwMobileEventDate"];
    NSDictionary* event     = (NSDictionary*)[eventDate objectForKey:@"vwMobileEvent"];

    
    EventViewController *eventViewController = [[EventViewController alloc] 
                                                initWithNibName:@"PersonViewController"  
                                                withEvent:event
                                                bundle:nil];
    
    [self.navigationController pushViewController:eventViewController animated:YES];
    [eventViewController release];

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
