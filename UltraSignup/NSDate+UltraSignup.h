//
//  NSDate+UltraSignup.h
//  UltraSignup
//
//  Created by Jon Kroll on 12/27/11.
//  Copyright (c) 2011. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark Date Parsing

@interface NSDate (UltraSignup)

/**
 @brief Decodes the receiver's JSON text
 
 @return the NSDictionary or NSArray represented by the receiver, or nil on error.
 
 @see @ref json2objc
 */
+ (NSDate*)dateFromJSONString:(NSString*)string;

@end