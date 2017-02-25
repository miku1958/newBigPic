//
//  newBigPicView.h
//  newBigPic
//
//  Created by mikun on 2017/2/24.
//  Copyright © 2017年 mikun. All rights reserved.
//

#import <UIKit/UIKit.h>

#define predictMargin 30

/** 这个代理是给newBigPicViewGroup专用的，其他情况不需要用到这个代理 */
@protocol newBigPicViewDelegate <NSObject>

@property (nonatomic,assign)CGFloat animationTime;
@property (nonatomic,assign)CGFloat BGAlpha;

/** 如果预览图片是正方形的，需要按原比例显示，需要设置这个 */
@property (nonatomic,assign)CGPoint picRatio;

/** 如果原比例是从某个缩略图获取的，可以设置这个标识符，但优先级没有picRatio高 */
@property (nonatomic,strong)NSString *exchangeStringToRatioURL;

/** 缩略图的标志字符串 */
@property (nonatomic,strong)NSString *exchangeStringFromThumbnailURL;

/** 移动网络打开的大图的标志字符串 */
@property (nonatomic,strong)NSString *exchangeStringToMobileBigSizeURL;

/** WIFI网络下打开的大图的标志字符串，如果不设置这个但设置了原图标志符，wifi 下会用原图打开 */
@property (nonatomic,strong)NSString *exchangeStringToWIFIBigSizeURL;

/** 打开的原图的标志字符串 */
@property (nonatomic,strong)NSString *exchangeStringToOriSizeURL;

/** 如果移动网络打开的大图不能播放（像新浪微博的就是这样，gif 需要原图的地址才行），需要设置这个 */
@property (nonatomic,strong)NSString *exchangeStringToGifURL;

@optional

- (void)dismissBigPicViews;
- (void)picShouldChange:(CGFloat)offsetX;
- (void)picShouldRecover;

@end


@interface newBigPicView : UIView
@property (nonatomic, weak) id<newBigPicViewDelegate> delegate;

#pragma mark - 公用属性,和上面代理应该有的属性是一样的
@property (nonatomic,assign)CGFloat animationTime;
@property (nonatomic,assign)CGFloat BGAlpha;

#pragma mark - 缩略图比例
/** 如果预览图片是正方形的，需要按原比例显示，需要设置这个 */
@property (nonatomic,assign)CGPoint picRatio;

/** 如果原比例是从某个缩略图获取的，可以设置这个标识符，但优先级没有picRatio高 */
@property (nonatomic,strong)NSString *exchangeStringToRatioURL;


#pragma mark - 修改图片url的标志符（如果有），如果打开时的url就是大图就不需要设置这些
/** 缩略图的标志字符串 */
@property (nonatomic,strong)NSString *exchangeStringFromThumbnailURL;

/** 移动网络打开的大图的标志字符串 */
@property (nonatomic,strong)NSString *exchangeStringToMobileBigSizeURL;

/** WIFI网络下打开的大图的标志字符串，如果不设置这个但设置了原图标志符，wifi 下会用原图打开 */
@property (nonatomic,strong)NSString *exchangeStringToWIFIBigSizeURL;

/** 打开的原图的标志字符串 */
@property (nonatomic,strong)NSString *exchangeStringToOriSizeURL;

/** 如果移动网络打开的大图不能播放（像新浪微博的就是这样，gif 需要原图的地址才行），需要设置这个 */
@property (nonatomic,strong)NSString *exchangeStringToGifURL;
#pragma mark - 初始化方法
/** 初始化方法,不要把这个 view 加到自己的 view 上面去!! */
+(newBigPicView *)bigPicture;


#pragma mark - 设置图片方法
/** 把图片的 superview 和需要显示的图片在这个 subviews 中的 index 整个一起发过来 ,并且从原始位置放大*/
-(void)setPicsView:(UIView *)picsView showIndex:(NSUInteger)idx;

/** 把图片的 superview 和需要显示的图片在这个 subviews 中的 index 整个一起发过来 ,没有动画,直接显示*/
-(void)preLoadPicsView:(UIView *)picsView showIndex:(NSInteger)idx;

/** 把需要显示的图片 url 发过来,并且指定消失的时候回到哪里 ,打开的时候先黑屏加载完再渐隐出来,消失的时候回到指定的地方*/
-(void)setPicURL:(NSString *)URL returnView:(UIView *)returnView returnRect:(CGRect)returnRect;
@end


