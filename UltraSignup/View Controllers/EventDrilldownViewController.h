//
//  EventDrilldownViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 8/19/11.
//  Copyright 2011. All rights reserved.
//

enum DRILLDOWN_TYPE
{
    EVENT_DRILLDOWN_DATES,
    EVENT_DRILLDOWN_DISTANCES
}; 

@interface EventDrilldownViewController : UITableViewController
{
    enum DRILLDOWN_TYPE drilldownType;
    NSString *_eventName;
    NSArray *_eventDatesOrDistancesArray;    
}

@property (nonatomic, retain) NSString *eventName;
@property (nonatomic, retain) NSArray *eventDatesOrDistancesArray;

- (id)initWithStyle:(UITableViewStyle)style withEventDistances:(NSArray*)eventDistances;
- (id)initWithStyle:(UITableViewStyle)style withEventDates:(NSArray*)eventDates;

@end