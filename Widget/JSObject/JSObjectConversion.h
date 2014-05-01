//
//  JSObjectConversion.h
//  JSObject
//
//  Created by TanHao on 14-4-27.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSObjectDefines.h"

NSString* NSStringWithJSString(JSStringRef string);
NSString* NSStringWithJSValue(JSContextRef context, JSValueRef value);
NSDictionary* NSDictionaryWithJSObject(JSContextRef context, JSObjectRef object);
NSObject* NSObjectWithJSValue(JSContextRef context, JSValueRef value);

JSStringRef JSStringCreateWithNSString(NSString* string);
JSValueRef JSValueWithNSString(JSContextRef context, NSString* string);
JSObjectRef JSObjectWithNSDictionary(JSContextRef context, NSDictionary* dictionary);
JSObjectRef JSObjectWithFunctionBlock(JSContextRef context, JSBlock function);
JSValueRef JSValueWithNSObject(JSContextRef context, id value, JSValueRef* exception);