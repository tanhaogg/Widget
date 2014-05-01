//
//  QMWidgetMenu.h
//  Widget
//
//  Created by tanhao on 14-4-21.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMBridget.h"

@interface QMWidgetMenu : QMBridget
{
    NSInteger selectedIdx;
    NSMenu *menu;
    NSView *view;
}
@property (nonatomic, assign) NSView *view;
@end
