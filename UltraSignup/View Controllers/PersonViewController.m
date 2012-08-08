//
//  PersonViewController.m
//  UltraSignup
//
//  Created by Jon Kroll on 7/4/11.
//  Copyright 2011. All rights reserved.
//

#import "Settings.h"
#import "PersonViewController.h"
#import "ResultsViewController.h"
#import "ASIHTTPRequest.h"
#import "SBJson.h"
#import "NSDate+UltraSignup.h"
#import "SearchViewController.h"
#import "UpcomingEventsViewController.h"


@implementation PersonViewController

@synthesize participant;
@synthesize personResultsArray;
@synthesize registrationsArray;
@synthesize personImage;

@synthesize activeRequest;

- (id)initWithNibName:(NSString *)nibNameOrNil 
      withParticipant:(NSDictionary*)theRunner 
               bundle:(NSBundle *)nibBundleOrNil;
{
    self = [super initWithNibName:nibNameOrNil 
                           bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        participant = theRunner;
        [participant retain];
        
        if (![[participant objectForKey:@"photo"] isEqual:[NSNull null]]) {
            
            NSString *photoURLString = [[NSString stringWithFormat:@"http://img.ultrasignup.com/%@.jpg",[participant objectForKey:@"photo"]] lowercaseString];
            
            //fetch photo
            NSURL *url = [NSURL URLWithString:photoURLString];
            
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

            //[request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy];
            [request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
            [request setSecondsToCache:60*60*24*30]; // Cache for 30 days
            [request setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy]; // save search between sessions
            
            [request setTag:REQUEST_TYPE_IMAGE];
            [request setDelegate:self];
            [request startAsynchronous];
        }

    }
    return self;    
}

- (void)dealloc
{
    [activeRequest clearDelegatesAndCancel];
    [activeRequest release];

    [super dealloc];
}

- (IBAction)showPhoto:(id)sender 
{    
    // push new UIImageView onto Navigation Controller stack

    UIViewController *photoViewController = [[UIViewController alloc] init];
    
    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:[NSString stringWithFormat:@"%@ %@", [participant objectForKey:@"first_name"], [participant objectForKey:@"last_name"]]];
    photoViewController.navigationItem.titleView = myLabel;
    [myLabel release];
    

    UIImage *fullImg = [[(UIButton*)sender backgroundImageForState:UIControlStateNormal] copy];    
    int imgFrameOriginX = ((320 - fullImg.size.width) /2) - 10;
    int imgFrameOriginY = ((480 - 80 - fullImg.size.height) /2) - 10; 
    
    UIImageView *fullImgView = [[UIImageView alloc] initWithFrame:CGRectMake(imgFrameOriginX, imgFrameOriginY, 
                                                                            fullImg.size.width + 20, fullImg.size.height + 20)];
    fullImgView.image = fullImg;
    fullImgView.backgroundColor = [UIColor whiteColor];
    fullImgView.contentMode = UIViewContentModeCenter;
    
    fullImgView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    fullImgView.layer.borderWidth = 1.0;
    fullImgView.layer.cornerRadius = 5.0;
    fullImgView.layer.masksToBounds = YES;
    fullImgView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    fullImgView.layer.shadowColor = [UIColor grayColor].CGColor;
    fullImgView.layer.shadowOpacity = 0.8;
    fullImgView.layer.shadowRadius = 1.0;
    
    fullImgView.clipsToBounds = NO;

    photoViewController.view.backgroundColor = [UIColor colorWithRed:223.0 / 255 green:223.0 / 255 blue:223.0 / 255 alpha:1.0];
    [photoViewController.view addSubview:fullImgView];
    
    [self.navigationController pushViewController:photoViewController animated:YES];
    
    [fullImg release];
    [fullImgView release];
    [photoViewController release];
    
}


- (NSString*) formatPlaceString:(NSString*)place {
    
    NSString* suffix;
    
    NSInteger onesPlace = [place intValue] % 10;
    NSInteger tensAndOnesPlaces = [place intValue] % 100;
    
    switch (onesPlace) {
        case 1:  suffix = @"st"; break;
        case 2:  suffix = @"nd"; break;
        case 3:  suffix = @"rd"; break;
        default: suffix = @"th"; break;
    }
    
    if (tensAndOnesPlaces > 10 && tensAndOnesPlaces < 20) {
        // special case - all teens end in "th"
        suffix = @"th";
    }
    
    return [NSString stringWithFormat:@"%@%@",place,suffix];
    
}

