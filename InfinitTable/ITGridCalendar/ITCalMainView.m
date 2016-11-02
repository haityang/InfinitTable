//
//  ITCalMainView.m
//  testCalendar
//
//  Created by yht on 9/27/16.
//  Copyright © 2015 yht. All rights reserved.
//

#import "ITCalMainView.h"
#import "ITCalPriceCell.h"
#import "ITCalTitleCell.h"
#import "ITCalTitleLTCell.h"
#import "ITCalDataMgr.h"
#import "ITCalLayout.h"
#import "UIScrollView+ITSVPullToRefresh.h"

#define kTitleTopWidth  50
#define kTitleTopHeight 37
#define kTitleLeftWidth 44
#define kTitleLeftHeight 50
#define kGridUnitWidth kTitleTopWidth
#define kGridUnitHeight kTitleLeftHeight

@interface ITCalMainView()<UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate>
@property(nonatomic,strong)UIView *viewLeftTop;
@property (weak, nonatomic) IBOutlet UICollectionView *scvTopTitle;
@property (weak, nonatomic) IBOutlet UICollectionView *scvLeftTitle;
@property (weak, nonatomic) IBOutlet UICollectionView *scvGrid;
@property(nonatomic,strong)ITCalDataMgr *dataMgr;

@end

@implementation ITCalMainView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _dataMgr = [[ITCalDataMgr alloc] init];
 
    }
    return self;
}

- (void)dealloc
{

}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _scvTopTitle.dataSource = self;
    _scvLeftTitle.dataSource = self;
    _scvGrid.dataSource = self;
    _scvTopTitle.delegate = self;
    _scvLeftTitle.delegate = self;
    _scvGrid.delegate = self;
    
    [_scvTopTitle registerNib:[UINib nibWithNibName:@"ITCalTitleCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"ITCalTitleCell"];
    
    [_scvLeftTitle registerNib:[UINib nibWithNibName:@"ITCalTitleCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"ITCalTitleCell"];
    
    [_scvGrid registerNib:[UINib nibWithNibName:@"ITCalPriceCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"ITCalPriceCell"];
    
}


- (void)reloadWithStartDate:(NSDate*)startDate
                    endDate:(NSDate*)endDate
                currentDate:(NSDate*)currentDate
                  priceData:(NSArray*)priceData
{
    //reload data manager
    [_dataMgr reloadDataWithStartDate:startDate endDate:endDate currentDate:currentDate priceDatas:priceData];
    
    [self.scvTopTitle reloadData];
    [self.scvLeftTitle reloadData];
    [self.scvGrid reloadData];
    
    _scvGrid.frame = self.frame;
    
    ITCalMainView __weak *weakSelf = self;
    [_scvGrid addPullToRefreshWithActionHandler:^(SVPullToRefreshPosition pos){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [weakSelf.scvGrid stopPullAnimating];
        });
    } position:SVPullToRefreshPositionLeft|SVPullToRefreshPositionTop];
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_dataMgr setSelStatusWithPath:(int)indexPath.section col:(int)indexPath.row];
    [_scvGrid reloadData];
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (collectionView == self.scvTopTitle) {
        return 1;
    }else if (collectionView == self.scvLeftTitle) {
        return self.dataMgr.leftTitles.count;
    }else {
        return self.dataMgr.priceDatas.count;
    }
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.scvTopTitle) {
        return self.dataMgr.topTitles.count;
    }else if (collectionView == self.scvLeftTitle) {
        return 1;
    }else {
        NSArray *row = self.dataMgr.priceDatas[section];
        return row.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.scvTopTitle) {
        ITCalTitleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ITCalTitleCell" forIndexPath:indexPath];
        ITCalTitleUnitData *data = self.dataMgr.topTitles[indexPath.row];
        cell.lbDay.text = data.day;
        cell.lbWeek.text = data.week;
        return cell;
        
    }else if (collectionView == self.scvLeftTitle) {
        ITCalTitleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ITCalTitleCell" forIndexPath:indexPath];
        ITCalTitleUnitData *data = self.dataMgr.leftTitles[indexPath.section];
        cell.lbDay.text = data.day;
        cell.lbWeek.text = data.week;
        return cell;
        
    }else {
        ITCalPriceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ITCalPriceCell" forIndexPath:indexPath];
        ITCalPrcieUnitData *data = self.dataMgr.priceDatas[indexPath.section][indexPath.row];
        cell.lbPrice.text = data.price;
        cell.isHasPrice = data.isHasPrice;
        cell.selStatus = (ITCalPriceSelStatus)data.selStatus;
        return cell;
    }
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    if (scrollView == _scvGrid) {
        _scvTopTitle.delegate = nil;
        _scvLeftTitle.delegate = nil;
        _scvTopTitle.contentOffset = CGPointMake(offset.x, _scvTopTitle.contentOffset.y);
        _scvLeftTitle.contentOffset = CGPointMake(_scvLeftTitle.contentOffset.x, offset.y);
        _scvTopTitle.delegate = self;
        _scvLeftTitle.delegate = self;
        
        [_scvGrid fixPullViewPosition];
    
    }else if (scrollView == _scvLeftTitle) {
        _scvGrid.delegate = nil;
        _scvGrid.contentOffset = CGPointMake(_scvGrid.contentOffset.x, offset.y);
        _scvGrid.delegate = self;
    }else if (scrollView == _scvTopTitle) {
        _scvGrid.delegate = nil;
        _scvGrid.contentOffset = CGPointMake(offset.x, _scvGrid.contentOffset.y);
        _scvGrid.delegate = self;
    }
}




@end
