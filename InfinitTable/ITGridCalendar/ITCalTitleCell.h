//
//  ITCalTitleCell.h
//  testCalendarTableView
//
//  Created by yht on 9/22/16.
//  Copyright © 2015 yht. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ITCalTitleCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIView *vRightLine;
@property (weak, nonatomic) IBOutlet UIView *vBotLine;
@property (weak, nonatomic) IBOutlet UILabel *lbDay;
@property (weak, nonatomic) IBOutlet UILabel *lbWeek;

@property (nonatomic)BOOL isSelected;

@end
