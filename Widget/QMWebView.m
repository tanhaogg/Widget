//
//  QMWebView.m
//  Widget
//
//  Created by tanhao on 14-4-30.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "QMWebView.h"

@implementation QMWebView

- (NSView *)hitTest:(NSPoint)aPoint
{
    //NSDictionary *info = [super elementAtPoint:aPoint];
    
    //NSLog(@"%@",info);
    
    return [super hitTest:aPoint];
}

@end
