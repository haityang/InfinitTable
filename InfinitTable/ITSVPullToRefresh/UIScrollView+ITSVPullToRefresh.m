//
// UIScrollView+ITSVPullToRefresh.m
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+ITSVPullToRefresh.h"

//fequal() and fequalzro() from http://stackoverflow.com/a/1614761/184130
#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static CGFloat const ITSVPullToRefreshViewHeight = 60;


@interface ITSVPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(SVPullToRefreshPosition pos);

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, readwrite) SVPullToRefreshState state;
@property (nonatomic, readwrite) SVPullToRefreshPosition position;

@property (nonatomic, strong) NSMutableArray *titles;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, readwrite) CGFloat originalLeftInset;
@property (nonatomic, readwrite) CGFloat originalRightInset;

@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property(nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end



#pragma mark - UIScrollView (SVPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshViewArray;

@implementation UIScrollView (SVPullToRefresh)

@dynamic pullToRefreshViewsArray, showsPullToRefresh;

- (void)addPullToRefreshWithActionHandler:(void (^)(SVPullToRefreshPosition pos))actionHandler position:(NSUInteger)position {
    
    [self.pullToRefreshViewsArray removeAllObjects];
    
    for (int i=0; (SVPullToRefreshPositionEnd != 1<<i); ++i) {
        NSUInteger pos = 1<<i;
        if (pos & position) {
            CGRect frame = CGRectZero;
            switch (pos) {
                case SVPullToRefreshPositionTop:
                    frame = CGRectMake(0, -ITSVPullToRefreshViewHeight, self.bounds.size.width, ITSVPullToRefreshViewHeight);
                    break;
                case SVPullToRefreshPositionBottom:
                    frame = CGRectMake(0, self.contentSize.height, self.bounds.size.width, ITSVPullToRefreshViewHeight);
                    break;
                case SVPullToRefreshPositionLeft:
                    frame = CGRectMake(-ITSVPullToRefreshViewHeight, 0, ITSVPullToRefreshViewHeight, self.bounds.size.height);
                    break;
                case SVPullToRefreshPositionRight:
                    frame = CGRectMake(self.bounds.size.width, 0, ITSVPullToRefreshViewHeight, self.bounds.size.height);
                    break;
                default:
                    return;
            }
            ITSVPullToRefreshView *view = [[ITSVPullToRefreshView alloc] initWithFrame:frame];
            view.pullToRefreshActionHandler = actionHandler;
            view.scrollView = self;
            [self addSubview:view];
            
            view.originalTopInset = self.contentInset.top;
            view.originalBottomInset = self.contentInset.bottom;
            view.originalLeftInset = self.contentInset.left;
            view.originalRightInset = self.contentInset.right;
            view.position = pos;
            view.canCallBack = YES;
            [self addPullToRefreshViewOject:view];
            self.showsPullToRefresh = YES;
        }
    }
}

- (void)triggerPullToRefresh {
    for (ITSVPullToRefreshView *view in self.pullToRefreshViewsArray) {
        view.state = SVPullToRefreshStateTriggered;
        [view startAnimating];
    }
}

- (void)stopPullAnimating
{
    for (ITSVPullToRefreshView *pullToRefreshView in self.pullToRefreshViewsArray) {
        [pullToRefreshView stopAnimating];
    }
}

- (void)fixPullViewPosition
{
    for (ITSVPullToRefreshView *pullToRefreshView in self.pullToRefreshViewsArray) {
        CGRect frame = pullToRefreshView.frame;
        
        switch (pullToRefreshView.position) {
            case SVPullToRefreshPositionTop:
            case SVPullToRefreshPositionBottom:
                frame = CGRectMake(self.contentOffset.x, frame.origin.y, frame.size.width, frame.size.height);
                break;

            case SVPullToRefreshPositionLeft:
            case SVPullToRefreshPositionRight:
                frame = CGRectMake(frame.origin.x, self.contentOffset.y, frame.size.width, frame.size.height);
                break;

            default:
                break;
        }
        pullToRefreshView.frame = frame;
    }
}

- (void)cancelOtherViewAction:(ITSVPullToRefreshView*)me
{
    for (ITSVPullToRefreshView *pullToRefreshView in self.pullToRefreshViewsArray) {
        if (pullToRefreshView != me) {
            pullToRefreshView.canCallBack = NO;
        }
    }
}


- (NSMutableArray*)pullToRefreshViewsArray
{
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshViewArray);
}

