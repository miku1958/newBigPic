//
//  newBigPicView.m
//  newBigPic
//
//  Created by mikun on 2017/2/24.
//  Copyright © 2017年 mikun. All rights reserved.
//

#import "newBigPicView.h"
//#import "wbPicSize.h"
#import "Reachability.h"
#import "MBProgressHUD+MJ.h"
#import "predefine.h"
#import "SDImageCache.h"
#import "SDWebImageManager.h"
#import "UIImageView+WebCache.h"

/*开发日志
 尝试使用 collectionview,无法实现点开图片缩放的效果,会导致线程阻塞(更新,缩放效果靠调整图片 frame 而不是整个 view 可以实现)
 尝试使用 scrollview 实现切换多图的效果,scrollview 会拦截缩放时的 touchbegan 方法,导致缩放的锚点获取不了
 之所以不用 scrollview 来实现缩放是因为 scrollview 的缩放是靠 contextview 来实现的,不能实现横图的
 */





@interface newBigPicView()<UIGestureRecognizerDelegate,UIScrollViewDelegate>{
	CGFloat screenWidth;//这三个全局变量在baseSetting中设置
	CGFloat screenHeight;
	CGFloat screenRatio;
	CGFloat yWhenSameWH;
	
	NSInteger showingIndex;
	NSInteger picCount;
	/** 图片高除以宽的比例 */
	CGFloat picRatio;
	__block CGFloat picVIewScale;
	
	CGRect newFrameOfBigPicView;
	
	UIView *picSuperView;
	
	CGPoint zoomAnchorPoint;
	CGPoint zoomAnchorPointRatio;
	
	CGFloat zoomMinimumZoomScale;
	CGFloat zoomMaxmumZoomScale;
	
	CGFloat realOffsetX;
	/** 保存的上一次pan 的距离 */
	CGFloat lastPanOffsetX;
	
	//一个计数器,防止因为tableview去掉bounces后, 缩放到最小系统以为是不能动的导致pan的translate永远为空
	NSUInteger scalePreventLock;
	
	BOOL opening;
	
	BOOL swiping;
	
	NSString *thumb150whURL;
	
	BOOL shouldRecover;
}

@property (nonatomic,strong)UIScrollView *contentView;
@property (nonatomic,strong)UIImageView *showingPicView;

@property (nonatomic,strong)UIVisualEffectView *bgView;
@end

@implementation newBigPicView

-(CGFloat)animationTime{
	if (!_animationTime) {
		if (self.delegate) {
			_animationTime = [self.delegate animationTime];
		}else{
			_animationTime = 0.25;
		}
	}
	return _animationTime;
}

-(CGFloat)BGAlpha{
	if (!_BGAlpha) {
		if (self.delegate) {
			_BGAlpha = [self.delegate BGAlpha];
		}else{
			_BGAlpha = 0.9;
		}
	}
	return _BGAlpha;
}


+(newBigPicView *)bigPicture{
	newBigPicView *bigPicView = [[newBigPicView alloc]init];
	bigPicView.frame = newKeywindow.frame;
	[bigPicView baseSetting];
	newLog(@"bigPicView:%@",bigPicView);
	bigPicView.clipsToBounds = YES;
	return bigPicView;
}

-(void)baseSetting{
	screenHeight = newScreenHeight;
	screenWidth = newScreenWidth;
	screenRatio =screenHeight/screenWidth;
	yWhenSameWH = (screenHeight-screenWidth)/2;
	picCount =0;
	scalePreventLock =0;
	opening = YES;
	shouldRecover = NO;

	self.backgroundColor = [UIColor clearColor];
	
}
-(UIScrollView *)contentView{
	if (!_contentView) {
		_contentView = [[UIScrollView alloc]initWithFrame:self.bounds];
		_contentView.delegate = self;
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBigPicView)];
		tap.delegate = self;
		[_contentView addGestureRecognizer:tap];
		
		UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapView:)];
		doubleTap.numberOfTapsRequired = 2;
		//		doubleTap.delegate = self;
		[_contentView addGestureRecognizer:doubleTap];
		
		[tap requireGestureRecognizerToFail:doubleTap];
		[tap requireGestureRecognizerToFail:_contentView.panGestureRecognizer];
		
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(savePic)];
		[_contentView addGestureRecognizer:longPress];

		[_contentView setBounces:NO ];
		[_contentView setAlwaysBounceVertical:YES];
		
		[self addSubview:_contentView];
	}
	return _contentView;
}



