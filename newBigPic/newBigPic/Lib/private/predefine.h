//
//  predefine.h
//  newBigPic
//
//  Created by mikun on 2017/2/24.
//  Copyright © 2017年 mikun. All rights reserved.
//

#import "UIView+Position.h"


#define newKeywindow [UIApplication sharedApplication].keyWindow

#define newScreenWidth [UIScreen mainScreen].bounds.size.width

#define newScreenHeight [UIScreen mainScreen].bounds.size.height

#define newURL(unUTF8str) [NSURL URLWithString:unUTF8str]

#ifdef DEBUG
//在调试界面输出信息
#define newLog(...) NSLog(__VA_ARGS__)
//在调试界面输出详细信息(函数,行号)
#define newDetailLog(...) NSLog(@"%s %d \n %@\n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])
//模拟设备被独占，线程被占用，用于测试性能
#define newSleep(time) [NSThread sleepForTimeInterval:time]
#else
#define newLog(...)
#define newDetailLog(...)
#define newSleep(time)
#endif
