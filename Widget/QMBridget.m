//
//  QMBridget.m
//  Widget
//
//  Created by TanHao on 14-4-27.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "QMBridget.h"

@implementation QMBridget

/*
 如果可以处理该方法,返回NO,
 否则,返回YES
 */

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{
    return NO;
}

/*
 如果存在该属性,返回NO,
 否则,返回YES
 */

+ (BOOL)isKeyExcludedFromWebScript:(const char *)property
{
    return NO;
}

/*
 映射OC方法在JS中的方法名
 */
+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    NSString *selName = NSStringFromSelector(sel);
    selName = [selName stringByReplacingOccurrencesOfString:@":" withString:@""];
    return selName;
}

/*
 映射OC属性在JS中的属性名称
 */
+ (NSString *)webScriptNameForKey:(const char *)property
{
    return [NSString stringWithFormat:@"%s",property];
}

@end
