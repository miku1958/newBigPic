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

@interface newBigPicViewGroup()<UIScrollViewDelegate,newBigPicViewDelegate>{
    CGFloat screenWidth;//这三个全局变量在baseSetting中设置
    CGFloat screenHeight;
    CGFloat yWhenSameWH;
    
    NSInteger showingIndex;
    NSInteger picCount;
    /** 图片高除以宽的比例 */
    CGFloat picRatio;
    __block CGFloat picVIewScale;
    
    CGRect newFrameOfBigPicView;
    
    UIView *picSuperView;
    //NSArray *picViewArray;
    
    BOOL preLoadViewHasLoad;
    //-1代表是左边,0代表没有上一次,1代表是右边
    NSInteger lastPreIsRight;
    
    CGFloat currentOffset;
    
    BOOL swiping;
}

@property (nonatomic,strong)newBigPicView *showingView;
@property (nonatomic,strong)newBigPicView *preLoadLeftView;
@property (nonatomic,strong)newBigPicView *preLoadRightView;
@property (nonatomic,strong)UIScrollView *picContentView;

@property (nonatomic,strong)UIVisualEffectView *bgView;
@end

@implementation newBigPicViewGroup

-(CGFloat)animationTime{
	if (!_animationTime) {
		_animationTime = 0.25;
	}
	return _animationTime;
}

-(CGFloat)BGAlpha{
	if (!_BGAlpha) {
		_BGAlpha = 0.9;
	}
	return _BGAlpha;
}

+(newBigPicViewGroup *)bigPictureGroup{
    newBigPicViewGroup *group = [[newBigPicViewGroup alloc]initWithFrame:newKeywindow.frame];
    [group baseSetting];
    //    bigPicView.clipsToBounds = NO;
    
    return group;
}



-(void)baseSetting{
    screenWidth = newScreenWidth;
    screenHeight = newScreenHeight;
    yWhenSameWH = (screenHeight-screenWidth)/2;
    
    UIBlurEffect * blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    _bgView = [[UIVisualEffectView alloc]initWithEffect:blur];
    _bgView.frame = self.bounds;
    _bgView.alpha = 0;//改变 alpha 可以改变模糊度
    [self addSubview:_bgView];
}

-(newBigPicView *)showingView{
    if (!_showingView) {
        _showingView = [newBigPicView bigPicture];
        _showingView.delegate = self;
        [_picContentView addSubview:_showingView];
    }
    return _showingView;
}

-(newBigPicView *)preLoadLeftView{
    if (!_preLoadLeftView) {
        _preLoadLeftView = [newBigPicView bigPicture];
        _preLoadLeftView.delegate = self;
        [_picContentView addSubview:_preLoadLeftView];
    }
    return _preLoadLeftView;
}
-(newBigPicView *)preLoadRightView{
    if (!_preLoadRightView) {
        _preLoadRightView = [newBigPicView bigPicture];
        _preLoadRightView.delegate = self;
        [_picContentView addSubview:_preLoadRightView];
    }
    return _preLoadRightView;
}
-(UIScrollView *)picContentView{
    if (!_picContentView) {
        _picContentView = [[UIScrollView alloc]init];
        self.picContentView.frame = self.bounds;
        _picContentView.pagingEnabled = YES;
                _picContentView.alwaysBounceHorizontal = YES;
        _picContentView.delegate = self;
        [self addSubview:_picContentView];
    }
    return _picContentView;
}


-(void)setPicsView:(UIView *)picsView showIndex:(NSUInteger)idx{

    UIWindow *win = newKeywindow;
    win.windowLevel = UIWindowLevelAlert;
    [win.rootViewController.view addSubview:self];
    [UIView animateWithDuration:self.animationTime animations:^{
        _bgView.alpha = self.BGAlpha;
    }];
    showingIndex = idx;
    picSuperView = picsView;
    picCount= 0;
    [picsView.subviews enumerateObjectsUsingBlock:^(UIView *imageView, NSUInteger idx, BOOL * _Nonnull stop) {
        if(!imageView.isHidden)
            picCount++;
    }];
    self.picContentView.contentSize = (CGSize){screenWidth*picCount, screenHeight};
    currentOffset = screenWidth*showingIndex;
    self.picContentView.contentOffset = CGPointMake(currentOffset, 0);
//    lastPreIsRight=0;
//    preLoadViewHasLoad =NO;
    [self.showingView setPicsView:picsView showIndex:idx];
    _showingView.x = screenWidth*showingIndex;
    
    [self.preLoadLeftView preLoadPicsView:picsView showIndex:showingIndex-1];
    _preLoadLeftView.x =screenWidth*(showingIndex-1);
    
    [self.preLoadRightView preLoadPicsView:picsView showIndex:showingIndex+1];
    _preLoadRightView.x =screenWidth*(showingIndex+1);
    
    
}


