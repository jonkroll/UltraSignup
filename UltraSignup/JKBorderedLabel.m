//
//  JKBorderedLabel.m
//  test3
//
//  Created by Jon Kroll on 1/19/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "JKBorderedLabel.h"

#define kUltraSignupLightGreen [UIColor colorWithRed:157.0 / 255 green:160.0 / 255 blue:57.0 / 255 alpha:1.0]

@implementation JKBorderedLabel

@synthesize borderColor = _borderColor;
@synthesize borderWidth = _borderWidth;


- (id)initWithString:(NSString*)string
{
    if (self = [super init]) {
    
        self.text = string;
        self.textColor = [UIColor whiteColor];
        self.font = [UIFont fontWithName:@"Impact" size:20.0];
        self.textAlignment = UITextAlignmentCenter;
        self.backgroundColor = [UIColor clearColor];
        self.borderColor = kUltraSignupLightGreen;
        self.borderWidth = 4;
        [self sizeToFit];
    }
    return self;    
}

- (void)drawTextInRect:(CGRect)rect {
    
    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor = self.textColor;

    self.shadowOffset = CGSizeMake(0, 0);
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, _borderWidth);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    
    // on the iPhone simulator it was necessary to shift the y origin of the border down one pixel
    // on the actual device it doesn't look like this is necessary though
    //rect.origin.y += 1;
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = _borderColor;
    [super drawTextInRect:rect];

    //rect.origin.y -= 1;    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    [super drawTextInRect:rect];
        
    self.shadowOffset = shadowOffset;
    
}

- (void)sizeToFit
{
    [super sizeToFit];
    
    self.frame = CGRectMake(self.frame.origin.x,
                               self.frame.origin.y - _borderWidth,
                               self.frame.size.width + (_borderWidth * 2),
                               self.frame.size.height);
}

@end