- (void)setPullToRefreshViewsArray:(NSMutableArray *)fioArray
{
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshViewArray, fioArray, OBJC_ASSOCIATION_RETAIN);
}

- (void)addPullToRefreshViewOject:(ITSVPullToRefreshView *)pullToRefreshView
{
    if (!self.pullToRefreshViewsArray) {
        self.pullToRefreshViewsArray = [NSMutableArray array];
    }
    [self.pullToRefreshViewsArray addObject:pullToRefreshView];
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    for (ITSVPullToRefreshView *pullToRefreshView in self.pullToRefreshViewsArray) {
        pullToRefreshView.hidden = !showsPullToRefresh;
        
        if(!showsPullToRefresh) {
            if (pullToRefreshView.isObserving) {
                [self removeObserver:pullToRefreshView forKeyPath:@"contentOffset"];
                [self removeObserver:pullToRefreshView forKeyPath:@"contentSize"];
                [self removeObserver:pullToRefreshView forKeyPath:@"frame"];
                [pullToRefreshView resetScrollViewContentInset];
                pullToRefreshView.isObserving = NO;
            }
        }
        else {
            if (!pullToRefreshView.isObserving) {
                [self addObserver:pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
                [self addObserver:pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
                [self addObserver:pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
                pullToRefreshView.isObserving = YES;
                
                CGRect frame = CGRectZero;
                switch (pullToRefreshView.position) {
                    case SVPullToRefreshPositionTop:
                        frame = CGRectMake(0, -ITSVPullToRefreshViewHeight, self.bounds.size.width, ITSVPullToRefreshViewHeight);
                        break;
                    case SVPullToRefreshPositionBottom:
                        frame = CGRectMake(0, self.contentSize.height, self.bounds.size.width, ITSVPullToRefreshViewHeight);
                        break;
                    case SVPullToRefreshPositionLeft:
                        frame = CGRectMake(-ITSVPullToRefreshViewHeight, 0, ITSVPullToRefreshViewHeight, self.bounds.size.height);
                        break;
                    case SVPullToRefreshPositionRight:
                        frame = CGRectMake(self.bounds.size.width, 0, ITSVPullToRefreshViewHeight, self.bounds.size.height);
                        break;
                    default:
                        return;
                }
                
                pullToRefreshView.frame = frame;
            }
        }
    }
}

- (BOOL)showsPullToRefresh {
    for (ITSVPullToRefreshView *pullToRefreshView in self.pullToRefreshViewsArray) {
        return !pullToRefreshView.hidden;
    }
    return NO;
}

@end

#pragma mark - SVPullToRefresh
@implementation ITSVPullToRefreshView

// public properties
@synthesize pullToRefreshActionHandler, arrowColor, textColor, activityIndicatorViewColor, activityIndicatorViewStyle;

@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
@synthesize activityIndicatorView = _activityIndicatorView;

@synthesize titleLabel = _titleLabel;


- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.textColor = [UIColor darkGrayColor];
        self.state = SVPullToRefreshStateStopped;
        
        self.titles = [NSMutableArray arrayWithObjects:NSLocalizedString(@"拖拉刷新",),
                             NSLocalizedString(@"松开刷新",),
                             NSLocalizedString(@"加载中 .   .   .",),
                                nil];
        
        self.wasTriggeredByUser = YES;
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "ITSVPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

- (CGSize) calStrSize:(NSString *)str
            withFont:(UIFont *)font
           withAttrs:(NSMutableParagraphStyle *)paragraphStyle
            withSize:(CGSize)containerSize
{
    if (!font)
        font = [UIFont systemFontOfSize:18];
    
    NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine;
    if (containerSize.height > font.pointSize + 2 && !(options & NSStringDrawingUsesLineFragmentOrigin))
    {
        options = options | NSStringDrawingUsesLineFragmentOrigin;
    }
    NSDictionary *attributes;
    if (!paragraphStyle)
    {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineBreakMode = NSLineBreakByWordWrapping;
        style.lineSpacing =  0;
        style.paragraphSpacing = 0;
        style.paragraphSpacingBefore = 0;
        style.lineHeightMultiple = 0;
        attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:style};
    }
    else
    {
        attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle};
    }
    
    CGSize tmpRect = [str boundingRectWithSize:containerSize
                                       options:options
                                    attributes:attributes
                                       context:nil].size;
    return tmpRect;
    
}

- (void)layoutSubviews
{
    switch (self.state) {
        case SVPullToRefreshStateAll:
        case SVPullToRefreshStateStopped:
            [self.activityIndicatorView stopAnimating];
            
        case SVPullToRefreshStateTriggered:
            break;
            
        case SVPullToRefreshStateLoading:
            [self.activityIndicatorView startAnimating];
            break;
    }
    
    CGFloat leftViewWidth = 0;
    if (self.activityIndicatorView.hidden == NO) {
        leftViewWidth = self.activityIndicatorView.bounds.size.width;
    }
    
    self.titleLabel.text = [self.titles objectAtIndex:self.state];
    if (self.position == SVPullToRefreshPositionTop
        || self.position == SVPullToRefreshPositionBottom) {
        
        CGSize titleSize = [self calStrSize:self.titleLabel.text withFont:self.titleLabel.font withAttrs:nil withSize:CGSizeMake(self.bounds.size.width,self.titleLabel.font.lineHeight)];
        
        CGFloat totalMaxWidth = leftViewWidth + titleSize.width;
        CGFloat labelX = (self.bounds.size.width -totalMaxWidth) / 2 + leftViewWidth;
        CGFloat labelY = (self.bounds.size.height / 2)  - (titleSize.height / 2);
        
        self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, labelY, titleSize.width, titleSize.height));
        self.activityIndicatorView.center = CGPointMake(labelX-leftViewWidth, self.bounds.size.height / 2);
        
    }else {
        CGSize titleSize = [self calStrSize:self.titleLabel.text withFont:self.titleLabel.font withAttrs:nil withSize:CGSizeMake(self.titleLabel.font.lineHeight, self.bounds.size.height)];
        
        CGFloat totalMaxHeight = leftViewWidth + titleSize.height;
        CGFloat labelY = (self.bounds.size.height -totalMaxHeight) / 2 + leftViewWidth;
        CGFloat labelX = (self.bounds.size.width / 2)  - (titleSize.width / 2);
        
        self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, labelY, titleSize.width, titleSize.height));
        self.activityIndicatorView.center = CGPointMake(self.bounds.size.width / 2, labelY-leftViewWidth);
    }

}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case SVPullToRefreshPositionTop:
            currentInsets.top = self.originalTopInset;
            break;
        case SVPullToRefreshPositionBottom:
            currentInsets.bottom = self.originalBottomInset;
            currentInsets.top = self.originalTopInset;
            break;
        case SVPullToRefreshPositionLeft:
            currentInsets.left = self.originalLeftInset;
            break;
        case SVPullToRefreshPositionRight:
            currentInsets.right = self.originalRightInset;
            break;
        default:
            break;
    }
    
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case SVPullToRefreshPositionTop:
        {
            CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
            currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
        }
            break;
        case SVPullToRefreshPositionBottom:
        {
            CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
            currentInsets.bottom = MIN(offset, self.originalBottomInset + self.bounds.size.height);
        }
            break;
        case SVPullToRefreshPositionLeft:
        {
            CGFloat offset = MAX(self.scrollView.contentOffset.x * -1, 0);
            currentInsets.left = MIN(offset, self.originalLeftInset + self.bounds.size.width);
        }
            break;
        case SVPullToRefreshPositionRight:
        {
            CGFloat offset = MAX(self.scrollView.contentOffset.x * -1, 0);
            currentInsets.right = MIN(offset, self.originalRightInset + self.bounds.size.width);
        }
            break;
        default:
            break;
    }
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"contentSize"]) {
//        NSLog(@"%f, %f", self.scrollView.contentSize.width, self.scrollView.contentSize.height);
        [self layoutSubviews];
        
        CGRect frame = CGRectZero;
        switch (self.position) {
            case SVPullToRefreshPositionTop:
                frame = CGRectMake(self.frame.origin.x, -ITSVPullToRefreshViewHeight, self.bounds.size.width, ITSVPullToRefreshViewHeight);
                break;
            case SVPullToRefreshPositionBottom:
            {
                CGFloat yOrigin = MAX(self.scrollView.contentSize.height, self.scrollView.bounds.size.height);
                frame = CGRectMake(self.frame.origin.x, yOrigin, self.bounds.size.width, ITSVPullToRefreshViewHeight);
            }
                break;
            case SVPullToRefreshPositionLeft:
                frame = CGRectMake(-ITSVPullToRefreshViewHeight, self.frame.origin.y, ITSVPullToRefreshViewHeight, self.bounds.size.height);
                break;
            case SVPullToRefreshPositionRight:
            {
                CGFloat xOrigin = MAX(self.scrollView.contentSize.width, self.scrollView.bounds.size.width);
                frame = CGRectMake(xOrigin, self.frame.origin.y, ITSVPullToRefreshViewHeight, self.bounds.size.height);
            }
                break;
            default:
                return;
        }

        self.frame = frame;
    }
    else if([keyPath isEqualToString:@"frame"]) {
        CGRect frame = self.frame;
        switch (self.position) {
            case SVPullToRefreshPositionTop:
            case SVPullToRefreshPositionBottom:
            {
                frame = CGRectMake(frame.origin.x, frame.origin.y, self.scrollView.bounds.size.width, ITSVPullToRefreshViewHeight);
            }
                break;
            case SVPullToRefreshPositionLeft:
            case SVPullToRefreshPositionRight:
            {
                frame = CGRectMake(frame.origin.x, self.frame.origin.y, ITSVPullToRefreshViewHeight, self.scrollView.bounds.size.height);
            }
                break;
            default:
                return;
        }
        
        self.frame = frame;
        [self layoutSubviews];
    }
    
    

}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != SVPullToRefreshStateLoading) {
        CGFloat scrollOffsetThreshold = 0;
        switch (self.position) {
            case SVPullToRefreshPositionTop:
                scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
                break;
            case SVPullToRefreshPositionBottom:
                scrollOffsetThreshold = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.bounds.size.height + self.originalBottomInset;
                break;
            case SVPullToRefreshPositionLeft:
                scrollOffsetThreshold = self.frame.origin.x - self.originalLeftInset;
                break;
            case SVPullToRefreshPositionRight:
                scrollOffsetThreshold = MAX(self.scrollView.contentSize.width - self.scrollView.bounds.size.width, 0.0f) + self.bounds.size.width + self.originalRightInset;
                break;
            default:
                break;
        }
        
        if(!self.scrollView.isDragging && self.state == SVPullToRefreshStateTriggered)
            self.state = SVPullToRefreshStateLoading;
        else if( self.scrollView.isDragging && self.state == SVPullToRefreshStateStopped)
        {
            if ((contentOffset.y < scrollOffsetThreshold && self.position == SVPullToRefreshPositionTop)
                || (contentOffset.x < scrollOffsetThreshold && self.position == SVPullToRefreshPositionLeft)
                || (contentOffset.y > scrollOffsetThreshold && self.position == SVPullToRefreshPositionBottom)
                || (contentOffset.x > scrollOffsetThreshold && self.position == SVPullToRefreshPositionRight)) {
                self.state = SVPullToRefreshStateTriggered;
            }
        }
        else if (self.state != SVPullToRefreshStateStopped) {
            if((contentOffset.y >= scrollOffsetThreshold && self.position == SVPullToRefreshPositionTop)
               || (contentOffset.y <= scrollOffsetThreshold && self.position == SVPullToRefreshPositionBottom)
               || (contentOffset.x >= scrollOffsetThreshold && self.position == SVPullToRefreshPositionLeft)
               || (contentOffset.x <= scrollOffsetThreshold && self.position == SVPullToRefreshPositionRight)) {
                self.state = SVPullToRefreshStateStopped;
            }
        }
        
    } else {
        CGFloat offset;
        UIEdgeInsets contentInset;
        switch (self.position) {
            case SVPullToRefreshPositionTop:
                offset = MAX(self.scrollView.contentOffset.y * -1, 0.0f);
                offset = MIN(offset, self.originalTopInset + self.bounds.size.height);
                contentInset = self.scrollView.contentInset;
                self.scrollView.contentInset = UIEdgeInsetsMake(offset, contentInset.left, contentInset.bottom, contentInset.right);
                break;
            case SVPullToRefreshPositionLeft:
                offset = MAX(self.scrollView.contentOffset.x * -1, 0.0f);
                offset = MIN(offset, self.originalLeftInset + self.bounds.size.width);
                contentInset = self.scrollView.contentInset;
                self.scrollView.contentInset = UIEdgeInsetsMake(contentInset.top, offset, contentInset.bottom, contentInset.right);
                break;

            case SVPullToRefreshPositionBottom:
                if (self.scrollView.contentSize.height >= self.scrollView.bounds.size.height) {
                    offset = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.bounds.size.height, 0.0f);
                    offset = MIN(offset, self.originalBottomInset + self.bounds.size.height);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(contentInset.top, contentInset.left, offset, contentInset.right);
                } else if (self.wasTriggeredByUser) {
                    offset = MIN(self.bounds.size.height, self.originalBottomInset + self.bounds.size.height);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(-offset, contentInset.left, contentInset.bottom, contentInset.right);
                }
                break;
                
            case SVPullToRefreshPositionRight:
                if (self.scrollView.contentSize.width >= self.scrollView.bounds.size.width) {
                    offset = MAX(self.scrollView.contentSize.width - self.scrollView.bounds.size.width + self.bounds.size.height, 0.0f);
                    offset = MIN(offset, self.originalRightInset + self.bounds.size.width);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(contentInset.top, contentInset.left, contentInset.bottom, offset);
                } else if (self.wasTriggeredByUser) {
                    offset = MIN(self.bounds.size.width, self.originalRightInset + self.bounds.size.width);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(contentInset.top, -offset, contentInset.bottom, contentInset.right);
                }
                break;
            default:
                break;
        }
    }
}

