//
//  EventViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 7/4/11.
//  Copyright 2011. All rights reserved.
//

#import "ASIHTTPRequest.h"

@interface EventViewController : UITableViewController <UIWebViewDelegate> {

    NSDictionary *_event;
    UIImage *eventImage;
    NSMutableArray *eventDatesArray;  // remove this
    
    NSDictionary *upcomingDate;
    NSDictionary *latestDate;
    NSArray *previousDates;

    BOOL hasMap;
    BOOL hasWebsite;
    
    ASIHTTPRequest *activeRequest;  // save reference to request so we can cancel if user leaves view before it completes

}

@property (nonatomic, retain) NSDictionary *event;
@property (nonatomic, retain) UIImage *eventImage;
@property (nonatomic, retain) NSMutableArray *eventDatesArray;

@property (nonatomic, retain) NSDictionary *upcomingDate;
@property (nonatomic, retain) NSDictionary *latestDate;
@property (nonatomic, retain) NSArray *previousDates;

@property (nonatomic, retain) ASIHTTPRequest *activeRequest;

- (id)initWithNibName:(NSString *)nibNameOrNil 
      withEvent:(NSDictionary *)event 
               bundle:(NSBundle *)nibBundleOrNil;

- (void)loadResults;
- (void)showMap;
//- (void)highlightMap;

@end
