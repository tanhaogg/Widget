//
//  JSObjectFunction.h
//  JSObject
//
//  Created by TanHao on 14-4-27.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface JSObjectFunction : NSObject
{
    JSValueRef jsObject;
}

+ (id)functionWithJSValue:(JSValueRef)jsRef;

- (id)initWithJSValue:(JSValueRef)jsRef;

- (JSObjectRef)JSObject;

@end