- (void)loadResults
{
    // TODO: show upcoming events a runner has registered for
    
    
    // get all results for this participant
    //   also exclude results where the Event info is null (I don't why how this happens, but it does)
    NSString* urlString = [NSString stringWithFormat:@"%@/Results?$filter=participant_id%%20eq%%20%@%%20and%%20EventDistance/vwMobileEventDate/vwMobileEvent%%20ne%%20null&$expand=EventDistance/vwMobileEventDate/vwMobileEvent&$orderby=EventDistance/vwMobileEventDate/event_date%%20desc&$top=100&$format=json",
                           kUltraSignupMobileServiceURI,
                           [[participant objectForKey:@"participant_id"] stringValue]
                           ];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
    
    //[req setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy];
    [req setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [req setSecondsToCache:60*60*24*30]; // Cache for 30 days
    [req setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy]; // save search between sessions
    
    [req setTag:REQUEST_TYPE_RESULTS];
    [req setDelegate:self];
    [req startAsynchronous];
    
    self.activeRequest = req;    
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
         
    // set title for View
    JKBorderedLabel *myLabel = [[JKBorderedLabel alloc] initWithString:[NSString stringWithFormat:@"%@ %@", [participant objectForKey:@"first_name"], [participant objectForKey:@"last_name"]]];
    self.navigationItem.titleView = myLabel;
    [myLabel release];
    
    // add multi-button to upper right                            
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:@"UIButtonBarSearch.png"],
											 [UIImage imageNamed:@"UIButtonBarHome.png"],
											 nil]];
    segmentedControl.frame = CGRectMake(0, 0, 90, 30);
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.momentary = YES;
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];    
    self.navigationItem.rightBarButtonItem = segmentBarItem;
    [segmentedControl release];
    [segmentBarItem release];
    
    [self loadResults];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            if (!self.registrationsArray || [self.registrationsArray count] == 0)
            {
                return 1;
            } else {
                
                return 2;
            }

            break;
        case 1:

            // number of events the person has done
            if ([self.personResultsArray count] == 0)
            {
                return 1;
            } else {
                
                return [self.personResultsArray count];
            }
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell;
    
    // Configure the cell...
    if ([indexPath section] == 0) {

        if ([indexPath row] == 0) {
            static NSString *CellIdentifier = @"RunnerDetailCell";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier] autorelease];
            }

     
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

            // participant name
            int nameWidth = 280;
            if (![[participant objectForKey:@"photo"] isEqual:[NSNull null]]) {
                nameWidth = nameWidth - 100;
            }        
            
            UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, nameWidth, 20)];
            labelName.numberOfLines = 1;
            labelName.text = [NSString stringWithFormat:@"%@ %@", [participant objectForKey:@"first_name"], [participant objectForKey:@"last_name"]];        
            labelName.font = [UIFont boldSystemFontOfSize:16];
            labelName.backgroundColor = [UIColor clearColor];
            labelName.lineBreakMode = UILineBreakModeTailTruncation;
            labelName.tag = 1;
            
            
            // line with runner info (age, gender, etc)
            NSString* age = @"";
            if ([participant objectForKey:@"current_age"] != nil && [participant objectForKey:@"current_age"] != 0) {
                age = [NSString stringWithFormat:@"%@",[participant objectForKey:@"current_age"]];
            }
            UILabel *labelGroup = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 180, 20)];
            labelGroup.numberOfLines = 1;
            labelGroup.textColor = [UIColor grayColor];
            labelGroup.font = [UIFont systemFontOfSize:14];
            labelGroup.lineBreakMode = UILineBreakModeWordWrap;
            labelGroup.text = [NSString stringWithFormat:@"%@%@", [participant objectForKey:@"gender"], age];
            labelGroup.backgroundColor = [UIColor clearColor];
            labelGroup.tag = 2;
            
            
            // location
            NSString* city = @"";
            if (![[participant objectForKey:@"city"] isEqual:[NSNull null]]) {
                city = [NSString stringWithFormat:@"%@ ", [participant objectForKey:@"city"]];
            }
            NSString* state = @"";
            if (![[participant objectForKey:@"state"] isEqual:[NSNull null]]) {
                state = [NSString stringWithFormat:@"%@", [participant objectForKey:@"state"]];
            }
            UILabel *labelLocation = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, 180, 20)];
            labelLocation.numberOfLines = 1;
            labelLocation.textColor = [UIColor grayColor];
            labelLocation.font = [UIFont systemFontOfSize:14];
            labelLocation.lineBreakMode = UILineBreakModeTailTruncation;
            labelLocation.text = [NSString stringWithFormat:@"%@%@", city, state];
            labelLocation.backgroundColor = [UIColor clearColor];
            labelLocation.tag = 3;
            
            
            // runner rank
            UILabel *labelRank = [[UILabel alloc] initWithFrame:CGRectMake(10, 70, 180, 20)];
            labelRank.numberOfLines = 1;
            labelRank.textColor = [UIColor grayColor];
            labelRank.font = [UIFont systemFontOfSize:14];
            labelRank.lineBreakMode = UILineBreakModeWordWrap;
            NSString *stringRank = [participant objectForKey:@"runner_rank"];
            if (![stringRank isEqual:[NSNull null]]) {
                float rank = [stringRank floatValue] * 100;
                labelRank.text = [NSString stringWithFormat:@"Runner Rank %.02f%%", rank];
            } else {
                labelRank.text = [NSString stringWithFormat:@"Runner Rank Unknown"];            
            }
            labelRank.backgroundColor = [UIColor clearColor];
            labelRank.tag = 4;

        
     
            // add subviews
            [[cell contentView] addSubview:labelName];
            [[cell contentView] addSubview:labelGroup];
            [[cell contentView] addSubview:labelLocation];
            [[cell contentView] addSubview:labelRank];

            
            if (self.personImage == nil && ![[participant objectForKey:@"photo"] isEqual:[NSNull null]]) {
                
                // show spinner while we download image
                UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(230, 20, 20, 20)];
                [[cell contentView] addSubview:spinner];
                [spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray]; 
                [spinner startAnimating];
                [spinner setTag:5];
                [spinner release];

                UILabel *labelImgLoading = [[UILabel alloc] initWithFrame:CGRectMake(190, 40, 100, 40)];
                labelImgLoading.numberOfLines = 2;
                labelImgLoading.textColor = [UIColor grayColor];
                labelImgLoading.font = [UIFont systemFontOfSize:12];
                labelImgLoading.textAlignment = UITextAlignmentCenter;
                labelImgLoading.text = @"Loading\nImage...";
                labelImgLoading.backgroundColor = [UIColor clearColor];
                labelImgLoading.tag = 6;
                [[cell contentView] addSubview:labelImgLoading];
                [labelImgLoading release];
            
            }
            
            // cleanup
            [labelName release];
            [labelGroup release];        
            [labelLocation release];
            [labelRank release];

            // note: will add image later after it loads (asynchronously)        
        
        } else {
            
            // show cell for registered upcoming events
            
            static NSString *CellIdentifier = @"UpcomingEventsCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier] autorelease];
            } 

            NSString *upcomingEventsText;
            switch ([self.registrationsArray count]) {
                case 0: upcomingEventsText = @"No Upcoming Events"; break; // this won't ever be used
                case 1: upcomingEventsText = @"1 Upcoming Event"; break;
                default: upcomingEventsText = [NSString stringWithFormat:@"%d Upcoming Events", [self.registrationsArray count]]; break;
            }
            
            cell.textLabel.text = upcomingEventsText;
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

        }
            
    } else {

        if (personResultsArray == nil) {

            static NSString *CellIdentifier = @"SpinnerCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier] autorelease];
            } 

            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(60, 16, 28, 28)]; 
            [activityIndicator startAnimating]; 
            [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray]; 
            [[cell contentView] addSubview:activityIndicator]; 
            [activityIndicator release]; 
            
            UILabel *loadingText = [[UILabel alloc] initWithFrame:CGRectMake(100, 18, 140, 20)];
            loadingText.text = @"Loading Events...";
            loadingText.backgroundColor = [UIColor clearColor];
            [[cell contentView] addSubview:loadingText];
            [cell.textLabel setFont:[UIFont systemFontOfSize:20]];
            [loadingText release];                        
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
        } else if ([personResultsArray count] == 0) {
            
            static NSString *CellIdentifier = @"NoRunnerResultCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier] autorelease];
            } 
            
            cell.textLabel.text = @"No Races";
            [cell.textLabel setFont:[UIFont systemFontOfSize:20]];
            [cell.textLabel setTextColor:[UIColor grayColor]];
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

            
        } else {
        
            NSDictionary* theresult = [personResultsArray objectAtIndex:indexPath.row];
            static NSString *CellIdentifier = @"RunnerResultCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier] autorelease];
            } else {
                // remove old values from cell
                // if we were were using a Nib file for the cell layout we wouldn't need to do this
                for (UIView *view in [[cell contentView] subviews]) {
                    if ([view isMemberOfClass:[UILabel class]]) { 
                        [view removeFromSuperview];
                    }
                }

            }

            
            NSDictionary* eventDist = (NSDictionary*)[theresult objectForKey:@"EventDistance"];
            NSDictionary* eventDate = (NSDictionary*)[eventDist objectForKey:@"vwMobileEventDate"];
            NSDictionary* event     = (NSDictionary*)[eventDate objectForKey:@"vwMobileEvent"];
                
            // event name
            UILabel *eventName = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, 210, 20)];
            eventName.numberOfLines = 1;
            eventName.lineBreakMode = UILineBreakModeTailTruncation;
            eventName.text = [NSString stringWithFormat:@"%@ %@", [event objectForKey:@"name"], [eventDist objectForKey:@"distance"]];        
            eventName.font = [UIFont boldSystemFontOfSize:16];
            eventName.highlightedTextColor = [UIColor whiteColor];
            eventName.backgroundColor = [UIColor clearColor];
            eventName.tag = 1;

            
            // event location
            NSString* city = @"";
            if (![[event objectForKey:@"city"] isEqual:[NSNull null]]) {
                city = [NSString stringWithFormat:@"%@ ", [event objectForKey:@"city"]];
            }
            NSString* state = @"";
            if (![[event objectForKey:@"state"] isEqual:[NSNull null]]) {
                state = [NSString stringWithFormat:@"%@", [event objectForKey:@"state"]];
            }
            UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 22, 210, 20)];
            locationLabel.numberOfLines = 1;
            locationLabel.lineBreakMode = UILineBreakModeWordWrap;
            locationLabel.text = [NSString stringWithFormat:@"%@%@", city, state];
            locationLabel.textColor = [UIColor grayColor];
            locationLabel.font = [UIFont systemFontOfSize:14];
            locationLabel.highlightedTextColor = [UIColor whiteColor];
            locationLabel.backgroundColor = [UIColor clearColor];
            locationLabel.tag = 2;
            
            // event date
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MMM d, YYYY"];
            UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 210, 20)];
            dateLabel.numberOfLines = 1;
            dateLabel.lineBreakMode = UILineBreakModeWordWrap;
            dateLabel.text = [dateFormatter stringFromDate:[NSDate dateFromJSONString:[eventDate objectForKey:@"event_date"]]];
            dateLabel.font = [UIFont systemFontOfSize:14];
            dateLabel.textColor = [UIColor grayColor];
            dateLabel.highlightedTextColor = [UIColor whiteColor];
            dateLabel.backgroundColor = [UIColor clearColor];
            dateLabel.tag = 3;
            [dateFormatter release];   
                
            // time
            UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(220, 4, 70, 20)];
            timeLabel.numberOfLines = 1;
            timeLabel.lineBreakMode = UILineBreakModeWordWrap;
            timeLabel.text = [theresult objectForKey:@"time"];        
            timeLabel.highlightedTextColor = [UIColor whiteColor];
            timeLabel.textAlignment = UITextAlignmentRight;
            timeLabel.backgroundColor = [UIColor clearColor];
            timeLabel.tag = 4;
            

            // place
            UILabel *placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(220, 22, 70, 20)];
            placeLabel.numberOfLines = 1;
            placeLabel.lineBreakMode = UILineBreakModeWordWrap;
            placeLabel.text = [self formatPlaceString:[NSString stringWithFormat:@"%@",[theresult objectForKey:@"place"]]];        
            placeLabel.highlightedTextColor = [UIColor whiteColor];
            placeLabel.textColor = [UIColor grayColor];
            placeLabel.font = [UIFont systemFontOfSize:14];
            placeLabel.textAlignment = UITextAlignmentRight;
            placeLabel.backgroundColor = [UIColor clearColor];
            placeLabel.tag = 5;
            
            // gender place
            UILabel *genderPlaceLabel = [[UILabel alloc] initWithFrame:CGRectMake(220, 40, 70, 20)];
            genderPlaceLabel.numberOfLines = 1;
            genderPlaceLabel.lineBreakMode = UILineBreakModeWordWrap;
            genderPlaceLabel.text = [self formatPlaceString:[NSString stringWithFormat:@"%@",[theresult objectForKey:@"gender_place"]]];        
            genderPlaceLabel.highlightedTextColor = [UIColor whiteColor];
            genderPlaceLabel.textColor = [UIColor redColor];
            genderPlaceLabel.font = [UIFont systemFontOfSize:14];
            genderPlaceLabel.textAlignment = UITextAlignmentRight;
            genderPlaceLabel.backgroundColor = [UIColor clearColor];
            genderPlaceLabel.tag = 6;

                
            // add subviews
            [[cell contentView] addSubview:eventName];
            [[cell contentView] addSubview:dateLabel];
            [[cell contentView] addSubview:locationLabel];
            [[cell contentView] addSubview:timeLabel];
            [[cell contentView] addSubview:placeLabel];
            if ([[participant objectForKey:@"gender"] isEqualToString:@"F"]) {
                // only show gender place for female participants
                [[cell contentView] addSubview:genderPlaceLabel];
            }
            // cleanup
            [eventName release];
            [dateLabel release];
            [locationLabel release];
            [timeLabel release];
            [placeLabel release];
            [genderPlaceLabel release];
            
        }
        
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 1) {
        
        UpcomingEventsViewController* upcomingViewController = [[UpcomingEventsViewController alloc] initWithUpcomingEvents:self.registrationsArray forPerson:participant];    
        
        [self.navigationController pushViewController:upcomingViewController animated:YES];
        [upcomingViewController release];

    
    } else {
         
        if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:@"RunnerResultCell"]) {
            NSDictionary* selectedEventResult = [personResultsArray objectAtIndex:[indexPath row]];
            NSDictionary* eventDist = (NSDictionary*)[selectedEventResult objectForKey:@"EventDistance"];

            UIViewController* detailViewController = [[ResultsViewController alloc] 
                                    initWithNibName:@"ResultsViewController"
                                    withEventDistance:eventDist 
                                    bundle:nil];      
            
            [self.navigationController pushViewController:detailViewController animated:YES];
            [detailViewController release];
        }
    }
}


 - (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            int minRowHeight = 100;
            int imgFrameWidth = 100;
            int imgHeight = (personImage.size.height * imgFrameWidth / personImage.size.width);         
        
            return MAX(imgHeight+20, minRowHeight);
        } else {
            return 44;
        }
    } else {
        if (personResultsArray.count > 0) {
            return 64;
        } else {
            return 56;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section==1) {
        switch ([self.personResultsArray count]) {
            case 0: return @"Events"; break;
            case 1: return @"1 Event"; break; 
            default: return [NSString stringWithFormat:@"%d Events",[self.personResultsArray count]]; break;
        }
    }
    return Nil;
}


