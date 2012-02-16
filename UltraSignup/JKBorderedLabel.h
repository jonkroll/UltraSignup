//
//  JKBorderedLabel.h
//  test3
//
//  Created by Jon Kroll on 1/19/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface JKBorderedLabel : UILabel
{
    UIColor *_borderColor;
    NSInteger _borderWidth;
}

@property (nonatomic, retain) UIColor *borderColor;
@property (nonatomic) NSInteger borderWidth;

- (id)initWithString:(NSString*)string;

@end
