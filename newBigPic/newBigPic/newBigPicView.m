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


#import "UIImageView+newWebImage.h"

//FIXME:	在图片分辨率和手机分辨率刚刚好的情况下,会不能缩放


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


-(CGPoint)picRatio{
	if (!_picRatio.x) {
		if (self.delegate) {
			_picRatio = [self.delegate picRatio];
		}
	}
	return _picRatio;
}

-(NSString *)exchangeStringToRatioURL{
	if (!_exchangeStringToRatioURL) {
		if (self.delegate) {
			_exchangeStringToRatioURL = [self.delegate exchangeStringToRatioURL];
		}
	}
	return _exchangeStringToRatioURL;
}

-(NSString *)exchangeStringFromThumbnailURL{
	if (!_exchangeStringFromThumbnailURL) {
		if (self.delegate) {
			_exchangeStringFromThumbnailURL = [self.delegate exchangeStringFromThumbnailURL];
		}
	}
	return _exchangeStringFromThumbnailURL;
}

-(NSString *)exchangeStringToMobileBigSizeURL{
	if (!_exchangeStringToMobileBigSizeURL) {
		if (self.delegate) {
			_exchangeStringToMobileBigSizeURL = [self.delegate exchangeStringToMobileBigSizeURL];
		}
	}
	return _exchangeStringToMobileBigSizeURL;
}

-(NSString *)exchangeStringToWIFIBigSizeURL{
	if (!_exchangeStringToWIFIBigSizeURL) {
		if (self.delegate) {
			_exchangeStringToWIFIBigSizeURL = [self.delegate exchangeStringToWIFIBigSizeURL];
		}
	}
	return _exchangeStringToWIFIBigSizeURL;
}

-(NSString *)exchangeStringToOriSizeURL{
	if (!_exchangeStringToOriSizeURL) {
		if (self.delegate) {
			_exchangeStringToOriSizeURL = [self.delegate exchangeStringToOriSizeURL];
		}
	}
	return _exchangeStringToOriSizeURL;
}

-(NSString *)exchangeStringToGifURL{
	if (!_exchangeStringToGifURL) {
		if (self.delegate) {
			_exchangeStringToGifURL = [self.delegate exchangeStringToGifURL];
		}
	}
	return _exchangeStringToGifURL;
}

-(OptimizeLandscapeDisplayType)OptimizeDisplayOfLandscapePic{
	if (!_OptimizeDisplayOfLandscapePic) {
		if (self.delegate) {
			_OptimizeDisplayOfLandscapePic = [self.delegate OptimizeDisplayOfLandscapePic];
		}
	}
	return _OptimizeDisplayOfLandscapePic;
}


-(CGFloat)newBigPicAnimationTime{
	if (!_newBigPicAnimationTime) {
		if (self.delegate) {
			_newBigPicAnimationTime = [self.delegate newBigPicAnimationTime];
		}else{
			_newBigPicAnimationTime = 0.25;
		}
	}
	return _newBigPicAnimationTime;
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
	[bigPicView baseSetting];
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
	self.frame = newKeywindow.frame;
	self.clipsToBounds = YES;
	self.backgroundColor = [UIColor clearColor];
	[self addSubview:self.contentView];
	
	[self initShowingPicView];
	
}
-(UIScrollView *)contentView{
	if (!_contentView) {
		_contentView = [[UIScrollView alloc]initWithFrame:self.bounds];
		_contentView.delegate = self;
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBigPicView)];
		//		tap.delegate = self;
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
		
	}
	return _contentView;
}



-(void)initShowingPicView{
	_showingPicView = [[UIImageView alloc]init];
	_showingPicView.contentMode = UIViewContentModeScaleAspectFill;
	_showingPicView.layer.masksToBounds = YES;
	_showingPicView.userInteractionEnabled = YES;
	[_contentView addSubview:_showingPicView];
}