-(UIImageView *)showingPicView{
	if (!_showingPicView) {
		_showingPicView = [[UIImageView alloc]init];
		_showingPicView.contentMode = UIViewContentModeScaleAspectFill;
		_showingPicView.layer.masksToBounds = YES;
		_showingPicView.userInteractionEnabled = YES;
		[self.contentView addSubview:_showingPicView];
	}
	return _showingPicView;
}

-(void)setPicsView:(UIView *)picsView showIndex:(NSUInteger)idx{
	if (!self.delegate) {
		UIBlurEffect * blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		_bgView = [[UIVisualEffectView alloc]initWithEffect:blur];
		_bgView.frame = self.bounds;
		_bgView.alpha = 0;//改变 alpha 可以改变模糊度
		[self addSubview:_bgView];
	}
	if(!picCount)
		[picsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if (!obj.isHidden) {
				picCount++;
			}
		}];
	
	NSString *picURL = [self setRatioAndGetPicURLWithPicsView:picsView showIndex:idx];
	
	CGRect oriFrameOfBigPicView = [picSuperView convertRect:picsView.subviews[idx].frame toView:nil];
	_showingPicView.frame= oriFrameOfBigPicView;
	[UIView animateWithDuration:self.animationTime animations:^{
		_bgView.alpha = self.BGAlpha;
		if (1<=picRatio) {//如果是竖立的图片:
			_showingPicView.frame = (CGRect){{0, yWhenSameWH}, screenWidth, screenWidth};
		}else{

			if (0.5<=picRatio){
				_showingPicView.frame = (CGRect){{(screenWidth/picRatio-screenWidth)/2, (screenHeight-screenWidth)/2}, screenWidth, screenWidth};
			}else{
				CGFloat picW = screenWidth*1.5;
				CGFloat picH = picW*picRatio;
				_showingPicView.frame = (CGRect){{(picH-screenWidth)/2+(picW-picH), (screenHeight-picH)/2}, picH, picH};
			}
		}
	} completion:^(BOOL finished) {
		newKeywindow.windowLevel = UIWindowLevelAlert;
	}];
	[self getLargePicWithURL:picURL];
}

-(void)preLoadPicsView:(UIView *)picsView showIndex:(NSInteger)idx{
	_showingPicView.alpha = 0;
	if(!picCount)
		[picsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if (!obj.isHidden) {
				picCount++;
			}
		}];
	if (0>idx||idx>=picCount){
		_showingPicView.image = nil;
		return;
	}
	NSString *picURL = [self setRatioAndGetPicURLWithPicsView:picsView showIndex:idx];
	_contentView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
	if (1<=picRatio) {//如果是竖立的图片:
		_showingPicView.frame = (CGRect){{0, yWhenSameWH}, screenWidth, screenWidth};
	}else{
		
		CGFloat picH = screenWidth*picRatio;

		_showingPicView.frame = (CGRect){{(screenWidth-picH)/2, (screenHeight-picH)/2}, picH, picH};

	}
	[UIView animateWithDuration:self.animationTime animations:^{
		_showingPicView.alpha =1;
	}];
	
	[self getLargePicWithURL:picURL];
	
}

-(void)setPicURL:(NSString *)URL sourceView:(UIView *)sourceView sourceRect:(CGRect)sourceRect{
	
}

-(NSString *)setRatioAndGetPicURLWithPicsView:(UIView *)picsView showIndex:(NSUInteger)idx{
	showingIndex = idx;
	picSuperView = picsView;
	UIImageView *showPicView = picSuperView.subviews[idx];
	self.showingPicView.image = showPicView.image;
	screenWidth =newScreenWidth;
	screenHeight = newScreenHeight;
	wbPicSize *picSize = [wbPicSize sharedPicSize];
	
	thumb150whURL = showPicView.sd_imageURL.absoluteString;
	
	NSString *thumb120bURL = [thumb150whURL stringByReplacingOccurrencesOfString:picSize.size150wh withString:picSize.size120b];
	UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:thumb120bURL];
	
	//获取120p 的缩略图获得图片尺寸比例
	CGFloat picSizeWidth = image.size.width;
	CGFloat picSizeHeight = image.size.height;
	picRatio =1;
	if (picSizeHeight) {
		picRatio = picSizeHeight/picSizeWidth;
	}
	return [self getBig_picWiththumbnail_pic:thumb150whURL];
}

