//
//  NSObject+JSObjectAssociation.h
//  JSObject
//
//  Created by TanHao on 14-4-26.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSObjectDefines.h"

@interface NSObject (JSObjectAssociation)

- (NSDictionary *)jsScriptPropertyTable;
- (NSDictionary *)jsScriptFunctionTable;

- (BOOL)isJSFunction:(JSContextRef)context;
- (id)callJSFunction:(JSContextRef)context parameters:(NSArray *)parameters;

@end
