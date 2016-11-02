//
//  ITCalTitleLTCell.m
//  testCalendar
//
//  Created by yht on 9/25/16.
//  Copyright © 2015 yht. All rights reserved.
//

#import "ITCalTitleLTCell.h"

@implementation ITCalTitleLTCell

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Drawing code
    CGPoint pts[2] = {{0,0}, {rect.size.width, rect.size.height}};
    CGContextAddLines(context, pts, 2);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextDrawPath(context, kCGPathFillStroke);
}

@end
