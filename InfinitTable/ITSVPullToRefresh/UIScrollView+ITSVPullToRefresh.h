//
// UIScrollView+ITSVPullToRefresh.h
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>


@class ITSVPullToRefreshView;

@interface UIScrollView (SVPullToRefresh)

typedef NS_ENUM(NSUInteger, SVPullToRefreshPosition) {
    SVPullToRefreshPositionTop = 1<<0,
    SVPullToRefreshPositionBottom = 1<<2,
    SVPullToRefreshPositionLeft = 1<<3,
    SVPullToRefreshPositionRight = 1<<4,
    SVPullToRefreshPositionEnd = 1<<5,
};

- (void)addPullToRefreshWithActionHandler:(void (^)(SVPullToRefreshPosition pos))actionHandler position:(NSUInteger)position;
- (void)triggerPullToRefresh;
- (void)stopPullAnimating;
- (void)fixPullViewPosition;//回定位置
- (void)cancelOtherViewAction:(ITSVPullToRefreshView*)me;

@property (nonatomic, strong, readonly) NSMutableArray *pullToRefreshViewsArray;
@property (nonatomic, assign) BOOL showsPullToRefresh;

@end


typedef NS_ENUM(NSUInteger, SVPullToRefreshState) {
    SVPullToRefreshStateStopped = 0,
    SVPullToRefreshStateTriggered,
    SVPullToRefreshStateLoading,
    SVPullToRefreshStateAll = 10
};

@interface ITSVPullToRefreshView : UIView

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UIColor *activityIndicatorViewColor NS_AVAILABLE_IOS(5_0);
@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;

@property (nonatomic, readonly) SVPullToRefreshState state;
@property (nonatomic, readonly) SVPullToRefreshPosition position;
@property (nonatomic)BOOL canCallBack;

- (void)setTitle:(NSString *)title forState:(SVPullToRefreshState)state;

- (void)startAnimating;
- (void)stopAnimating;

@end