#pragma mark - bigPicView 的代理方法
-(void)picShouldChange:(CGFloat)offsetX{
//    if (offsetX>50||offsetX<-50) {
//        [UIView animateWithDuration:animationTime*2 animations:^{
//            _picContentView.contentOffset = CGPointMake(_picContentView.contentOffset.x + offsetX, 0);
//        }];
//    }else
//    return;
    
//    CGFloat x = _picContentView.contentOffset.x;
//    NSUInteger currentIndex = _picContentView.contentOffset.x/screenWidth;
//    if ((currentIndex != showingIndex||(fabs(offsetX)<10))&&!((currentIndex >= picCount-1)||(!currentIndex)))
//        return;
    
    if (offsetX>0) {
        if (showingIndex>= picCount-1)
            return;

    }else{
        if (!showingIndex)
            return;
    }
//    [UIView animateWithDuration:animationTime*2 animations:^{
        _picContentView.contentOffset = CGPointMake(showingIndex*screenWidth + offsetX,0);


//    }];
    
//    [self scrollViewDidScroll:_picContentView];
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (![scrollView.panGestureRecognizer velocityInView:scrollView].x) {
        [self picShouldRecover];
    }
}


//-(void)scrollViewDidScroll:(UIScrollView *)scrollView{

//    if (preLoadViewHasLoad)
//        return;
//    CGFloat preLoadIndex;
//    if (scrollView.contentOffset.x<(screenWidth*showingIndex)) {//左边出现
//        if (!showingIndex)return;
//        if (lastPreIsRight <0) return;
//        preLoadIndex = showingIndex-1;
//        lastPreIsRight = -1;
//    }else{//右边出现,判断 index 是否为picCount-1
//        if (showingIndex == picCount-1)return;
//        if (lastPreIsRight >0) return;
//        preLoadIndex = showingIndex+1;
//        lastPreIsRight = 1;
//    }
//    [self.preLoadView preLoadPicsView:picSuperView showIndex:preLoadIndex];
//    _preLoadView.x = screenWidth*preLoadIndex;
//    preLoadViewHasLoad = YES;
//}

-(void)picShouldRecover{
    if (swiping) {
        return;
    }
    swiping = YES;
    id temp = _showingView;
    if (showingIndex)//显示左边
        if ((screenWidth*showingIndex-_picContentView.contentOffset.x)>=screenWidth*0.5) {
            showingIndex--;
            _showingView = _preLoadLeftView;
            _preLoadLeftView = _preLoadRightView;
            _preLoadRightView = temp;
            [_preLoadLeftView preLoadPicsView:picSuperView showIndex:showingIndex-1];
            _preLoadLeftView.x =screenWidth*(showingIndex-1);
        }
    if (showingIndex<picCount-1)//显示右边
        if ((_picContentView.contentOffset.x-screenWidth*showingIndex)>=screenWidth*0.5) {
            showingIndex++;
            _showingView = _preLoadRightView;
            _preLoadRightView = _preLoadLeftView;
            _preLoadLeftView = temp;
            [_preLoadRightView preLoadPicsView:picSuperView showIndex:showingIndex+1];
            _preLoadRightView.x =screenWidth*(showingIndex+1);
        }
    
//    [UIView animateWithDuration:animationTime animations:^{
//        _picContentView.contentOffset = CGPointMake(showingIndex*screenWidth, 0);
//    } completion:^(BOOL finished) {
        preLoadViewHasLoad = NO;
//    }];
    swiping = NO;
}

-(void)dismissBigPicViews{
    [UIView animateWithDuration:self.animationTime animations:^{
        _bgView.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
}



@end
