//
//  ITCalDataMgr.m
//  testCalendarTableView
//
//  Created by yht on 9/22/16.
//  Copyright © 2015 yht. All rights reserved.
//

#import "ITCalDataMgr.h"
@interface ITCalDataMgr()
{
    int _row, _col;   //old row, col
}
@end

@implementation ITCalDataMgr

- (void)reloadDataWithStartDate:(NSDate*)starDate endDate:(NSDate*)endDate currentDate:(NSDate*)currentDate priceDatas:(NSArray*)priceData
{
    NSMutableArray *dicDepartTitles = [NSMutableArray array];
    NSMutableArray *dicArriveTitles = [NSMutableArray array];
    NSMutableArray *dicGrids = [NSMutableArray array];
    
    for (int i=0; i<30; ++i) {//arrive date
        //set arrive title date
        NSString *arriveDate = [NSString stringWithFormat:@"201509%02d", i];
        ITCalTitleUnitData *leftTitleUnit = [[ITCalTitleUnitData alloc] init];
        leftTitleUnit.day = [NSString stringWithFormat:@"08-%02d", i];
        leftTitleUnit.week = @"横向";
        leftTitleUnit.date = arriveDate;
        [dicArriveTitles addObject:leftTitleUnit];

        NSMutableArray *rows = [NSMutableArray array];
        for (int j=0; j<30; ++j) {//depart date
            NSString *departDate = [NSString stringWithFormat:@"201508%02d", j];
            if (i==0) {
                //set depart title date
                ITCalTitleUnitData *topTitleUnit = [[ITCalTitleUnitData alloc] init];
                topTitleUnit.day = [NSString stringWithFormat:@"08-%02d", i];
                topTitleUnit.week = @"纵向";
                topTitleUnit.date = departDate;
                [dicDepartTitles addObject:topTitleUnit];
            }
            
            //set price data for each row
            ITCalPrcieUnitData *priceData = [[ITCalPrcieUnitData alloc] init];
            priceData.price = [NSString stringWithFormat: @"20%d", j];
            priceData.depDate = departDate;
            priceData.arrDate = arriveDate;
            priceData.isLowestPrice = NO;
            priceData.isHasPrice = YES;
            [rows addObject:priceData];
        }
        [dicGrids addObject:rows];
    }
    
    self.topTitles = dicDepartTitles;
    self.leftTitles = dicArriveTitles;
    self.priceDatas = dicGrids;
}


- (void)setSelStatusWithPath:(int)row col:(int)col isSelectd:(BOOL)isSelected
{
    ITCalPriceUnitSelStatus selStatus = (isSelected)? ITCalPriceUnitSelStatusRefSelected : ITCalPriceUnitSelStatusUnSelected;
    for (int i=0; i<=row; ++i) {//得到某一列
        ITCalPrcieUnitData *data = _priceDatas[i][col];
        data.selStatus = selStatus;
    }
    
    for (int i=0; i<=col; ++i) {//得到某一行
        ITCalPrcieUnitData *data = _priceDatas[row][i];
        data.selStatus = selStatus;
    }
    
    ITCalPrcieUnitData *data = _priceDatas[row][col];
    data.selStatus = (isSelected)? ITCalPriceUnitSelStatusSelected : ITCalPriceUnitSelStatusUnSelected;
    
}


- (void)setSelStatusWithPath:(int)row col:(int)col
{
    [self setSelStatusWithPath:_row col:_col isSelectd:NO];
    [self setSelStatusWithPath:row col:col isSelectd:YES];
    _row = row;
    _col = col;
}

@end


@implementation ITCalPrcieUnitData
- (instancetype)init
{
    self = [super init];
    if (self) {
        _selStatus = ITCalPriceUnitSelStatusUnSelected;
    }
    return self;
}
@end



@implementation ITCalTitleUnitData
@end
