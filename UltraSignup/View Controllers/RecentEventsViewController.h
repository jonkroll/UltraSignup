//
//  RecentEventsViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 9/11/11.
//  Copyright 2011. All rights reserved.
//

#import "ASIHTTPRequest.h"

@interface RecentEventsViewController : UITableViewController
{
    NSMutableArray* _recentEvents;    
}

@property (nonatomic, retain) NSMutableArray* recentEvents;

- (id)initWithRecentEvents:(NSMutableArray*)recentEvents;

@end