-(void)getLargePicWithURL:(NSString *)picURL{
	
	[[SDWebImageManager sharedManager] downloadImageWithURL:newURL(picURL) options:SDWebImageLowPriority|SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
		MBProgressHUD *hud = [MBProgressHUD HUDForView:self];
		
		if(!hud){
			hud = [MBProgressHUD showMessage:@"正在加载:0%" toView:self];
			[hud.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBigPicView)]];
			return ;
		}
		NSString *progress = [NSString stringWithFormat:@"正在加载:%lu%%",(unsigned long)(receivedSize*100/expectedSize)];
		hud.label.text =progress;
		
	} completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
		[MBProgressHUD hideHUDForView:self];
		_showingPicView.image = image;
		CGFloat picSizeWidth = image.size.width;
		CGFloat picSizeHeight = image.size.height;
		picRatio = picSizeHeight/picSizeWidth;
		if (1 <= picRatio) {
			picVIewScale = 1;
			//如果是从150p 来的需要调用这个方法调整尺寸
			CGFloat picH = screenWidth*picRatio;//算出来的高度
			CGFloat picY = (screenHeight-picH)/2;
			[UIView animateWithDuration:self.animationTime animations:^{
				_contentView.contentSize = CGSizeMake(screenWidth, picH);
				_showingPicView.frame = (CGRect){{0, 0}, screenWidth, picH};
				_contentView.contentInset = UIEdgeInsetsMake(0>picY?0:picY, 0, 0, 0);
			}completion:^(BOOL finished) {
				newFrameOfBigPicView = _showingPicView.frame;
				opening = NO;
				picVIewScale = picSizeHeight/screenHeight;
				zoomMinimumZoomScale = 1<picVIewScale?1:picVIewScale;
				zoomMaxmumZoomScale = 1>picVIewScale?1:picVIewScale;
				_contentView.minimumZoomScale = zoomMinimumZoomScale;
				_contentView.maximumZoomScale = zoomMaxmumZoomScale;
			}];
		}else{
			CGFloat picH = _showingPicView.height;
			CGFloat picW = picH/picRatio;//算出来的高度
			[UIView animateWithDuration:self.animationTime animations:^{
				_contentView.contentSize = CGSizeMake(picW, picH);
				//如果不把设置 contentsize 放这里,这个动画结束会导致位置图片高了一点
				//原因是因为线程关系,animate 的completion 会在外层的completion 结束后再运行
				_showingPicView.frame = (CGRect){{0, 0}, picW, picH};
				_contentView.contentInset = UIEdgeInsetsMake((screenHeight-picH)/2, 0, 0, 0);
			}completion:^(BOOL finished) {
				picVIewScale = picSizeWidth/screenWidth;
				
				zoomMinimumZoomScale = 1<picVIewScale?1:picVIewScale;
				zoomMaxmumZoomScale = 1>picVIewScale?1:picVIewScale;
				
				
				_contentView.minimumZoomScale = zoomMinimumZoomScale;
				_contentView.maximumZoomScale = zoomMaxmumZoomScale;
				
				CGFloat frameHeight = screenWidth*picRatio;
				newFrameOfBigPicView = (CGRect){{0, 0}, screenWidth, frameHeight};
				
				opening = NO;
			}];
		}
	}];
	
	if (!self.superview) {
		[newKeywindow.rootViewController.view addSubview:self];
	}
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
	return _showingPicView;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView{
	CGFloat showPicHeight =_showingPicView.height;
	CGFloat showPicWidth =_showingPicView.width;
	_contentView.contentInset = UIEdgeInsetsMake(showPicHeight>screenHeight?0:((screenHeight-showPicHeight)/2), showPicWidth>screenWidth?0:((screenWidth-showPicWidth)/2), 0, 0);
	
}




/**
 *  让 bigpicview 消失
 */
-(void)dismissBigPicView{
	[[SDWebImageManager sharedManager] cancelAll];
	[MBProgressHUD hideHUDForView:self];
	newLog(@"showingIndex:%ld",(long)showingIndex);
	UIImageView *showPicView = picSuperView.subviews[showingIndex];
	CGRect oriFrameOfBigPicView = [picSuperView convertRect:showPicView.frame toView:nil];
	newLog(@"oriFrame:x:%f,y:%f",oriFrameOfBigPicView.origin.x,oriFrameOfBigPicView.origin.y);
	

	CGFloat animateRatio = (picRatio<2?picRatio:2)-1;
	animateRatio = animateRatio>1?animateRatio:1;
	[UIView animateWithDuration:self.animationTime*animateRatio delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
		if ([self.delegate respondsToSelector:@selector(dismissBigPicViews)]){
			[self.delegate dismissBigPicViews];
		}
		_contentView.contentOffset = CGPointZero;
		//            _contentView.zoomScale = 1;
		//加这句话会导致横图的 miniscale 小于1时返回 oriframe 会错位
		_contentView.contentInset = UIEdgeInsetsZero;
		_showingPicView.frame = newFrameOfBigPicView;
		_showingPicView.frame = oriFrameOfBigPicView;
		_bgView.alpha = 0;
	} completion:^(BOOL finished) {
		self.showingPicView = nil;
		newKeywindow.windowLevel = 0;
		[self removeFromSuperview];
	}];
	

	
}

