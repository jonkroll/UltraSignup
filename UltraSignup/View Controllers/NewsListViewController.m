//
//  NewsListViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 1/1/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "NewsListViewController.h"
#import "NewsViewController.h"
#import "NewsItem.h"

@implementation NewsListViewController

@synthesize newsArray = _newsArray;

- (id)initWithNewsArray:(NSMutableArray *)newsArray 
{
    self = [super init];
    if (self) {
        self.newsArray = newsArray;
        [newsArray retain];
        
    }
    return self;
}


#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:@"News"];
    self.navigationItem.titleView = myLabel;
    [myLabel release];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.newsArray.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* CellIdentifier = @"NewsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:CellIdentifier] autorelease];
    } else {
        // remove old values from cell
        // if we were were using a Nib file for the cell layout we wouldn't need to do this
        for (UIView *view in [cell subviews]) {
            if ([view isMemberOfClass:[UILabel class]]) { 
                [view removeFromSuperview];
            }
        }
        cell.textLabel.text = @"";
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE, MMM d, yyyy"]; 
    
    NewsItem *newsItem = [self.newsArray objectAtIndex:[indexPath row]];
    
    UILabel* headlineLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,4,240, 44)];
    headlineLabel.textAlignment = UITextAlignmentLeft;
    headlineLabel.text = [NSString stringWithFormat:@"%@", newsItem.title];
    headlineLabel.highlightedTextColor = [UIColor whiteColor];
    headlineLabel.backgroundColor = [UIColor clearColor];
    headlineLabel.font = [UIFont boldSystemFontOfSize:16];
    headlineLabel.numberOfLines = 2;
    
    UILabel* dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,44,240,22)];
    dateLabel.text = [dateFormatter stringFromDate:newsItem.date];    
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.font = [UIFont systemFontOfSize:14];
    dateLabel.backgroundColor = [UIColor clearColor];
    dateLabel.textColor = [UIColor grayColor];
    
    
    [cell addSubview:headlineLabel];
    [cell addSubview:dateLabel];
    
    
    [headlineLabel release];
    [dateLabel release];
    [dateFormatter release];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewsItem *newsItem = [self.newsArray objectAtIndex:[indexPath row]];
    
    NewsViewController *detailViewController = [[NewsViewController alloc] initWithNewsItem:newsItem];
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
}

@end
