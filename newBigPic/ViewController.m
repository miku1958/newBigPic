//
//  ViewController.m
//  newBigPic
//
//  Created by mikun on 2017/2/24.
//  Copyright © 2017年 mikun. All rights reserved.
//

#import "ViewController.h"
#import "newBigPicViewGroup.h"
#import "UIImageView+WebCache.h"
@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIView *ImageViews;


@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	NSString *path = [[NSBundle mainBundle] pathForResource:@"picURLs.plist" ofType:nil];
	__block NSArray<NSString *> *urls = [NSArray arrayWithContentsOfFile:path];
	__block int i=0;
	[_ImageViews.subviews enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL * _Nonnull stop) {
		if ([imageView.class isSubclassOfClass:[UIImageView class]]){
			[imageView sd_setImageWithURL:[NSURL URLWithString:urls[i++]]];
		}
	}];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}
- (IBAction)picSelected:(UITapGestureRecognizer*)tap {

	
	newBigPicViewGroup *bigPicViewGroup = [newBigPicViewGroup bigPictureGroup];
	
	[bigPicViewGroup setPicView:tap.view];
	
	
}


@end
