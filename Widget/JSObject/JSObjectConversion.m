//
//  JSObjectConversion.h
//  JSObject
//
//  Created by TanHao on 14-4-27.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "JSObjectConversion.h"
#import "JSObjectBridging.h"
#import "JSObjectFunction.h"

//将JSStringRef转换为NSString
NSString* NSStringWithJSString(JSStringRef string)
{
    if (!string)
        return nil;
    
    CFStringRef stringAsCFString = JSStringCopyCFString(NULL, string);
    NSString* stringAsNSString = CFBridgingRelease(stringAsCFString);
    return stringAsNSString;
}

//将JS的对象转换成NSString,在JS中的行为"someObject.toString()".
NSString* NSStringWithJSValue(JSContextRef context, JSValueRef value) {
    
    if (context == nil || value == nil)
        return nil;
    
    JSStringRef stringValue = JSValueToStringCopy(context, value, NULL);
    
    if (!stringValue)
        return nil;
    
    NSString* returnString = NSStringWithJSString(stringValue);
    JSStringRelease(stringValue);
    return returnString;
}

//将JS对象转换为NSDictionary
NSDictionary* NSDictionaryWithJSObject(JSContextRef context, JSObjectRef object)
{
    if (context == NULL || object == NULL)
        return nil;
    
    JSPropertyNameArrayRef propertyNames = JSObjectCopyPropertyNames(context, object);
    size_t propertyCount = JSPropertyNameArrayGetCount(propertyNames);
    NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithCapacity:propertyCount];
    
    for (int i = 0; i < propertyCount; i++)
    {
        JSStringRef propertyName = JSPropertyNameArrayGetNameAtIndex(propertyNames, i);
        JSValueRef valueRef = JSObjectGetProperty(context, object, propertyName, NULL);
        
        if (!valueRef)
            continue;
        
        NSString *key = NSStringWithJSString(propertyName);
        id value = NSObjectWithJSValue(context, valueRef);
        
        if (!key || !value)
            continue;
        
        [properties setObject:value forKey:key];
    }
    JSPropertyNameArrayRelease(propertyNames);
    
    return [NSDictionary dictionaryWithDictionary:properties];
}

//将JS转换为OC对象
NSObject* NSObjectWithJSValue(JSContextRef context, JSValueRef value)
{
    if (!value)
        return nil;
    
    JSValueRef exception = NULL;
    id returnObjCValue = nil;
    
    switch (JSValueGetType(context, value))
    {
        case kJSTypeNull:
            returnObjCValue = [NSNull null];
            break;
        case kJSTypeBoolean:
            returnObjCValue = @(JSValueToBoolean(context, value));
            break;
        case kJSTypeNumber:
            returnObjCValue = @(JSValueToNumber(context, value, &exception));
            break;
        case kJSTypeString:
            returnObjCValue = NSStringWithJSValue(context, value);
            break;
        case kJSTypeObject:
            if (JSValueIsObjectOfClass(context, value, NativeObjectClass()))
            {
                return (id)JSObjectGetPrivate((JSObjectRef)value);
            }
            else if (JSValueIsObjectOfClass(context, value, BlockFunctionClass()))
            {
                return (id)JSObjectGetPrivate((JSObjectRef)value);
            }
            else if (JSObjectIsFunction(context, (JSObjectRef)value))
            {
                return [JSObjectFunction functionWithJSValue:value];
            }
            else
            {
                return NSDictionaryWithJSObject(context, (JSObjectRef)value);
            }
            break;
        default:
            returnObjCValue = NSStringWithJSValue(context, value);
            break;
    }
    return returnObjCValue;
}

#pragma mark -

//将NSString转换为JSStringRef
JSStringRef JSStringCreateWithNSString(NSString* string)
{
    if (!string)
        return NULL;
    
    CFStringRef cfString = (CFStringRef)string;
    JSStringRef jsString = JSStringCreateWithCFString(cfString);
    return jsString;
}

//将NSString转换为JS对象
JSValueRef JSValueWithNSString(JSContextRef context, NSString* string)
{
    if (context == NULL)
        return NULL;
    
    JSStringRef jsString = JSStringCreateWithNSString(string);
    if (jsString == NULL)
        return JSValueMakeUndefined(context);
    
    JSValueRef stringValue = JSValueMakeString(context, jsString);
    JSStringRelease(jsString);
    
    return stringValue;
}

//将Block转换为JS对象
JSObjectRef JSObjectWithFunctionBlock(JSContextRef context, JSBlock function)
{
    JSObjectRef functionObject = JSObjectMake(context, BlockFunctionClass(), (void*)CFBridgingRetain([function copy]));
    return functionObject;
}

//将OC对象转换为JS对象
JSValueRef JSValueWithNSObject(JSContextRef context, id value, JSValueRef* exception)
{
    if (context == NULL)
        return NULL;
    
    if (!value || [value isKindOfClass:[NSNull class]])
        return JSValueMakeNull(context);
    if ([value isKindOfClass:[NSNumber class]])
        return JSValueMakeNumber(context, [value doubleValue]);
    if ([value isKindOfClass:[NSString class]])
        return JSValueWithNSString(context, value);
    if ([value isKindOfClass:[NSArray class]])
    {
        JSStringRef arrayName = JSStringCreateWithUTF8CString("Array");
        JSObjectRef arrayPrototype = (JSObjectRef)JSObjectGetProperty(context, JSContextGetGlobalObject(context), arrayName, exception);
        JSStringRelease(arrayName);
        
        JSObjectRef array = JSObjectCallAsConstructor(context, arrayPrototype, 0, NULL, exception);
        for (int propertyIndex=0; propertyIndex<[(NSArray*)value count]; propertyIndex++)
        {
            id object = [(NSArray*)value objectAtIndex:propertyIndex];
            JSValueRef jsValue = JSValueWithNSObject(context, object, exception);
            if (jsValue == NULL) jsValue = JSValueMakeUndefined(context);
            
            JSObjectSetPropertyAtIndex(context, array, propertyIndex, jsValue, exception);
        }
        return array;
    }
    if ([NSStringFromClass([value class]) isEqualToString:@"__NSGlobalBlock__"] ||
        [NSStringFromClass([value class]) isEqualToString:@"__NSMallocBlock__"] ||
        [NSStringFromClass([value class]) isEqualToString:@"__NSStackBlock__"])
    {
        return JSObjectWithFunctionBlock(context, (JSBlock)value);
    }
    
    //将NSObject转换为JS对象
    JSObjectRef wrapperObject = JSObjectMake(context, NativeObjectClass(), (void*)CFBridgingRetain(value));
    return wrapperObject;
}