#pragma mark - Getters

- (UIActivityIndicatorView *)activityIndicatorView {
    if(!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 210, 20)];
        _titleLabel.text = @"拖拉刷新";
        _titleLabel.numberOfLines = 0;
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = textColor;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}


- (UIColor *)textColor {
    return self.titleLabel.textColor;
}

- (UIColor *)activityIndicatorViewColor {
    return self.activityIndicatorView.color;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    return self.activityIndicatorView.activityIndicatorViewStyle;
}

#pragma mark - Setters


- (void)setTitle:(NSString *)title forState:(SVPullToRefreshState)state {
    if(!title)
        title = @"";
    
    if(state == SVPullToRefreshStateAll)
        [self.titles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[title, title, title]];
    else
        [self.titles replaceObjectAtIndex:state withObject:title];
    
    [self setNeedsLayout];
}


- (void)setTextColor:(UIColor *)newTextColor {
    textColor = newTextColor;
    self.titleLabel.textColor = newTextColor;
}

- (void)setActivityIndicatorViewColor:(UIColor *)color {
    self.activityIndicatorView.color = color;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}



#pragma mark -
- (void)startAnimating{
    switch (self.position) {
        case SVPullToRefreshPositionTop:
            
            if(fequalzero(self.scrollView.contentOffset.y)) {
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.frame.size.height) animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
        case SVPullToRefreshPositionBottom:
            
            if((fequalzero(self.scrollView.contentOffset.y) && self.scrollView.contentSize.height < self.scrollView.bounds.size.height)
               || fequal(self.scrollView.contentOffset.y, self.scrollView.contentSize.height - self.scrollView.bounds.size.height)) {
                [self.scrollView setContentOffset:(CGPoint){.y = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.frame.size.height} animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
            
        case SVPullToRefreshPositionLeft:
            
            if(fequalzero(self.scrollView.contentOffset.x)) {
                [self.scrollView setContentOffset:CGPointMake(-self.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
            
        case SVPullToRefreshPositionRight:
            
            if((fequalzero(self.scrollView.contentOffset.x) && self.scrollView.contentSize.width < self.scrollView.bounds.size.width)
               || fequal(self.scrollView.contentOffset.x, self.scrollView.contentSize.width - self.scrollView.bounds.size.width)) {
                [self.scrollView setContentOffset:(CGPoint){.x = MAX(self.scrollView.contentSize.width - self.scrollView.bounds.size.width, 0.0f) + self.frame.size.width} animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
        default:
            break;
    }
    
    self.state = SVPullToRefreshStateLoading;
}

- (void)stopAnimating {
    self.state = SVPullToRefreshStateStopped;
    self.canCallBack = YES;
    
    switch (self.position) {
        case SVPullToRefreshPositionTop:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalTopInset) animated:YES];
            break;
        case SVPullToRefreshPositionBottom:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.originalBottomInset) animated:YES];
            break;
        case SVPullToRefreshPositionLeft:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(-self.originalLeftInset, self.scrollView.contentOffset.y) animated:YES];
            break;
        case SVPullToRefreshPositionRight:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentSize.width - self.scrollView.bounds.size.width + self.originalRightInset, self.scrollView.contentOffset.y) animated:YES];
            break;
        default:
            break;
    }
}

- (void)setState:(SVPullToRefreshState)newState {
    
    if(_state == newState)
        return;
    
    SVPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case SVPullToRefreshStateAll:
        case SVPullToRefreshStateStopped:
            [self resetScrollViewContentInset];
            break;
            
        case SVPullToRefreshStateTriggered:
            break;
            
        case SVPullToRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == SVPullToRefreshStateTriggered
               && self.canCallBack
               && pullToRefreshActionHandler) {
                    [self.scrollView cancelOtherViewAction:self];
                    pullToRefreshActionHandler(self.position);
            }
            break;
    }
}

@end