-(void)setPicView:(UIImageView *)picView{
	if (!self.delegate) {
		UIBlurEffect * blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		_bgView = [[UIVisualEffectView alloc]initWithEffect:blur];
		_bgView.frame = self.bounds;
		_bgView.alpha = 0;//改变 alpha 可以改变模糊度
		[self addSubview:_bgView];
	}
	
	
	NSString *picURL = [self setRatioAndGetPicURLWithPicView:picView];
	
	
	CGRect oriFrameOfBigPicView = [picSuperView convertRect:picView.frame toView:nil];
	_showingPicView.frame= oriFrameOfBigPicView;
	[UIView animateWithDuration:self.newBigPicAnimationTime animations:^{
		_bgView.alpha = self.BGAlpha;
		
		if(self.OptimizeDisplayOfLandscapePic==OptimizeLandscapeDisplayTypeYES&&
		   1>picRatio){
			if (0.5<=picRatio){
				_showingPicView.frame = (CGRect){{(screenWidth/picRatio-screenWidth)/2, (screenHeight-screenWidth)/2}, screenWidth, screenWidth};
			}else{
				CGFloat picW = screenWidth*1.5;
				CGFloat picH = picW*picRatio;
				_showingPicView.frame = (CGRect){{(picH-screenWidth)/2+(picW-picH), (screenHeight-picH)/2}, picH, picH};
			}
		}else{
			_showingPicView.frame = (CGRect){{0, yWhenSameWH}, screenWidth, screenWidth};
		}
		
		
	} completion:^(BOOL finished) {
		newKeywindow.windowLevel = UIWindowLevelAlert;
	}];
	if (picURL) {
		[self getLargePicWithURL:picURL];
	}
}
//FIXME:	需要根据collectionview的特性来修改
#pragma mark - 获取预加载的 picview
-(void)preLoadPicView:(UIImageView *)picView preloadType:(newPicPreloadSide)side{
	
	NSArray<__kindof UIView *> *subs = picView.superview.subviews;
	int i = 0;
	int j = -1;
	for (; i<subs.count;i++) {
		__kindof UIView *obj  = subs[i];
		if (obj == picView) {
			j=i;
			break;
		}
	}
	
	
	
	
	
	
	if(!picCount){
		[picView.superview.subviews enumerateObjectsUsingBlock:^(UIView *imageView, NSUInteger idx, BOOL * _Nonnull stop) {
			if ([imageView.class isSubclassOfClass:[UIImageView class]])
				if(!imageView.isHidden)
					picCount++;
		}];
	}
	
	switch (side) {
		case newPicPreloadSideLeft:
			showingIndex = showingIndex -1;
			j = j-1;
			
			if (j<0) {
				return;
			}
			while (j>=0) {
				if ([subs[j].class isSubclassOfClass:[UIImageView class]]){
					[self preLoadPicView:subs[j]];
					break;
				}
				j = j-1;
			}
			break;
		case newPicPreloadSideRight:
			showingIndex = showingIndex + 1;
			j = j+1;
			if (j>=picCount) {
				return;
			}
			while (j<=picCount) {
				if ([subs[j].class isSubclassOfClass:[UIImageView class]]){
					[self preLoadPicView:subs[j]];
					break;
				}
				j = j+1;
			}
			break;
		default:break;
	}
}

-(void)preLoadPicView:(UIImageView *)preloadImView{
	if (_showingPicView.image == preloadImView.image) {
		return;
	}
	
	_contentView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
	
	if(self.OptimizeDisplayOfLandscapePic==OptimizeLandscapeDisplayTypeYES&&
	   1>picRatio){
		CGFloat picH = screenWidth*picRatio;
		newFrameOfBigPicView = (CGRect){{(screenWidth-picH)/2, (screenHeight-picH)/2}, picH, picH};
	}else{
		newFrameOfBigPicView = (CGRect){{0, yWhenSameWH}, screenWidth, screenWidth};
	}
	
	_showingPicView.frame = newFrameOfBigPicView;
	
	NSString *picURL = [self setRatioAndGetPicURLWithPicView:preloadImView];
	UIImage *largeImage = [UIImage loadImageCacheWithURL:picURL];
	if (largeImage) {
		[self showLargeImage:largeImage withAnimation:NO];
	}else{
		_showingPicView.image =preloadImView.image;
	}
	
	[UIView animateWithDuration:self.newBigPicAnimationTime animations:^{
		_showingPicView.alpha =1;
	}];
	
	if (!largeImage&&picURL){
		[self getLargePicWithURL:picURL];
	}
	if (!self.superview) {
		[newKeywindow.rootViewController.view addSubview:self];
	}
}

