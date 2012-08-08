//
//  SearchViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 1/17/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ASIHTTPRequest.h"

@interface SearchViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>
{
    NSMutableArray *_tempSearchData;
    NSMutableArray *_searchData;
        
    ASIHTTPRequest *activePersonRequest;
    ASIHTTPRequest *activeEventRequest;

    int displayRequestTag;
}


@property (nonatomic, retain) NSMutableArray *tempSearchData;
@property (nonatomic, retain) NSMutableArray *searchData;

@property (nonatomic, retain) ASIHTTPRequest *activePersonRequest;
@property (nonatomic, retain) ASIHTTPRequest *activeEventRequest;


- (void)startSearch:(UISearchBar *)searchBar;

@end
