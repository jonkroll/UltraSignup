//
//  PersonViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 7/4/11.
//  Copyright 2011. All rights reserved.
//

#import "ASIHTTPRequest.h"

@interface PersonViewController : UITableViewController {

    NSDictionary *participant;
    NSMutableArray *personResultsArray;
    NSMutableArray *registrationsArray;
    UIImage *personImage;

    ASIHTTPRequest *activeRequest;  // save reference to request so we can cancel if user leaves view before it completes

}

@property (nonatomic, retain) NSDictionary *participant;
@property (nonatomic, retain) NSMutableArray *personResultsArray;
@property (nonatomic, retain) NSMutableArray *registrationsArray;
@property (nonatomic, retain) UIImage *personImage;

@property (nonatomic, retain) ASIHTTPRequest *activeRequest;

- (id)initWithNibName:(NSString *)nibNameOrNil 
      withParticipant:(NSDictionary *)result 
               bundle:(NSBundle *)nibBundleOrNil;

- (void)loadResults;

@end
