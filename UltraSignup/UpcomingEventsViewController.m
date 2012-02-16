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
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [event objectForKey:@"name"], [eventDist objectForKey:@"distance"]];
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, YYYY"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ • %@", 
                                            [event objectForKey:@"city"], 
                                            [event objectForKey:@"state"], 
                                            [dateFormatter stringFromDate:[NSDate dateFromJSONString:[eventDate objectForKey:@"event_date"]]]];
    [dateFormatter release];
    
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
