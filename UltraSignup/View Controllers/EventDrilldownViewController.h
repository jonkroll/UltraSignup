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
    NSMutableArray *eventDatesOrDistancesArray;
    
    NSString *_eventName;
}

@property (nonatomic, retain) NSString *eventName;

- (id)initWithStyle:(UITableViewStyle)style withEventDistances:(NSMutableArray*)eventDistances;
- (id)initWithStyle:(UITableViewStyle)style withEventDates:(NSMutableArray*)eventDates;

@end