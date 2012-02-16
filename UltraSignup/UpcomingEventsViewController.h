//
//  UpcomingEventsViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 1/21/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UpcomingEventsViewController : UITableViewController
{
    NSMutableArray* _upcomingEvents;  
    NSDictionary* _person;
}

@property (nonatomic, retain) NSMutableArray* upcomingEvents;
@property (nonatomic, retain) NSDictionary* person;

- (id)initWithUpcomingEvents:(NSMutableArray*)upcomingEvents forPerson:(NSDictionary*)person;

@end