- (void)doubleTapView:(UITapGestureRecognizer *)doubleTap{
	if (_contentView.zoomScale != zoomMinimumZoomScale) {
		[_contentView setZoomScale:zoomMinimumZoomScale animated:YES];
	}else{
		[_contentView setZoomScale:zoomMaxmumZoomScale animated:YES];
	}
}


- (void)savePic{
	UIAlertController *alertcontroller = [UIAlertController
										  alertControllerWithTitle:@"保存图片?"
										  message:@"请选择项目" //tittle和msg会分行,msg字体会小点
										  preferredStyle:UIAlertControllerStyleActionSheet];
	UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		wbPicSize *picSize = [wbPicSize sharedPicSize];

		NSString *sizeOriURL = [thumb150whURL stringByReplacingOccurrencesOfString:picSize.size150wh withString:picSize.sizeOri];
		[[SDWebImageManager sharedManager] downloadImageWithURL:newURL(sizeOriURL) options:SDWebImageLowPriority|SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
			MBProgressHUD *hud = [MBProgressHUD HUDForView:_showingPicView];
			if(!hud){
				hud = [MBProgressHUD showMessage:@"正在加载:0%" toView:self];
				[hud addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBigPicView)]];
				
				return ;
			}
			NSString *progress = [NSString stringWithFormat:@"正在加载:%lu%%",(unsigned long)(receivedSize*100/expectedSize)];
			hud.label.text =progress;
		} completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
			[MBProgressHUD hideHUDForView:self];
			UIImageWriteToSavedPhotosAlbum(_showingPicView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
		}];
		
	}];
	UIAlertAction *cancelAction = [UIAlertAction
								   actionWithTitle:@"取消"
								   style:UIAlertActionStyleCancel
								   handler:^(UIAlertAction * _Nonnull action) {
									   
								   }];
	[alertcontroller addAction:addAction];
	[alertcontroller addAction:cancelAction];
	[newKeywindow.rootViewController presentViewController:alertcontroller animated:YES completion:nil];
	
}
//实现这个方法处理保存结果
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	
	if (error) {
		[MBProgressHUD showError:[NSString stringWithFormat:@"保存出错,错误:%@",error] toView:self];
		return;
	}
	[MBProgressHUD showSuccess:@"保存成功" toView:self];
	
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
	
	return YES;
}

/** 根据网络状态获取图片尺寸 */
-(NSString *)getBig_picWiththumbnail_pic:(NSString *)thumbnail_pic{
	wbPicSize *picSize = [wbPicSize sharedPicSize];
	NSString *oriURL = [thumbnail_pic stringByReplacingOccurrencesOfString:picSize.size150wh withString:picSize.sizeOri];
	
	if([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:oriURL])
		return oriURL;
	
	
#pragma mark - 这里 AFN 出错,检测网络状态一直是-1:unknown 所以改用Reachability
	newLog(@"网络状态%ld",(long)[[Reachability reachabilityForInternetConnection] currentReachabilityStatus]);
	if (ReachableViaWiFi ==
		[[Reachability reachabilityForInternetConnection] currentReachabilityStatus]) {
		newLog(@"是 wifi !!!");
		//lagre 太大,换成mw690是水平9p
		return [thumbnail_pic stringByReplacingOccurrencesOfString:picSize.size150wh withString:picSize.size690w];
	}else{//没有 wifi 就加载优化的大图
		newLog(@"不是 WIFI !!!");
		if ([[thumbnail_pic pathExtension] isEqualToString:@"gif"]) {
			//中图可能加载的 gif 不完整不能播放,所以统一改成 large 版
			return [thumbnail_pic stringByReplacingOccurrencesOfString:picSize.size150wh withString:picSize.size690w];
		}else{
			return [thumbnail_pic stringByReplacingOccurrencesOfString:picSize.size150wh withString:picSize.size440s];
		}
	}
}
@end



