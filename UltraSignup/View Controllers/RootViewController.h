//
//  RootViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 7/7/11.
//  Copyright 2011. All rights reserved.
//

@interface RootViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate, CLLocationManagerDelegate> 
{
    
    IBOutlet UISearchDisplayController* _searchController;
    IBOutlet UITableView* _tableView; 
    
    NSMutableArray* _eventDatesArray;  // stores eventDates to show on home page
    NSMutableArray* _localEventDatesArray;  // stores eventDates close to user's location
    NSMutableArray* _newsArray;
    
    ASIHTTPRequest *activeRequest;  // save reference to request so we can cancel if user leaves view before it completes

    CLLocationManager *locationManager; 
    CLLocation *location;
    
    BOOL isUsingDeviceSimulator;

}

@property (nonatomic, retain) IBOutlet UITableView *tableView;

@property (nonatomic, retain) NSMutableArray *eventDatesArray;
@property (nonatomic, retain) NSMutableArray *localEventDatesArray;
@property (nonatomic, retain) NSMutableArray *newsArray;

@property (nonatomic, retain) ASIHTTPRequest *activeRequest;

@property (nonatomic, retain) CLLocation *location;

- (void)updateLocalEventDatesArray;
- (void)showSearchViewController;

@end
