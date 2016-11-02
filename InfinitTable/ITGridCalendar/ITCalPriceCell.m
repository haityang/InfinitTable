//
//  ITCalPriceCell.m
//  testCalendarTableView
//
//  Created by yht on 9/22/16.
//  Copyright © 2015 yht. All rights reserved.
//

#import "ITCalPriceCell.h"

/** HEX颜色 */
#define CTColorHex(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 green:((c>>8)&0xFF)/255.0 blue:((c)&0xFF)/255.0 alpha:1.0]
#define CTColorHexA(c,a) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 green:((c>>8)&0xFF)/255.0 blue:((c)&0xFF)/255.0 alpha:(a)]


@implementation ITCalPriceCell


- (void)setSelStatus:(ITCalPriceSelStatus)selStatus
{
    if (_selStatus == selStatus) return;//状态一样，则不变化
    
    _selStatus = selStatus;
    if (selStatus==ITCalPriceSelStatusUnSelected) {
        self.backgroundColor = [UIColor whiteColor];
        self.lbPrice.textColor = CTColorHex(0x666666);
    
    }else if (selStatus==ITCalPriceSelStatusSelected) {
        self.backgroundColor = CTColorHex(0x099fde);
        self.lbPrice.textColor = [UIColor whiteColor];
    }else {
        self.backgroundColor = CTColorHex(0xeffaff);
        self.lbPrice.textColor = CTColorHex(0x666666);
    }
}



@end
