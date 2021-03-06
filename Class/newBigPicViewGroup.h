//
//  newBigPicViewGroup.h
//  newBigPic
//
//  Created by mikun on 2017/2/24.
//  Copyright © 2017年 mikun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "newBigPicView.h"

@interface newBigPicViewGroup : UICollectionView<newBigPicViewDelegate>

#pragma mark - 公用属性
@property (nonatomic,assign)CGFloat newBigPicAnimationTime;
@property (nonatomic,assign)CGFloat BGAlpha;


#pragma mark - 缩略图比例
/** 如果预览图片不是正方形的，需要按原比例显示，需要设置这个 */
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
+(newBigPicViewGroup *)bigPictureGroup;

#pragma mark - 设置图片方法
/** 把装了多UIImageview的View中,要显示的UIImageview传进来 */
-(void)setPicView:(UIImageView *)picView;

/** 把需要显示的图片 url 发过来*/
-(void)setPicURLs:(NSArray *)URLs showingIndex:(NSUInteger)showingIndex;

@end
