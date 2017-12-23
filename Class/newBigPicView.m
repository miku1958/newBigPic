//
//  newBigPicView.m
//  newBigPic
//
//  Created by mikun on 2017/2/24.
//  Copyright © 2017年 mikun. All rights reserved.
//

#import "newBigPicView.h"
#import "Reachability.h"
#import "MBProgressHUD.h"
#import "predefine.h"
#import <Photos/Photos.h>

#import "newWebImage.h"
#import "newBigPicViewGroup.h"


//FIXME:	在图片分辨率和手机分辨率刚刚好的情况下,会不能缩放


@interface newBigPicView()<UIGestureRecognizerDelegate,UIScrollViewDelegate>{
	CGFloat _screenWidth;//这三个全局变量在baseSetting中设置
	CGFloat _screenHeight;
	CGFloat _screenRatio;
	CGFloat _yWhenSameWH;
	
	NSInteger _showingIndex;
	NSInteger _picCount;
	/** 图片高除以宽的比例 */
	CGFloat _picHWRatio;
	__block CGFloat _picVIewScale;
	
	CGRect _newFrameOfBigPicView;
	
	UIView *_picSuperView;
	
	CGPoint _zoomAnchorPoint;
	CGPoint _zoomAnchorPointRatio;
	
	CGFloat _zoomMinimumZoomScale;
	CGFloat _zoomMaxmumZoomScale;
	
	CGFloat _realOffsetX;
	/** 保存的上一次pan 的距离 */
	CGFloat _lastPanOffsetX;
	
	//一个计数器,防止因为tableview去掉bounces后, 缩放到最小系统以为是不能动的导致pan的translate永远为空
	NSUInteger _scalePreventLock;
	
	BOOL _opening;
	
	BOOL _swiping;
	
	NSString *_thumb150whURL;
	
	BOOL _shouldRecover;
	
	double _date_s;
	BOOL _isSingleTap;
	double _overtime;
	
	BigPicDisplayEffectType _effect;
	
	CGFloat thumbCornerRadius;
}

@property (nonatomic,strong)UIScrollView *contentView;
@property (nonatomic,strong)UIImageView *showingPicView;

@property (nonatomic,strong)UIVisualEffectView *bgView;
@end

@implementation newBigPicView


+(newBigPicView *)bigPicture{
	newBigPicView *bigPicView = [[newBigPicView alloc]init];
	[bigPicView baseSetting];
	return bigPicView;
}

