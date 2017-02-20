//
//  newBigPicView.h
//  mikuWeibo
//
//  Created by mikun on 2016/12/27.
//  Copyright © 2016年 庄黛淳华. All rights reserved.
//

#import <UIKit/UIKit.h>
#define BigPicViewBGAlpha 0.9
#define predictMargin 30
@protocol newBigPicViewDelegate <NSObject>
@optional
- (void)dismissBigPicViews;
- (void)picShouldChange:(CGFloat)offsetX;
- (void)picShouldRecover;

@end


@interface newBigPicView : UIView
/** 初始化方法,不要把这个 view 加到自己的 view 上面去!! */
+(newBigPicView *)bigPicture;

/** 把图片的 superview 和需要显示的图片在这个 subviews 中的 index 整个一起发过来 ,并且从原始位置放大*/
-(void)setPicsView:(UIView *)picsView showIndex:(NSUInteger)idx;

/** 把图片的 superview 和需要显示的图片在这个 subviews 中的 index 整个一起发过来 ,没有动画,直接显示*/
-(void)preLoadPicsView:(UIView *)picsView showIndex:(NSInteger)idx;

/** 把需要显示的图片 url 发过来,并且指定消失的时候回到哪里 ,打开的时候先黑屏加载完再渐隐出来,消失的时候回到指定的地方*/
-(void)setPicURL:(NSString *)URL returnView:(UIView *)returnView returnRect:(CGRect)returnRect;


@property (nonatomic, weak) id<newBigPicViewDelegate> delegate;

@end


