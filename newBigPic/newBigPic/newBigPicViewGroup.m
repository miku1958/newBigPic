//
//  newBigPicViewGroup.m
//  newBigPic
//
//  Created by mikun on 2017/2/24.
//  Copyright © 2017年 mikun. All rights reserved.
//

#import "newBigPicViewGroup.h"
#import "newBigPicView.h"
#import "predefine.h"


@interface newBigPicViewGroupCell:UICollectionViewCell
@property (nonatomic,strong)newBigPicView *handleView;
@end


NSString * const CollectionCellID = @"picContentViewCellID";

@interface newBigPicViewGroup()<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>{
    CGFloat _screenWidth;//这三个全局变量在baseSetting中设置
    CGFloat _screenHeight;
    CGFloat _yWhenSameWH;
    
    NSInteger _showingIndex;
    UIImageView *_showingView;

    /** 图片高除以宽的比例 */
//    CGFloat _picRatio;
    __block CGFloat _picVIewScale;
    
    CGRect _newFrameOfBigPicView;
    
    UIView *_picSuperView;
    //NSArray *picViewArray;
    
    BOOL _preLoadViewHasLoad;
    //-1代表是左边,0代表没有上一次,1代表是右边
    NSInteger _lastPreIsRight;
    
    CGFloat _currentOffsetX;
    
    BOOL _swiping;
    
    UIVisualEffectView *_bgView;
    
    NSMutableArray<UIImageView*> *_modelArr;
	
	BOOL _isOpenImage;
}


//@property (nonatomic,strong)newBigPicView *preLoadLeftView;
//@property (nonatomic,strong)newBigPicView *preLoadRightView;
//@property (nonatomic,strong)UICollectionView *picContentView;

@end

@implementation newBigPicViewGroup


+(newBigPicViewGroup *)bigPictureGroup{
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc]init];
    flow.minimumInteritemSpacing = 0;//设置cell与cell的间距
	flow.minimumLineSpacing = 0;
    flow.sectionInset = UIEdgeInsetsZero;//设置cell与collectionView的间距
    flow.itemSize = newKeywindow.frame .size;
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    return [newBigPicViewGroup.alloc initWithFrame:newKeywindow.frame collectionViewLayout:flow];
}

-(instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout{

    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self registerClass:newBigPicViewGroupCell.class forCellWithReuseIdentifier:CollectionCellID];
        self.pagingEnabled = YES;
		self.backgroundColor = [UIColor clearColor];
        self.alwaysBounceHorizontal = YES;
        self.delegate = self;
        self.dataSource = self;
        [self baseSetting];
    }
    return self;
}

-(void)baseSetting{

    _screenWidth = newScreenWidth;
    _screenHeight = newScreenHeight;
    _yWhenSameWH = (_screenHeight-_screenWidth)/2;
    

	UIBlurEffect * blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
	_bgView = [[UIVisualEffectView alloc]initWithEffect:blur];
	_bgView.frame = self.bounds;
	_bgView.alpha = 0;//改变 alpha 可以改变模糊度

	self.backgroundView = _bgView;
    
    _BGAlpha = 1;
    _newBigPicAnimationTime = 0.25;
    _modelArr = [NSMutableArray array];
	_isOpenImage = YES;
	_OptimizeDisplayOfLandscapePic = OptimizeLandscapeDisplayTypeNO;
}


-(void)setPicView:(UIImageView *)picView{
	_picSuperView = picView.superview;
    _showingView = picView;
	
	[_picSuperView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *obj, NSUInteger idx, BOOL *stop) {
		if (obj == picView) {
			_showingIndex = idx;
            *stop =YES;
		}
	}];

    UIWindow *win = newKeywindow;
    win.windowLevel = UIWindowLevelAlert;
    [win addSubview:self];
    [UIView animateWithDuration:_newBigPicAnimationTime animations:^{
        _bgView.alpha = _BGAlpha;
    }];



    [_picSuperView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *imageView, NSUInteger idx, BOOL *stop) {
        if ([imageView.class isSubclassOfClass:UIImageView.class]){
            if(!imageView.isHidden){
                [_modelArr addObject:imageView];
            }
        }
    }];
	[UIView performWithoutAnimation:^{
		[self reloadData];
	}];
	
	_currentOffsetX = _screenWidth*_showingIndex;
	self.contentOffset = CGPointMake(_currentOffsetX, 0);

    
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _modelArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    newBigPicViewGroupCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellID forIndexPath:indexPath];
	cell.handleView.delegate = self;
	_showingIndex = indexPath.row;
	_showingView = _modelArr[_showingIndex];
	
	if (_isOpenImage) {
		_isOpenImage = NO;
		[cell.handleView setPicView:_showingView];
	}else{
		[cell.handleView preLoadPicView:_showingView];
	}
    return cell;
}

- (void)preloadCellAtIndex:(NSInteger)index{
	if (index<0||index>=_modelArr.count) {
		return;
	}
	NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
	    newBigPicViewGroupCell *cell = [self dequeueReusableCellWithReuseIdentifier:CollectionCellID forIndexPath:indexPath];
	cell.handleView.delegate = self;
	[cell.handleView preLoadPicView:_modelArr[index]];
	
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
	
}

#pragma mark - bigPicView 的代理方法
-(void)picShouldChange:(CGFloat)offsetX{
    
    if (offsetX>0) {
        if (_showingIndex>= _modelArr.count-1)
            return;
	}else if(!_showingIndex){
		return;
    }

	self.contentOffset = CGPointMake(_showingIndex*_screenWidth + offsetX,0);
}


-(void)dismissBigPicViews{
    [UIView animateWithDuration:_newBigPicAnimationTime animations:^{
        _bgView.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
}

@end


@implementation newBigPicViewGroupCell

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _handleView = [newBigPicView bigPicture];
		[self addSubview:_handleView];
    }
	return self;
}

@end