#pragma mark - ASIHttpRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{    
    NSIndexPath *indexPath;
    NSString *response;
    
    switch (request.tag) {
            
        case REQUEST_TYPE_IMAGE :

            // get top table cell
            indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            UIView* cellContentView = [[[self tableView] cellForRowAtIndexPath:indexPath] contentView];

            // remove spinner & loading image label
            NSArray* subviews = [cellContentView subviews];
            int numSubViews = [subviews count];
            for (int i=0; i < numSubViews; i++) {
                UIView* view = [subviews objectAtIndex:i];
                if (view.tag == 5 || view.tag == 6) {
                    [view removeFromSuperview];
                }
            }
            
            personImage = [UIImage imageWithData:[request responseData]];
            [personImage retain];   /// ??? necessary?
            
            UIImage *img = self.personImage;
            
            int imgFrameWidth = 100;
            int imgFrameHeight = img.size.height * imgFrameWidth / img.size.width; 
            int imgFrameX = 290 - imgFrameWidth;
            int imgFrameY = 10 + MAX(0, (80-imgFrameHeight) / 2);
                
            UIButton *imgButton = [UIButton buttonWithType:UIButtonTypeCustom];                                                        
            [imgButton setBackgroundImage:img forState:UIControlStateNormal];
            imgButton.frame = CGRectMake(imgFrameX, imgFrameY, imgFrameWidth, imgFrameHeight);
            imgButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
            imgButton.layer.borderWidth = 1.0;
            imgButton.layer.cornerRadius = 5.0;
            imgButton.layer.masksToBounds = YES;
            imgButton.tag = 7;    
            [imgButton addTarget:self action:@selector(showPhoto:) forControlEvents:UIControlEventTouchUpInside];

            [cellContentView addSubview:imgButton];
            [cellContentView bringSubviewToFront:imgButton];

            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];

            break;
        
        case REQUEST_TYPE_RESULTS :

            self.registrationsArray = [NSMutableArray arrayWithObjects:nil];
            self.personResultsArray = [NSMutableArray arrayWithObjects:nil];

            response = [request responseString];
            
            // parse JSON string into NSDictionary
            SBJsonParser *json = [[SBJsonParser new] autorelease];
            NSError *jsonError = nil;
            NSDictionary *parsedJSON = [json objectWithString:response error:&jsonError];
            
            if (jsonError) {
                NSLog(@"%@",[jsonError description]);
            }
            
            NSMutableArray *data = [parsedJSON objectForKey:@"d"];
            NSDictionary *result;
            for (result in data) {
                if ([[result objectForKey:@"place"] intValue] == 0) {
                    
                    // only including in upcoming results list is the event is in the future
                    NSDictionary* eventDate = (NSDictionary*)[(NSDictionary*)[result objectForKey:@"EventDistance"] objectForKey:@"vwMobileEventDate"];
                    NSDate *theDate = [NSDate dateFromJSONString:[eventDate objectForKey:@"event_date"]];
                    NSDate* today = [NSDate date];
                    if ([today compare:theDate] == NSOrderedAscending) {
                          [self.registrationsArray addObject:result];
                    }
                } else {
                    [self.personResultsArray addObject:result];
                }
            }
                        
            // sort the upcoming registrations array by date
            // (I don't know why it isn't sorted to begin with, but oh well)
            [self.registrationsArray sortUsingComparator: ^(id obj1, id obj2) {
                
                NSDictionary* eventDate1 = (NSDictionary*)[(NSDictionary*)[obj1 objectForKey:@"EventDistance"] objectForKey:@"vwMobileEventDate"];
                NSDictionary* eventDate2 = (NSDictionary*)[(NSDictionary*)[obj2 objectForKey:@"EventDistance"] objectForKey:@"vwMobileEventDate"];

                NSDate *date1 = [NSDate dateFromJSONString:[eventDate1 objectForKey:@"event_date"]];
                NSDate *date2 = [NSDate dateFromJSONString:[eventDate2 objectForKey:@"event_date"]];

                return [date1 compare:date2];
            }];
           
            
            // do a reload of the table
            [self.tableView performSelectorOnMainThread:@selector(reloadData) 
                                   withObject:nil 
                                waitUntilDone:YES];  
            break;
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    // unable to get image
    NSError *error = [request error];
    
    // TODO: what to do if image fetch fails??
    //   possible causes: image missing or request timed out
    //   need to stop spinner and show an "image not avaialble" image
    
    
    NSLog(@"fetch error: %@", error.description);
    
}

#pragma mark - Segmented button methods

- (void)segmentAction:(UISegmentedControl*)sender 
{
    switch ([sender selectedSegmentIndex])
    {
        case 0: // search
        {
            SearchViewController *svc = [[SearchViewController alloc] 
                                         initWithNibName:@"SearchViewController"
                                         bundle:nil];
            svc.title = @"Search";
            [self.navigationController pushViewController:svc animated:YES];
            [svc release];
            break;
        }
        case 1: // home
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        }
    }
}

@end
