//
//  NewsItem.h
//  UltraSignup
//
//  Created by Jon Kroll on 12/30/11.
//  Copyright (c) 2011. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewsItem : NSObject {
    NSString *_title;
    NSString *_description;
    NSDate *_date;
    NSString *_url;
}

@property (copy) NSString *title;
@property (copy) NSString *description;
@property (copy) NSDate *date;
@property (copy) NSString *url;

- (id)initWithTitle:(NSString*)title 
    withDescription:(NSString*)description 
           withDate:(NSDate*)date 
            withURL:(NSString*)url;

@end
