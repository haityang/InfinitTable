//
//  ITCalPriceCell.h
//  testCalendarTableView
//
//  Created by yht on 9/22/16.
//  Copyright © 2015 yht. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ITCalPriceSelStatus) {
    ITCalPriceSelStatusUnSelected=1,     //处于未选中状态,背景色为白
    ITCalPriceSelStatusSelected,        //处于选中状态,背景色为蓝
    ITCalPriceSelStatusRefSelected,//处于关联选中状态,背景色为灰色
};

@interface ITCalPriceCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *lbPrice;

@property(nonatomic)ITCalPriceSelStatus selStatus; 
@property(nonatomic)BOOL isHasPrice;//是否有低价数据。会影响到显示和可选性
@end