-(void)setPicURL:(NSString *)URL sourceView:(UIView *)sourceView sourceRect:(CGRect)sourceRect{
	
}

-(NSString *)setRatioAndGetPicURLWithPicView:(UIImageView *)picView{
	picSuperView = picView.superview;
	showingIndex = -1;
	[picSuperView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (obj == picView) {
			showingIndex = idx;
		}
	}];
	
	if(!picCount){
		[picView.superview.subviews enumerateObjectsUsingBlock:^(UIView *imageView, NSUInteger idx, BOOL * _Nonnull stop) {
			if ([imageView.class isSubclassOfClass:[UIImageView class]])
				if(!imageView.isHidden)
					picCount++;
		}];
	}
	
	if (0>showingIndex||showingIndex>=picCount){
		_showingPicView.image = nil;
		return nil;
	}
	
	
	UIImageView *showPicView = picSuperView.subviews[showingIndex];
	self.showingPicView.image = showPicView.image;
	screenWidth =newScreenWidth;
	screenHeight = newScreenHeight;
	
	thumb150whURL = showPicView.newImageURL.absoluteString;
	NSString *thumb120bURL;
	if (self.picRatio.x) {
		picRatio =self.picRatio.y/self.picRatio.x;
	}else{
		picRatio =1;
		if (self.exchangeStringFromThumbnailURL&&self.exchangeStringToRatioURL) {
			thumb120bURL = [thumb150whURL stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL withString:self.exchangeStringToRatioURL];
			
			UIImage *image = [UIImage newImageFromDiskCacheForKey:thumb120bURL];
			
			//获取120p 的缩略图获得图片尺寸比例
			CGFloat picSizeWidth = image.size.width;
			CGFloat picSizeHeight = image.size.height;
			if (picSizeHeight) {
				picRatio = picSizeHeight/picSizeWidth;
			}
			
		}
	}
	
	return [self getBig_picWiththumbnail_pic:thumb150whURL];
}

