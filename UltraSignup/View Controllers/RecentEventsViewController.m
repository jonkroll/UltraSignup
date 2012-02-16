//
//  RecentEventsViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 9/11/11.
//  Copyright 2011. All rights reserved.
//

#import "EventDrilldownViewController.h"
#import "RecentEventsViewController.h"
#import "ResultsViewController.h"
#import "SBJson.h"
#import "NSDate+UltraSignup.h"
#import "Settings.h"

@implementation RecentEventsViewController

@synthesize recentEvents = _recentEvents;

- (id)initWithRecentEvents:(NSMutableArray*)recentEvents
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _recentEvents = recentEvents;
        [_recentEvents retain];        
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:@"Recent Events"];
    self.navigationItem.titleView = myLabel;
    [myLabel release];
    
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
    return [[self recentEvents] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
 
    NSDictionary* eventDate = [[self recentEvents] objectAtIndex:[indexPath row]];   
    NSDictionary* event = (NSDictionary*)[eventDate objectForKey:@"vwMobileEvent"];
    
    cell.textLabel.text = [event objectForKey:@"name"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, YYYY"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ • %@", 
                                        [event objectForKey:@"city"], 
                                        [event objectForKey:@"state"], 
                                 [dateFormatter stringFromDate:[NSDate dateFromJSONString:[eventDate objectForKey:@"event_date"]]]];
    [dateFormatter release];
    
    return cell;
}
    

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* eventDate;
    NSDictionary* event;

    
    eventDate = (NSDictionary*)[[self recentEvents] objectAtIndex:[indexPath row]];
    event = (NSDictionary*)[eventDate objectForKey:@"vwMobileEvent"];
    
    NSMutableArray* eventDistances = [eventDate objectForKey:@"vwMobileEventDistances"];
    if ([eventDistances count] == 1) {
        
        NSDictionary* eventDist = (NSDictionary*)[eventDistances objectAtIndex:0];
        UIViewController* resultsViewController = [[ResultsViewController alloc] 
                                                   initWithNibName:@"ResultsViewController"
                                                   withEventDistance:eventDist 
                                                   bundle:nil];
        
        [self.navigationController pushViewController:resultsViewController 
                                             animated:YES];
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
    
}

@end
