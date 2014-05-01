//
//  JSObjectBridging.h
//  JSObject
//
//  Created by TanHao on 14-4-27.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "JSObjectBridging.h"
#import "JSObjectConversion.h"
#import "NSObject+JSObjectAssociation.h"
#import <objc/runtime.h>

//快速构造set方法
NS_INLINE SEL PropertySetterSelectorForName(NSString* name)
{
    NSString* capitalizedString = [name stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                withString:[[name substringToIndex:1] capitalizedString]];
    NSString* setterSelectorName = [NSString stringWithFormat:@"set%@:", capitalizedString];
    return NSSelectorFromString(setterSelectorName);
}

//析构时释放内存
void CommonObjectFinalise (JSObjectRef object)
{
    CFBridgingRelease(JSObjectGetPrivate(object));
}

#pragma mark -

//当JS方法被调用时触发
JSValueRef NativeObjectCallAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
    if (!JSObjectIsFunction(ctx, function))
        return JSValueMakeUndefined(ctx);
    
    JSStringRef propertyNameRef = JSStringCreateWithNSString(@"name");
    if (!JSObjectHasProperty(ctx, function, propertyNameRef))
        return JSValueMakeUndefined(ctx);
    
    JSValueRef fuctionNameRef = JSObjectGetProperty(ctx, function, propertyNameRef, exception);
    if (fuctionNameRef == NULL)
        return JSValueMakeUndefined(ctx);
    
    id internalObject = (id)(JSObjectGetPrivate(thisObject));
    NSString* key = NSStringWithJSValue(ctx, fuctionNameRef);
    if (!key)
        return JSValueMakeUndefined(ctx);
    
    NSString *functionName = [[internalObject jsScriptFunctionTable] objectForKey:key];
    if (!functionName)
        return JSValueMakeUndefined(ctx);
    
    SEL methodCallSelector = NSSelectorFromString(functionName);
    if ([internalObject respondsToSelector:methodCallSelector])
    {
        NSMethodSignature *signature = [internalObject methodSignatureForSelector:methodCallSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:methodCallSelector];
        
        id result = nil;
        for (int argument = 0; argument < argumentCount; argument++)
        {
            JSValueRef argumentValue = arguments[argument];
            id argumentObject = NSObjectWithJSValue(ctx, argumentValue);
            if (!argumentObject)
                return JSValueMakeUndefined(ctx);
            [invocation setArgument:&argumentObject atIndex:2+argument];
        }
        [invocation invokeWithTarget:internalObject];
        const char * type = [signature methodReturnType];
        
        if (strcmp(type, @encode(id)) == 0)
        {
            [invocation getReturnValue:&result];
        }
        
        #define INVOCATION_PACKING(_TYPE_) \
        if (strcmp(type, @encode(_TYPE_)) == 0)\
        {\
            _TYPE_ va = 0;\
            [invocation getReturnValue:&va];\
            result = @(va);\
        }
        
        INVOCATION_PACKING(int8_t)
        INVOCATION_PACKING(int16_t)
        INVOCATION_PACKING(int32_t)
        INVOCATION_PACKING(int64_t)
        INVOCATION_PACKING(int64_t)
        
        INVOCATION_PACKING(uint8_t)
        INVOCATION_PACKING(uint16_t)
        INVOCATION_PACKING(uint32_t)
        INVOCATION_PACKING(uint64_t)
        INVOCATION_PACKING(uint64_t)
        
        INVOCATION_PACKING(float)
        INVOCATION_PACKING(double)
        INVOCATION_PACKING(bool)
        return JSValueWithNSObject(ctx, result, exception);
    }
    
    return JSValueMakeUndefined(ctx);
}

//判定是否有该属性(包括方法)时调用
bool NativeObjectHasProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName)
{
    id internalObject = (id)(JSObjectGetPrivate(object));
    NSString* key = NSStringWithJSString(propertyName);
    if (!key)
        return false;
    
    return [[internalObject jsScriptPropertyTable] objectForKey:key] || [[internalObject jsScriptFunctionTable] objectForKey:key];
}