-(void)baseSetting{
	_screenHeight = newBPScreenHeight;
	_screenWidth = newBPScreenWidth;
	_screenRatio =_screenHeight/_screenWidth;
	_yWhenSameWH = (_screenHeight-_screenWidth)/2;
	_picCount =0;
	_scalePreventLock =0;
	_opening = YES;
	_shouldRecover = NO;
	self.frame = newBPKeywindow.frame;
	self.clipsToBounds = YES;
	self.backgroundColor = [UIColor clearColor];
	[self addSubview:self.contentView];
	
	[self initShowingPicView];
	
	_isSingleTap = YES;
	_overtime = 0.23;
}
-(UIScrollView *)contentView{
	if (!_contentView) {
		_contentView = [[UIScrollView alloc]initWithFrame:self.bounds];
		_contentView.delegate = self;
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
		//		tap.delegate = self;
		[_contentView addGestureRecognizer:tap];
		
		[tap requireGestureRecognizerToFail:_contentView.panGestureRecognizer];
		
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(savePic)];
		[_contentView addGestureRecognizer:longPress];
		
		[_contentView setBounces:NO ];
		[_contentView setAlwaysBounceVertical:YES];
#ifdef __IPHONE_11_0
		if (@available(iOS 11.0, *)) {
			[_contentView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
		}
#endif
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
	[self setPicView:picView withEffect:BigPicDisplayEffectTypeScale largeImageURL:nil];
}
-(void)setPicView:(UIImageView *)picView  withEffect:(BigPicDisplayEffectType)effect{
	[self setPicView:picView withEffect:effect largeImageURL:nil];
}
-(void)setPicView:(UIImageView *)picView  withEffect:(BigPicDisplayEffectType)effect largeImageURL:(NSString*)largeImageURL{
	[self setPicView:picView withEffect:effect largeImageURL:largeImageURL cornerRadius:0];
}

-(void)setPicView:(UIImageView *)picView withEffect:(BigPicDisplayEffectType)effect largeImageURL:(NSString*)largeImageURL cornerRadius:(CGFloat)cornerRadius{
	thumbCornerRadius = cornerRadius;
	_showingPicView.layer.cornerRadius = cornerRadius;
	_effect = effect;
	_picSuperView = picView.superview;
	_showingPicView.image = picView.image;
	if (!self.delegate) {
		UIBlurEffect * blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		_bgView = [[UIVisualEffectView alloc]initWithEffect:blur];
		_bgView.frame = self.bounds;
		_bgView.alpha = 0;//改变 alpha 可以改变模糊度
		[self insertSubview:_bgView atIndex:0];
	}
	NSString *picURL;
	if (largeImageURL) {
		picURL = largeImageURL;
	}else{
		picURL = [self setRatioAndGetPicURLWithPicView:picView];
	}
	
	_contentView.contentOffset = CGPointZero;
	_contentView.contentInset = UIEdgeInsetsZero;
	
	switch (_effect) {
		case BigPicDisplayEffectTypeEaseInOut:
			_showingPicView.frame = (CGRect){{self.center.x, self.center.y}, 0, 0};
			_showingPicView.alpha = 0;
			break;
		case BigPicDisplayEffectTypeScale:
			_showingPicView.frame = [_picSuperView convertRect:picView.frame toView:nil];
			break;
	}
	if (!self.superview) {
		[newBPKeywindow.rootViewController.view addSubview:self];
	}
	
	[self showingPicViewCornerRadius:0 AnimationTime:self.newBigPicAnimationTime];
	
	[UIView animateWithDuration:self.newBigPicAnimationTime animations:^{
		
		switch (_effect) {
			case BigPicDisplayEffectTypeEaseInOut:
				_showingPicView.alpha = 1;
				break;
			case BigPicDisplayEffectTypeScale:
				
				break;
		}
		
		_bgView.alpha = self.BGAlpha;
		
		if (_delegate) {
			if(self.OptimizeDisplayOfLandscapePic==OptimizeLandscapeDisplayTypeYES&&
			   1>_picHWRatio){
				if (0.5<=_picHWRatio){
					_showingPicView.frame = (CGRect){{(_screenWidth/_picHWRatio-_screenWidth)/2, (_screenHeight-_screenWidth)/2}, _screenWidth, _screenWidth};
				}else{
					CGFloat picW = _screenWidth*1.5;
					CGFloat picH = picW*_picHWRatio;
					_showingPicView.frame = (CGRect){{(picH-_screenWidth)/2+(picW-picH), (_screenHeight-picH)/2}, picH, picH};
				}
			}else{
				_showingPicView.frame = (CGRect){{0, _yWhenSameWH}, _screenWidth, _screenWidth};
			}
		}else{
			[self showLargeImage:_showingPicView.image withAnimation:NO];
		}
		
	} completion:^(BOOL finished) {
		newBPKeywindow.windowLevel = UIWindowLevelAlert;
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
	
	if(!_picCount){
		[picView.superview.subviews enumerateObjectsUsingBlock:^(UIView *imageView, NSUInteger idx, BOOL * _Nonnull stop) {
			if ([imageView.class isSubclassOfClass:[UIImageView class]])
				if(!imageView.isHidden)
					_picCount++;
		}];
	}
	
	switch (side) {
		case newPicPreloadSideLeft:
			_showingIndex = _showingIndex -1;
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
			_showingIndex = _showingIndex + 1;
			j = j+1;
			if (j>=_picCount) {
				return;
			}
			while (j<=_picCount) {
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
	[self preLoadPicView:preloadImView largeImageURL:nil];
}

-(void)preLoadWithLargeImageURL:(NSString*)largeImageURL{
	[self preLoadPicView:nil largeImageURL:largeImageURL];
}

-(void)preLoadPicView:(UIImageView *)preloadImView largeImageURL:(NSString*)largeImageURL{
	if (preloadImView && _showingPicView.image == preloadImView.image) {
		return;
	}
	if (largeImageURL&&[_showingPicView.newImageURL.absoluteString isEqualToString:largeImageURL]) {
		return;
	}
	_contentView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
	
	if(self.OptimizeDisplayOfLandscapePic==OptimizeLandscapeDisplayTypeYES&&
	   1>_picHWRatio){
		CGFloat picH = _screenWidth*_picHWRatio;
		_newFrameOfBigPicView = (CGRect){{(_screenWidth-picH)/2, (_screenHeight-picH)/2}, picH, picH};
	}else{
		_newFrameOfBigPicView = (CGRect){{0, _yWhenSameWH}, _screenWidth, _screenWidth};
	}
	
	_showingPicView.frame = _newFrameOfBigPicView;
	
	NSString *picURL;
	if (largeImageURL) {
		picURL = largeImageURL;
	}else{
		picURL = [self setRatioAndGetPicURLWithPicView:preloadImView];
	}
	UIImage *largeImage = [UIImage loadImageCacheWithURL:picURL];
	if (largeImage) {
		[self showLargeImage:largeImage withAnimation:NO];
	}else if(preloadImView){
		_showingPicView.image =preloadImView.image;
	}
	
	[UIView animateWithDuration:self.newBigPicAnimationTime animations:^{
		_showingPicView.alpha =1;
	}];
	
	if (!largeImage&&picURL){
		[self getLargePicWithURL:picURL];
	}
	if (!self.superview) {
		[newBPKeywindow.rootViewController.view addSubview:self];
	}
}

-(NSString *)setRatioAndGetPicURLWithPicView:(UIImageView *)picView{
	_picSuperView = picView.superview;
	_showingIndex = -1;
	[_picSuperView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *obj, NSUInteger idx, BOOL *stop) {
		if (obj == picView) {
			_showingIndex = idx;
		}
	}];
	
	if(!_picCount){
		[picView.superview.subviews enumerateObjectsUsingBlock:^(UIView *imageView, NSUInteger idx, BOOL * _Nonnull stop) {
			if ([imageView.class isSubclassOfClass:[UIImageView class]])
				if(!imageView.isHidden)
					_picCount++;
		}];
	}
	
	if (0>_showingIndex||_showingIndex>=_picCount){
		_showingPicView.image = nil;
		return nil;
	}
	
	
	UIImageView *showPicView = _picSuperView.subviews[_showingIndex];
	self.showingPicView.image = showPicView.image;
	_screenWidth =newBPScreenWidth;
	_screenHeight = newBPScreenHeight;
	
	_thumb150whURL = showPicView.newImageURL.absoluteString;
	NSString *thumb120bURL;
	if (self.picRatio.x) {
		_picHWRatio =self.picRatio.y/self.picRatio.x;
	}else{
		_picHWRatio =1;
		if (self.exchangeStringFromThumbnailURL&&self.exchangeStringToRatioURL) {
			thumb120bURL = [_thumb150whURL stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL withString:self.exchangeStringToRatioURL];
			
			UIImage *image = [UIImage newImageFromDiskCacheForKey:thumb120bURL];
			
			//获取120p 的缩略图获得图片尺寸比例
			CGFloat picSizeWidth = image.size.width;
			CGFloat picSizeHeight = image.size.height;
			if (picSizeHeight) {
				_picHWRatio = picSizeHeight/picSizeWidth;
			}
			
		}
	}
	
	return [self getBig_picWiththumbnail_pic:_thumb150whURL];
}

-(void)getLargePicWithURL:(NSString *)picURL{

	[UIImage downloadImageWithURL:picURL options:newWebImageLowPriority|newWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger totalSize) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			MBProgressHUD *hud = [MBProgressHUD HUDForView:self];
			
			if(!hud){
				hud = [self showMessage:@"正在加载:0%" toView:self];
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
	[MBProgressHUD hideHUDForView:self animated:YES];
	_showingPicView.image = image;
	
	CGFloat picSizeWidth = _showingPicView.image.size.width;
	CGFloat picSizeHeight = _showingPicView.image.size.height;
	_picHWRatio = picSizeHeight/picSizeWidth;
	
	CGFloat animTime = self.newBigPicAnimationTime;
	if (!enableAnim) {
		animTime = 0;
	}
	if (self.OptimizeDisplayOfLandscapePic==OptimizeLandscapeDisplayTypeYES&&
		1>_picHWRatio) {
		CGFloat picH = _showingPicView.frame.size.height;
		CGFloat picW = picH/_picHWRatio;//算出来的高度

		[UIView animateWithDuration:animTime animations:^{
			_contentView.contentSize = CGSizeMake(picW, picH);
			//如果不把设置 contentsize 放这里,这个动画结束会导致位置图片高了一点
			//原因是因为线程关系,animate 的completion 会在外层的completion 结束后再运行
			_showingPicView.frame = (CGRect){{0, 0}, picW, picH};
			_contentView.contentInset = UIEdgeInsetsMake((_screenHeight-picH)/2, 0, 0, 0);
		}completion:^(BOOL finished) {
			_picVIewScale = picSizeWidth/_screenWidth;
			
			_zoomMinimumZoomScale = 0.5<_picVIewScale?0.5:_picVIewScale;
			_zoomMaxmumZoomScale = 2>_picVIewScale?2:_picVIewScale;
			
			
			_contentView.minimumZoomScale = _zoomMinimumZoomScale;
			_contentView.maximumZoomScale = _zoomMaxmumZoomScale;
			
			CGFloat frameHeight = _screenWidth*_picHWRatio;
			_newFrameOfBigPicView = (CGRect){{0, 0}, _screenWidth, frameHeight};
			
			_opening = NO;
		}];
	}else{
		_picVIewScale = 1;
		//如果是从150p 来的需要调用这个方法调整尺寸
		CGFloat picH = _screenWidth*_picHWRatio;//算出来的高度
		CGFloat picY = (_screenHeight-picH)/2;
		[UIView animateWithDuration:animTime animations:^{
			_contentView.contentSize = CGSizeMake(_screenWidth, picH);
			_showingPicView.frame = (CGRect){{0, 0}, _screenWidth, picH};
			_contentView.contentInset = UIEdgeInsetsMake(0>picY?0:picY, 0, 0, 0);
		}completion:^(BOOL finished) {
			_newFrameOfBigPicView = _showingPicView.frame;
			_opening = NO;
			_picVIewScale = _showingPicView.image.size.width/_screenWidth;
			_zoomMinimumZoomScale = 1<_picVIewScale?1:_picVIewScale;
			_zoomMaxmumZoomScale = 1>_picVIewScale?1:_picVIewScale;
			_contentView.minimumZoomScale = _zoomMinimumZoomScale;
			_contentView.maximumZoomScale = _zoomMaxmumZoomScale;
		}];
	}
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
	return _showingPicView;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView{
	CGFloat showPicHeight =_showingPicView.frame.size.height;
	CGFloat showPicWidth =_showingPicView.frame.size.width;
	_contentView.contentInset = UIEdgeInsetsMake(showPicHeight>_screenHeight?0:((_screenHeight-showPicHeight)/2), showPicWidth>_screenWidth?0:((_screenWidth-showPicWidth)/2), 0, 0);
	
}

- (void)tapView:(UITapGestureRecognizer*)tap{
	if (_date_s<0.1) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_overtime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			if (_isSingleTap) {
				[self dismissBigPicView];
			}
			_date_s = 0;
		});
		_date_s = CFAbsoluteTimeGetCurrent();
		_isSingleTap = YES;
		return;
	}
	if (CFAbsoluteTimeGetCurrent()-_date_s<_overtime) {
		_isSingleTap = NO;
		_date_s = 0;
		[self scaleView];
	}
}



/**
 *  让 bigpicview 消失
 */
-(void)dismissBigPicView{
	[UIImage cancelAllDownload];
	[MBProgressHUD hideHUDForView:self animated:YES];

	UIImageView *showPicView = _picSuperView.subviews[_showingIndex];
	CGRect oriFrameOfBigPicView = [_picSuperView convertRect:showPicView.frame toView:nil];

	
	
	CGFloat animateRatio = (_picHWRatio<2?_picHWRatio:2)-1;
	animateRatio = animateRatio>1?animateRatio:1;
	
	[self showingPicViewCornerRadius:thumbCornerRadius AnimationTime:self.newBigPicAnimationTime*animateRatio];
	
	[UIView animateWithDuration:self.newBigPicAnimationTime*animateRatio delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		BOOL isFromURL = NO;

		if (_delegate) {
			if ([_delegate respondsToSelector:@selector(dismissBigPicViews)]){
				[_delegate dismissBigPicViews];
			}
			UIView *delegate = _delegate;
			if ([delegate valueForKey:@"_fromURL"]) {
				isFromURL = YES;
			}
		}
		if (isFromURL) {
			self.alpha = 0;
		}else{
			_contentView.contentOffset = CGPointZero;
			//            _contentView.zoomScale = 1;
			//加这句话会导致横图的 miniscale 小于1时返回 oriframe 会错位
			_contentView.contentInset = UIEdgeInsetsZero;
			_showingPicView.frame = _newFrameOfBigPicView;
			_showingPicView.frame = oriFrameOfBigPicView;
			_bgView.alpha = 0;
		}
	} completion:^(BOOL finished) {
		self.showingPicView = nil;
		newBPKeywindow.windowLevel = 0;
		[self removeFromSuperview];
	}];
	
}
- (void)showingPicViewCornerRadius:(CGFloat)cornerRadius AnimationTime:(CGFloat)time {
	__weak typeof(self) _self = self;
	CABasicAnimation *anim = [CABasicAnimation animation];
	anim.keyPath = @"cornerRadius";
	anim.toValue = @(cornerRadius);
	anim.duration = time;
	anim.removedOnCompletion = NO;
	// 保持最新的状态（默认值是kCAFillModeRemoved移除动画）
	anim.fillMode = kCAFillModeForwards;
	[_showingPicView.layer addAnimation:anim forKey:@"cornerRadius"];
}

- (void)scaleView{
	if (_contentView.zoomScale != _zoomMinimumZoomScale) {
		[_contentView setZoomScale:_zoomMinimumZoomScale animated:YES];
	}else{
		[_contentView setZoomScale:_zoomMaxmumZoomScale animated:YES];
	}
}


- (void)savePic{
	UIAlertController *alertcontroller = [UIAlertController
										  alertControllerWithTitle:@"保存图片?"
										  message:nil //tittle和msg会分行,msg字体会小点
										  preferredStyle:UIAlertControllerStyleActionSheet];
	UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		//FIXME:	判断请求
		PHAuthorizationStatus author = [PHPhotoLibrary authorizationStatus];
		if (author == PHAuthorizationStatusRestricted ||
			author == PHAuthorizationStatusDenied){
			
			UIAlertController *alertCtr = [UIAlertController
												  alertControllerWithTitle:@"没有权限保存图片"
												  message:@"是否跳转到设置?" //tittle和msg会分行,msg字体会小点
												  preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"跳转到设置" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
				NSString *urlstr =@"prefs:root=Privacy&path=PHOTOS";
				NSURL *url;
				if (UIDevice.currentDevice.systemVersion.doubleValue <10.0) {
					url = [NSURL URLWithString:urlstr];
				}else{
					url = [NSURL URLWithString:[urlstr stringByReplacingOccurrencesOfString:@"prefs" withString:@"App-Prefs"]];;
				}
		
				if ([UIApplication.sharedApplication canOpenURL:url]) {
					[UIApplication.sharedApplication openURL:url];
				}
			}];
			[alertCtr addAction:confirmAction];
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) { }];
			[alertCtr addAction:cancelAction];
			[newBPKeywindow.rootViewController presentViewController:alertCtr animated:YES completion:nil];
			return;
		}
		NSString *sizeOriURL;
		if (self.exchangeStringFromThumbnailURL&&self.exchangeStringToOriSizeURL) {
			sizeOriURL = [_thumb150whURL stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL withString:self.exchangeStringToOriSizeURL];
		}else{
			sizeOriURL = _thumb150whURL;
		}
		if (!sizeOriURL.length) {
			UIImageWriteToSavedPhotosAlbum(_showingPicView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
			[self showMessage:@"正在保存" toView:self];
			return;
		}
		
		[UIImage downloadImageWithURL:sizeOriURL options:newWebImageLowPriority|newWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger totalSize) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				MBProgressHUD *hud = [MBProgressHUD HUDForView:_showingPicView];
				if(!hud){
					hud = [self showMessage:@"正在加载:0%" toView:self];
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
			[MBProgressHUD hideHUDForView:self animated:YES];
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
	[newBPKeywindow.rootViewController presentViewController:alertcontroller animated:YES completion:nil];
	
}
//实现这个方法处理保存结果
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	
	if (error) {
		[self showError:[NSString stringWithFormat:@"保存出错,错误:%@",error] toView:self];
		return;
	}
	[self showSuccess:@"保存成功" toView:self];
	
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
	
	if (ReachableViaWiFi == [[Reachability reachabilityForInternetConnection] currentReachabilityStatus]){

		if (self.exchangeStringToWIFIBigSizeURL) {
			return [thumbnail_pic stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL withString:self.exchangeStringToWIFIBigSizeURL];
		}
		if(self.exchangeStringToOriSizeURL){
			return [thumbnail_pic stringByReplacingOccurrencesOfString:self.exchangeStringFromThumbnailURL withString:self.exchangeStringToOriSizeURL];
		}
	}else{
		//没有 wifi 就加载优化的大图
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

#pragma mark - 同步superView的懒加载
-(CGPoint)picRatio{
	if (!_picRatio.x) {
		_picRatio = _delegate?_delegate.picRatio:CGPointZero;
	}
	return _picRatio;
}

-(NSString *)exchangeStringToRatioURL{
	if (!_exchangeStringToRatioURL) {
		_exchangeStringToRatioURL = _delegate?_delegate.exchangeStringToRatioURL:nil;
	}
	return _exchangeStringToRatioURL;
}

-(NSString *)exchangeStringFromThumbnailURL{
	if (!_exchangeStringFromThumbnailURL) {
		_exchangeStringFromThumbnailURL = _delegate?_delegate.exchangeStringFromThumbnailURL:nil;
	}
	return _exchangeStringFromThumbnailURL;
}

-(NSString *)exchangeStringToMobileBigSizeURL{
	if (!_exchangeStringToMobileBigSizeURL) {
		_exchangeStringToMobileBigSizeURL = _delegate?_delegate.exchangeStringToMobileBigSizeURL:nil;
	}
	return _exchangeStringToMobileBigSizeURL;
}

-(NSString *)exchangeStringToWIFIBigSizeURL{
	if (!_exchangeStringToWIFIBigSizeURL) {
		_exchangeStringToWIFIBigSizeURL = _delegate?_delegate.exchangeStringToWIFIBigSizeURL:nil;
	}
	return _exchangeStringToWIFIBigSizeURL;
}

-(NSString *)exchangeStringToOriSizeURL{
	if (!_exchangeStringToOriSizeURL) {
		_exchangeStringToOriSizeURL = _delegate?_delegate.exchangeStringToOriSizeURL:nil;
	}
	return _exchangeStringToOriSizeURL;
}

-(NSString *)exchangeStringToGifURL{
	if (!_exchangeStringToGifURL) {
		_exchangeStringToGifURL = _delegate?_delegate.exchangeStringToGifURL:nil;
	}
	return _exchangeStringToGifURL;
}

-(OptimizeLandscapeDisplayType)OptimizeDisplayOfLandscapePic{
	if (!_OptimizeDisplayOfLandscapePic) {
		_OptimizeDisplayOfLandscapePic = _delegate?_delegate.OptimizeDisplayOfLandscapePic:OptimizeLandscapeDisplayTypeNO;
	}
	return _OptimizeDisplayOfLandscapePic;
}


-(CGFloat)newBigPicAnimationTime{
	if (!_newBigPicAnimationTime) {
		_newBigPicAnimationTime = _delegate?_delegate.newBigPicAnimationTime:0.25;
	}
	return _newBigPicAnimationTime;
}

-(CGFloat)BGAlpha{
	if (!_BGAlpha) {
		_BGAlpha = _delegate?_delegate.BGAlpha:1;
	}
	return _BGAlpha;
}

#pragma mark - 因为cocoapod的原因所以把MBProgress+MJ的内容搬到这里
- (MBProgressHUD *)showMessage:(NSString *)message toView:(UIView *)view {
	if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
	// 快速显示一个提示信息
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.label.text = message;
	// 隐藏时候从父控件中移除
	hud.removeFromSuperViewOnHide = YES;
	// YES代表需要蒙版效果
	//    hud.dimBackground = YES;
	return hud;
}

- (void)show:(NSString *)text icon:(NSString *)icon view:(UIView *)view
{
	if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
	// 快速显示一个提示信息
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.label.text = text;
	// 设置图片
	hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"MBProgressHUD.bundle/%@", icon]]];
	// 再设置模式
	hud.mode = MBProgressHUDModeCustomView;
	
	// 隐藏时候从父控件中移除
	hud.removeFromSuperViewOnHide = YES;
	
	// 1秒之后再消失
	[hud hideAnimated:YES afterDelay:0.7];
}

#pragma mark 显示错误信息
- (void)showError:(NSString *)error toView:(UIView *)view{
	[self show:error icon:@"error.png" view:view];
}


- (void)showSuccess:(NSString *)success toView:(UIView *)view
{
	[self show:success icon:@"success.png" view:view];
}
@end



