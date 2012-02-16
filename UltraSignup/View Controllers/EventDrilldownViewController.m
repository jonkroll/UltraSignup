//
//  EventDrilldownViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 8/19/11.
//  Copyright 2011. All rights reserved.
//

#import "EventDrilldownViewController.h"
#import "ResultsViewController.h"
#import "SearchViewController.h"
#import "NSDate+UltraSignup.h"

@implementation EventDrilldownViewController

@synthesize eventName;

- (id)initWithStyle:(UITableViewStyle)style withEventDistances:(NSMutableArray*)eventDistances
{
    self = [super initWithStyle:style];
    if (self) {
        drilldownType = EVENT_DRILLDOWN_DISTANCES;
        eventDatesOrDistancesArray = eventDistances;
        [eventDatesOrDistancesArray retain];
        
        //self.navigationItem.prompt = @"Hello World";
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style withEventDates:(NSMutableArray*)eventDates
{
    self = [super initWithStyle:style];
    if (self) {
        drilldownType = EVENT_DRILLDOWN_DATES;
        eventDatesOrDistancesArray = eventDates;
        [eventDatesOrDistancesArray retain];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:238.0 / 255 green:238.0 / 255 blue:238.0 / 255 alpha:1.0];

    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:self.eventName];
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
    segmentedControl.momentary = NO;
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
    return [eventDatesOrDistancesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    switch (drilldownType) {
        case EVENT_DRILLDOWN_DATES : 
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MMM d, YYYY"];            
            NSDictionary* eventDate = [eventDatesOrDistancesArray objectAtIndex:[indexPath row]];
            cell.textLabel.text = [dateFormatter stringFromDate:[NSDate dateFromJSONString:[eventDate objectForKey:@"event_date"]]];
            [dateFormatter release];
            break;
        }
        case EVENT_DRILLDOWN_DISTANCES :
        {
            NSDictionary* eventDist = [eventDatesOrDistancesArray objectAtIndex:[indexPath row]];
            cell.textLabel.text = [eventDist objectForKey:@"distance"];
            break;
        }
    }
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = @"";
    switch (drilldownType) {
        case EVENT_DRILLDOWN_DATES :      title = @"Dates";     break; 
        case EVENT_DRILLDOWN_DISTANCES :  title = @"Distances"; break; 
    }
    return title;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController* vc;
    
    switch (drilldownType) {
        case EVENT_DRILLDOWN_DATES : 
        {
            
            NSDictionary* eventDate = (NSDictionary*)[eventDatesOrDistancesArray objectAtIndex:[indexPath row]];
            NSMutableArray* eventDistances = (NSMutableArray*)[eventDate objectForKey:@"vwMobileEventDistances"];

            if ([eventDistances count] == 1) {
                NSDictionary *eventDist = (NSDictionary*)[eventDistances objectAtIndex:0];
                vc = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController"
                                                  withEventDistance:eventDist 
                                                             bundle:nil];  
            } else {

                // need to go to drilldown controller to pick a distance                
                vc = [[EventDrilldownViewController alloc] initWithStyle:UITableViewStyleGrouped 
                                                      withEventDistances:[eventDate objectForKey:@"vwMobileEventDistances"] ];
                [(EventDrilldownViewController*)vc setEventName:self.eventName];
            }
            break;
        }
        case EVENT_DRILLDOWN_DISTANCES :
        {
            NSDictionary* eventDist = (NSDictionary*)[eventDatesOrDistancesArray objectAtIndex:[indexPath row]];
            vc = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController"
                                              withEventDistance:eventDist 
                                                         bundle:nil]; 
            }
            break;
    }
    
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];

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
