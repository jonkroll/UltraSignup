//
//  ResultsViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 7/3/11.
//  Copyright 2011. All rights reserved.
//

#import "ASIHTTPRequest.h"

@interface ResultsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ASIHTTPRequestDelegate> 

@property (nonatomic, retain) IBOutlet UIView               *eventDistanceMasthead;
@property (nonatomic, retain) IBOutlet UIButton             *masthead;
@property (nonatomic, retain) IBOutlet UILabel              *labelEventName;
@property (nonatomic, retain) IBOutlet UILabel              *labelEventLocation;
@property (nonatomic, retain) IBOutlet UILabel              *labelEventDateDistance;
@property (nonatomic, retain) IBOutlet UITableView          *tableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl   *resultsFilter;

@property (nonatomic, retain) NSDictionary          *eventDistance;
@property (nonatomic, retain) NSMutableArray        *resultsArray;
@property (nonatomic, retain) NSMutableArray        *filteredResultsArray;

@property (nonatomic, retain) ASIHTTPRequest        *activeRequest;


- (id)initWithNibName:(NSString *)nibNameOrNil 
    withEventDistance:(NSDictionary *)eventDistance 
               bundle:(NSBundle *)nibBundleOrNil;

- (void)loadResults;

- (void)reloadTableData;

- (IBAction)goToEventView:(id)sender;

@end

