//
//  JSObjectFunction.m
//  JSObject
//
//  Created by TanHao on 14-4-27.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "JSObjectFunction.h"

@implementation JSObjectFunction

+ (id)functionWithJSValue:(JSValueRef)jsRef
{
    return [[[self alloc] initWithJSValue:jsRef] autorelease];
}

- (id)initWithJSValue:(JSValueRef)jsRef
{
    self = [super init];
    if (self)
    {
        //JSValueRef无需操作引用计数
        jsObject = jsRef;
    }
    return self;
}

- (JSObjectRef)JSObject
{
    return (JSObjectRef)jsObject;
}

@end
