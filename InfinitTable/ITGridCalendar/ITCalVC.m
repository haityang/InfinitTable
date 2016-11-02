//
//  ITCalVC.m
//  testCalendarTableView
//
//  Created by yht on 9/22/16.
//  Copyright © 2015 yht. All rights reserved.
//

#import "ITCalVC.h"
#import "ITCalMainView.h"

@interface ITCalVC()
@property(nonatomic,strong)ITCalMainView *calView;

@end

@implementation ITCalVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    //create calendar view
    NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"ITCalMainView" owner:self options:nil];
    _calView = nibs[0];
    _calView.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height-64);
    [self.view addSubview:_calView];
    [_calView reloadWithStartDate:nil endDate:nil currentDate:nil priceData:nil];

}

@end