-(void)getLargePicWithURL:(NSString *)picURL{

	[UIImage downloadImageWithURL:picURL options:newWebImageLowPriority|newWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger totalSize) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			MBProgressHUD *hud = [MBProgressHUD HUDForView:self];
			
			if(!hud){
				hud = [MBProgressHUD showMessage:@"正在加载:0%" toView:self];
				[hud.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBigPicView)]];
				return ;
			}
			NSString *progress = [NSString stringWithFormat:@"正在加载:%lu%%",(unsigned long)(receivedSize*100/totalSize)];
			hud.label.text =progress;
		});
	} completed:^(UIImage * image, NSData * data, NSError * error, UIImage *__autoreleasing *replaceSaveingImage) {
		[self showLargeImage:image];
	}];
	
	
}
- (void)showLargeImage:(UIImage *)image{
	[self showLargeImage:image withAnimation:YES];
}
- (void)showLargeImage:(UIImage *)image withAnimation:(BOOL)enableAnim{
	if (!image) {
		return ;
		//TODO:	弹出提示
	}
	[MBProgressHUD hideHUDForView:self];
	_showingPicView.image = image;
	
	CGFloat picSizeWidth = image.size.width;
	CGFloat picSizeHeight = image.size.height;
	picRatio = picSizeHeight/picSizeWidth;
	
	CGFloat animTime = self.newBigPicAnimationTime;
	if (!enableAnim) {
		animTime = 0;
	}
	if (self.OptimizeDisplayOfLandscapePic==OptimizeLandscapeDisplayTypeYES&&
		1>picRatio) {
		CGFloat picH = _showingPicView.height;
		CGFloat picW = picH/picRatio;//算出来的高度

		[UIView animateWithDuration:animTime animations:^{
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
	}else{
		picVIewScale = 1;
		//如果是从150p 来的需要调用这个方法调整尺寸
		CGFloat picH = screenWidth*picRatio;//算出来的高度
		CGFloat picY = (screenHeight-picH)/2;
		[UIView animateWithDuration:animTime animations:^{
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
	//FIXME:	在动画快执行结束的时候突然没了
	[UIImage cancelAllDownload];
	[MBProgressHUD hideHUDForView:self];
	newLog(@"showingIndex:%ld",(long)showingIndex);
	UIImageView *showPicView = picSuperView.subviews[showingIndex];
	CGRect oriFrameOfBigPicView = [picSuperView convertRect:showPicView.frame toView:nil];
	newLog(@"oriFrame:x:%f,y:%f",oriFrameOfBigPicView.origin.x,oriFrameOfBigPicView.origin.y);
	
	
	CGFloat animateRatio = (picRatio<2?picRatio:2)-1;
	animateRatio = animateRatio>1?animateRatio:1;
	[UIView animateWithDuration:self.newBigPicAnimationTime*animateRatio delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
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
		NSString *sizeOriURL;
		if (self.exchangeStringFromThumbnailURL&&self.exchangeStringToOriSizeURL) {
			sizeOriURL = [thumb150whURL stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL withString:self.exchangeStringToOriSizeURL];
		}else{
			sizeOriURL = thumb150whURL;
		}
		
		[UIImage downloadImageWithURL:sizeOriURL options:newWebImageLowPriority|newWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger totalSize) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				MBProgressHUD *hud = [MBProgressHUD HUDForView:_showingPicView];
				if(!hud){
					hud = [MBProgressHUD showMessage:@"正在加载:0%" toView:self];
					[hud addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBigPicView)]];
					
					return ;
				}
				NSString *progress = [NSString stringWithFormat:@"正在加载:%lu%%",(unsigned long)(receivedSize*100/totalSize)];
				hud.label.text =progress;
			});
		} completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, UIImage *__autoreleasing *replaceSaveingImage) {
			if (!image) {
				return ;
				//TODO:	弹出提示
			}
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
	if (!self.exchangeStringFromThumbnailURL)
		return nil;
	NSString *oriURL;
	if (self.exchangeStringToOriSizeURL) {
		oriURL = [thumbnail_pic stringByReplacingOccurrencesOfString:_exchangeStringFromThumbnailURL withString:_exchangeStringToOriSizeURL];
		
	}
	
	if([UIImage newImageFromDiskCacheForKey:oriURL])
		return oriURL;
	
	
	newLog(@"网络状态%ld",(long)[[Reachability reachabilityForInternetConnection] currentReachabilityStatus]);
	
	
	if (ReachableViaWiFi == [[Reachability reachabilityForInternetConnection] currentReachabilityStatus]){
		newLog(@"是 WIFI !!!");
		if (self.exchangeStringToWIFIBigSizeURL) {
			return [thumbnail_pic stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL withString:self.exchangeStringToWIFIBigSizeURL];
		}
		if(self.exchangeStringToOriSizeURL){
			return [thumbnail_pic stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL withString:self.exchangeStringToOriSizeURL];
		}
	}else{
		//没有 wifi 就加载优化的大图
		newLog(@"不是 WIFI !!!");
		if (self.exchangeStringToGifURL) {
			if ([[thumbnail_pic pathExtension] isEqualToString:@"gif"]) {
				//中图可能加载的 gif 不完整不能播放,所以统一改成 large 版
				return [thumbnail_pic stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL  withString:self.exchangeStringToGifURL];
			}
			return [thumbnail_pic stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL withString:self.exchangeStringToMobileBigSizeURL];
		}
		
	}
	return thumbnail_pic;
}
@end



