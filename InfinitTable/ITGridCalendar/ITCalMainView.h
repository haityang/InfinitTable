//
//  ITCalMainView.h
//  testCalendar
//
//  Created by yht on 9/27/16.
//  Copyright © 2015 yht. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ITCalMainView : UIView

- (void)reloadWithStartDate:(NSDate*)startDate
                    endDate:(NSDate*)endDate
                currentDate:(NSDate*)currentDate
                  priceData:(NSArray*)priceData;

@end
