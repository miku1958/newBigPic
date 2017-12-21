//
//  newBigPicView.h
//  newBigPic
//
//  Created by mikun on 2017/2/24.
//  Copyright © 2017年 mikun. All rights reserved.
//
/*
 本框架读取类似九宫格的view的时候读取的是 view.subviews，
 如果是使用 StroyBoard设置缩略图的 imageview，是通过其他imageview复制过来的，
 会导致父view.subviews只有一开始手动拖进去的控件，这个是 StroyBoard 的 bug
 */

#import <UIKit/UIKit.h>

#define predictMargin 30

typedef NS_ENUM(NSInteger, OptimizeLandscapeDisplayType) {
    OptimizeLandscapeDisplayTypeYES    =1,
    OptimizeLandscapeDisplayTypeNO   =2
};

typedef NS_ENUM(NSInteger, BigPicDisplayEffectType) {
	BigPicDisplayEffectTypeScale    =0,
	BigPicDisplayEffectTypeEaseInOut   =1
};

typedef NS_ENUM(NSInteger, newPicPreloadSide) {
	newPicPreloadSideSelf    =0,
	newPicPreloadSideLeft   =1,
	newPicPreloadSideRight    =2
};

/** 这个代理是给newBigPicViewGroup专用的，其他情况不需要用到这个代理 */
@protocol newBigPicViewDelegate <NSObject>

@property (nonatomic,assign)CGFloat newBigPicAnimationTime;
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

/** 如果设置为 YES,显示横向图片的时候会稍微放大点,高度和屏幕宽度一样,方便阅读 */
@property (nonatomic,assign)OptimizeLandscapeDisplayType OptimizeDisplayOfLandscapePic;

@optional

- (void)dismissBigPicViews;
- (void)picShouldChange:(CGFloat)offsetX;
- (void)picShouldRecover;

@end


@interface newBigPicView : UIView
@property (nonatomic, weak) id<newBigPicViewDelegate> delegate;

#pragma mark - 公用属性,和上面代理应该有的属性是一样的
@property (nonatomic,assign)CGFloat newBigPicAnimationTime;
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

/** 如果设置为 YES,显示横向图片的时候会稍微放大点,高度和屏幕宽度一样,方便阅读 */
@property (nonatomic,assign)OptimizeLandscapeDisplayType OptimizeDisplayOfLandscapePic;


#pragma mark - 初始化方法
/** 初始化方法,不要把这个 view 加到自己的 view 上面去!! */
+(newBigPicView *)bigPicture;


#pragma mark - 设置图片方法
/** 把图片的 superview 和需要显示的图片在这个 subviews 中的 index 整个一起发过来 ,并且从原始位置放大*/
-(void)setPicView:(UIImageView *)picView;

-(void)setPicView:(UIImageView *)picView withEffect:(BigPicDisplayEffectType)effect;

-(void)setPicView:(UIImageView *)picView withEffect:(BigPicDisplayEffectType)effect largeImageURL:(NSString*)largeImageURL;

-(void)setPicView:(UIImageView *)picView withEffect:(BigPicDisplayEffectType)effect largeImageURL:(NSString*)largeImageURL cornerRadius:(CGFloat)cornerRadius;

/** 把图片的 superview 和需要显示的图片在这个 subviews 中的 index 整个一起发过来 ,没有动画,直接显示*/
-(void)preLoadPicView:(UIImageView *)picView preloadType:(newPicPreloadSide)side;
-(void)preLoadPicView:(UIImageView *)preloadImView;
-(void)preLoadWithLargeImageURL:(NSString*)largeImageURL;

/** 把需要显示的图片 url 发过来,并且指定消失的时候回到哪里 ,打开的时候先黑屏加载完再渐隐出来,消失的时候回到指定的地方*/
-(void)setPicURL:(NSString *)URL returnView:(UIView *)returnView returnRect:(CGRect)returnRect;
@end




