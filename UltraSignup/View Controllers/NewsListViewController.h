//
//  NewsListViewController.h
//  UltraSignup
//
//  Created by Jon Kroll on 1/1/12.
//  Copyright (c) 2012. All rights reserved.
//

@interface NewsListViewController : UITableViewController
{
    NSMutableArray *_newsArray;    
}

@property (nonatomic, retain) NSMutableArray *newsArray;

- (id)initWithNewsArray:(NSMutableArray*)newsArray;

@end
