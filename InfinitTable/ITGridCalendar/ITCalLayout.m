//
//  ITCalLayout.m
//  CollectionViewMultipleRowsHorizontal
//
//  Created by Eric G. DelMar on 12/18/12.
//  Copyright (c) 2012 Eric G. DelMar. All rights reserved.
//
#define space 0
#import "ITCalLayout.h"

#define kGridUnitWidth 50
#define kGridUnitHeight 50

@implementation ITCalLayout { // a subclass of UICollectionViewFlowLayout
    NSInteger itemWidth;
    NSInteger itemHeight;
    NSInteger contentWidth;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        itemWidth = kGridUnitWidth;
        itemHeight = kGridUnitHeight;
    }
    return self;
}

-(CGSize)collectionViewContentSize {
    static CGSize contentSize;//因为每个单元格大小一样，所以用静态
    if (!CGSizeEqualToSize(contentSize, CGSizeZero)) return contentSize;
    
    NSInteger secCount =  [self.collectionView numberOfSections];
    if (secCount==0) return CGSizeZero;
    
    NSInteger ySize = secCount * (itemHeight + space);
    NSInteger xSize = [self.collectionView numberOfItemsInSection:0] * (itemWidth + space); // "space" is for spacing between cells.
    
    contentWidth = xSize;
    contentSize = CGSizeMake(xSize, ySize);
    return contentSize;

}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path {
    UICollectionViewLayoutAttributes* attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    attributes.size = CGSizeMake(itemWidth,itemHeight);
    CGFloat xValue = (CGFloat)itemWidth/2.0 + path.row * (itemWidth + space);
    CGFloat yValue = (CGFloat)itemHeight/2.0 + path.section * (itemHeight + space);
    attributes.center = CGPointMake(xValue, yValue);
    return attributes;
}


-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {
    static NSArray *array;
    if (!array) {
        NSInteger minCol = 0;
        NSInteger maxCol= contentWidth/(itemWidth + space);
        
        NSMutableArray* attributes = [NSMutableArray array];
        for(NSInteger i=0 ; i < self.collectionView.numberOfSections; i++) {
            for (NSInteger j=minCol ; j < maxCol; j++) {
                NSIndexPath* indexPath = [NSIndexPath indexPathForItem:j inSection:i];
                [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
            }
        }
        array = attributes;
    }
    return array;
}

@end
