//
//  const.h
//  LemonDecibel
//
//  Created by fax on 2019/4/22.
//  Copyright © 2019 Guangxi Four Jun Technology Co.,Ltd. All rights reserved.
//

#ifndef const_h
#define const_h


#endif /* const_h */

// 屏幕适配
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

#define STATUSTBAR_HEIGHT [UIApplication sharedApplication].statusBarFrame.size.height

#define SYSTEMNAV_HEIGHT 44.0

#define NAVBAR_HEIGHT (STATUSTBAR_HEIGHT+SYSTEMNAV_HEIGHT)

#define TABBAR_HEIGHT (SCREEN_HEIGHT>=812.0 ? 83 : 49)

#define BOTTOMHEIGHT (SCREEN_HEIGHT>=812.0 ? 34 : 0)

#define RATE SCREEN_WIDTH/375
