//
//  newBigPicViewGroup.h
//  mikuWeibo
//
//  Created by mikun on 2017/1/24.
//  Copyright © 2017年 庄黛淳华. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface newBigPicViewGroup : UIView
/** 初始化方法,不要把这个 view 加到自己的 view 上面去!! */
+(newBigPicViewGroup *)bigPictureGroup;

/** 把多图的 view(这个 view 只装了需要显示的UIImageViews) 整个一起发过来 */
-(void)setPicsView:(UIView *)picsView showIndex:(NSUInteger)idx;

@end
