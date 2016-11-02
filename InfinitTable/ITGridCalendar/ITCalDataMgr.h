//
//  ITCalDataMgr.h
//  testCalendarTableView
//
//  Created by yht on 9/22/16.
//  Copyright © 2015 yht. All rights reserved.
//

#import <Foundation/Foundation.h>



@class ITCalPrcieUnitData;
@class ITCalTitleUnitData;

typedef NS_ENUM(NSInteger, ITCalPriceUnitSelStatus) {
    ITCalPriceUnitSelStatusUnSelected=1,     //处于未选中状态,背景色为白
    ITCalPriceUnitSelStatusSelected,        //处于选中状态,背景色为蓝
    ITCalPriceUnitSelStatusRefSelected,//处于关联选中状态,背景色为灰色
};

//日历数据管理
@interface ITCalDataMgr : NSObject
@property(nonatomic,strong)NSArray *topTitles;
@property(nonatomic,strong)NSArray *leftTitles;
@property(nonatomic,strong)NSArray *priceDatas;

- (void)reloadDataWithStartDate:(NSDate*)starDate endDate:(NSDate*)endDate currentDate:(NSDate*)currentDate priceDatas:(NSArray*)priceDatas;
- (void)setSelStatusWithPath:(int)row col:(int)col; //设置低价Cell选中状态
@end



//低价单元数据结构
@interface ITCalPrcieUnitData : NSObject
@property(nonatomic,strong)NSString *price;
@property(nonatomic,copy)NSString *depDate;
@property(nonatomic,copy)NSString *arrDate;
@property(nonatomic)ITCalPriceUnitSelStatus selStatus;
@property(nonatomic)BOOL isHasPrice;//有低价数据
@property(nonatomic)BOOL isLowestPrice;//是最低价
@end


@interface ITCalTitleUnitData : NSObject
@property(nonatomic,copy)NSString *day;
@property(nonatomic,copy)NSString *week;
@property(nonatomic,strong)NSString *date;

@end

