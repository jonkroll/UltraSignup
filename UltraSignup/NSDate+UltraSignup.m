//
//  NSDate+UltraSignup.m
//  UltraSignup
//
//  Created by Jon Kroll on 12/27/11.
//  Copyright (c) 2011. All rights reserved.
//

#import "NSDate+UltraSignup.h"

@implementation NSDate (UltraSignup)


+ (NSDate*)dateFromJSONString:(NSString*)string 
{
    // example of date format from xml: /Date(1308960000000)/

    NSTimeInterval milliseconds = [[string substringWithRange:NSMakeRange(6,13)] doubleValue] / 1000.0;
    return [NSDate dateWithTimeIntervalSince1970:milliseconds];

}

@end
