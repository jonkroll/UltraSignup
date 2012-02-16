//
//  NewsItem.m
//  UltraSignup
//
//  Created by Jon Kroll on 12/30/11.
//  Copyright (c) 2011. All rights reserved.
//

#import "NewsItem.h"

@implementation NewsItem

@synthesize title = _title;
@synthesize description = _description;
@synthesize date = _date;
@synthesize url = _url;

- (id)initWithTitle:(NSString*)title 
    withDescription:(NSString*)description 
           withDate:(NSDate*)date 
            withURL:(NSString*)url 
{
    if ((self = [super init])) {
        _title = [title copy];
        _description = [description copy];
        _date = [date copy];
        _url = [url copy];
    }
    return self;
}

- (void)dealloc {
    [_title release];
    _title = nil;
    [_description release];
    _description = nil;
    [_date release];
    _date = nil;
    [_url release];
    _url = nil;
    [super dealloc];
}


@end
