//
//  JSObjectDefines.h
//  JSObject
//
//  Created by TanHao on 14-4-27.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

typedef id(^JSBlock)(NSArray* parameters);

@protocol JSWebScripting <NSObject>

+ (NSString *)webScriptNameForSelector:(SEL)selector;
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector;
+ (NSString *)webScriptNameForKey:(const char *)name;
+ (BOOL)isKeyExcludedFromWebScript:(const char *)name;

@end
