//
//  NSObject+JSObjectAssociation.m
//  JSObject
//
//  Created by TanHao on 14-4-26.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "NSObject+JSObjectAssociation.h"
#import <objc/runtime.h>
#import "JSObjectConversion.h"
#import "JSObjectFunction.h"

#define JSObjectScriptPropertyTableKey "JSObjectScriptPropertyTableKey"
#define JSObjectScriptFunctionTableKey "JSObjectScriptFunctionTableKey"

@protocol JSObjectProtocol <NSObject>
- (JSObjectRef)JSObject;
@end

@implementation NSObject (JSObjectAssociation)

- (NSDictionary *)jsScriptPropertyTable
{
    @synchronized(self)
    {
        NSDictionary *propertyTable = nil;
        propertyTable = objc_getAssociatedObject(self, JSObjectScriptPropertyTableKey);
        if (propertyTable)
        {
            return propertyTable;
        }
        
        Class selfClass = [self class];
        
        BOOL respondsExcluded = [selfClass respondsToSelector:@selector(isKeyExcludedFromWebScript:)];
        BOOL respondsScriptName = [selfClass respondsToSelector:@selector(webScriptNameForKey:)];
        
        unsigned int outCount = 0;
        const objc_property_t* propertyList = class_copyPropertyList(selfClass, &outCount);
        NSMutableDictionary *temp_propertyTable = [NSMutableDictionary dictionaryWithCapacity:outCount];
        for (unsigned int idx = 0; idx<outCount; idx++)
        {
            objc_property_t property = propertyList[idx];
            const char* propertyCStr = property_getName(property);
            NSString *propertyName = [NSString stringWithUTF8String:propertyCStr];
            NSString *jsKey = propertyName;
            
            if (respondsExcluded && [selfClass isKeyExcludedFromWebScript:propertyCStr])
            {
                continue;
            }
            
            if (respondsScriptName)
            {
                jsKey = [selfClass webScriptNameForKey:propertyCStr];
            }
            [temp_propertyTable setObject:propertyName forKey:jsKey];
        }
        propertyTable = [NSDictionary dictionaryWithDictionary:temp_propertyTable];
        objc_setAssociatedObject(self, JSObjectScriptPropertyTableKey, propertyTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return propertyTable;
    }
}

- (NSDictionary *)jsScriptFunctionTable
{
    @synchronized(self)
    {
        NSDictionary *functionTable = objc_getAssociatedObject(self, JSObjectScriptFunctionTableKey);
        if (functionTable)
            return functionTable;
        
        Class selfClass = [self class];
        
        BOOL respondsExcluded = [selfClass respondsToSelector:@selector(isSelectorExcludedFromWebScript:)];
        BOOL respondsScriptName = [selfClass respondsToSelector:@selector(webScriptNameForSelector:)];
        
        unsigned int outCount = 0;
        const Method* methodList = class_copyMethodList(selfClass, &outCount);
        NSMutableDictionary *temp_functionTable = [NSMutableDictionary dictionaryWithCapacity:outCount];
        for (unsigned int idx = 0; idx<outCount; idx++)
        {
            Method method = methodList[idx];
            SEL selector = method_getName(method);
            NSString *functionName = NSStringFromSelector(selector);
            NSString *jsKey = functionName;
            
            if (respondsExcluded && [selfClass isSelectorExcludedFromWebScript:selector])
            {
                continue;
            }
            
            if (respondsScriptName)
            {
                jsKey = [selfClass webScriptNameForSelector:selector];
            }else
            {
                jsKey = [functionName stringByReplacingOccurrencesOfString:@"_" withString:@"$_"];
                jsKey = [functionName stringByReplacingOccurrencesOfString:@":" withString:@"_"];
            }
            [temp_functionTable setObject:functionName forKey:jsKey];
        }
        functionTable = [NSDictionary dictionaryWithDictionary:temp_functionTable];
        objc_setAssociatedObject(self, JSObjectScriptFunctionTableKey, functionTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return functionTable;
    }
}

- (BOOL)isJSFunction:(JSContextRef)context
{
    if (![self respondsToSelector:@selector(JSObject)])
        return NO;
    
    JSObjectRef jsRef = [(id<JSObjectProtocol>)self JSObject];
    return JSObjectIsFunction(context, jsRef);
}

- (id)callJSFunction:(JSContextRef)context parameters:(NSArray *)parameters
{
    if ([self respondsToSelector:@selector(JSObject)])
    {
        JSObjectRef jsRef = [(id<JSObjectProtocol>)self JSObject];
        bool isFunction = JSObjectIsFunction(context, jsRef);
        if (isFunction)
        {
            //将OC数组转换成C的数组
            JSValueRef arguments[parameters.count];
            for (int argument = 0; argument < parameters.count; argument++)
            {
                id argumentAsObject = [parameters objectAtIndex:argument];
                JSValueRef argumentAsValue = JSValueWithNSObject(context, argumentAsObject, NULL);
                if (argumentAsValue == NULL)
                    return nil;
                arguments[argument] = argumentAsValue;
            }
            
            //调用JS方法并获取返回值
            JSValueRef returnValue = JSObjectCallAsFunction(context, jsRef, NULL, parameters.count, arguments, NULL);
            return NSObjectWithJSValue(context, returnValue);
        }
    }    
    return nil;
}

@end