//为属性赋值时被调用
bool NativeObjectSetProperty (JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef* exception)
{
    id internalObject = (id)(JSObjectGetPrivate(object));
    NSString* key = NSStringWithJSString(propertyName);
    NSObject* objectValue = NSObjectWithJSValue(ctx, value);
    
    if (!key || !objectValue)
        return false;
    
    NSString* properyName = [[internalObject jsScriptPropertyTable] objectForKey:key];
    if (!propertyName)
        return false;
    
    SEL setterSelector = PropertySetterSelectorForName(properyName);
    if ([internalObject respondsToSelector:setterSelector])
    {
        [internalObject performSelector:setterSelector withObject:objectValue];
        return true;
    }
    
    return false;
}

//在JS中获取属性(包括方法)时被调用
JSValueRef NativeObjectGetProperty (JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception)
{
    id internalObject = (id)(JSObjectGetPrivate(object));
    NSString* key = NSStringWithJSString(propertyName);
    
    //属性
    NSString *propertySelName = [[internalObject jsScriptPropertyTable] objectForKey:key];
    if (propertySelName)
    {
        SEL getterSelector = NSSelectorFromString(propertySelName);
        if ([internalObject respondsToSelector:getterSelector])
        {
            id value = [internalObject performSelector:getterSelector];
            return JSValueWithNSObject(ctx, value, exception);
        }
    }
    
    //方法
    NSString *methodSelName = [[internalObject jsScriptFunctionTable] objectForKey:key];
    if (methodSelName)
    {
        JSObjectRef function = JSObjectMakeFunctionWithCallback(ctx, propertyName, &NativeObjectCallAsFunction);
        return function;
    }
    
    return JSValueMakeUndefined(ctx);
}

JSClassDefinition NativeObjectClassDefinition = {
    0, // version
    0, // attributes
    "NativeObject", // class name
    NULL, // parent class
    NULL, // static values
    NULL, // static functions
    NULL, // initialise callback
    &CommonObjectFinalise, // finalise callback
    &NativeObjectHasProperty, // has property callback
    &NativeObjectGetProperty, // get property callback
    &NativeObjectSetProperty, // set property callback
    NULL, // delete property callback
    NULL, // get property names callback
    NULL, // call as function callback
    NULL, // call as constructor callback
    NULL, // has instance callback
    NULL  // convert to type callback
};

//OC对象在JS的类型描述
JSClassRef NativeObjectClass()
{
    static JSClassRef _class = nil;
    
    if (_class == nil)
        _class = JSClassCreate(&NativeObjectClassDefinition);
    
    return _class;
}

#pragma mark - Block

//Block在JS中被调用时
JSValueRef BlockFunctionCallAsFunction (JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
    JSBlock functionBlock = (JSBlock)(JSObjectGetPrivate(function));
    
    NSMutableArray* functionParameters = [NSMutableArray array];
    for (int arg = 0; arg < argumentCount; arg++)
    {
        [functionParameters addObject:NSObjectWithJSValue(ctx, arguments[arg])];
    }
    
    id returnValue = nil;
    returnValue = functionBlock(functionParameters);
    return JSValueWithNSObject(ctx, returnValue, exception);
}

JSClassDefinition BlockFunctionClassDefinition = {
    0, // version
    0, // attributes
    "BlockFunction", // class name
    NULL, // parent class
    NULL, // static values
    NULL, // static functions
    NULL, // initialise callback
    &CommonObjectFinalise, // finalise callback
    NULL, // has property callback
    NULL, // get property callback
    NULL, // set property callback
    NULL, // delete property callback
    NULL, // get property names callback
    &BlockFunctionCallAsFunction, // call as function callback
    NULL, // call as constructor callback
    NULL, // has instance callback
    NULL // convert to type callback
};

//在JS中Block的类型描述
JSClassRef BlockFunctionClass()
{
    static JSClassRef _class = nil;
    
    if (_class == nil)
        _class = JSClassCreate(&BlockFunctionClassDefinition);
    
    return _class;
}