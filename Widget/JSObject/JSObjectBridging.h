//
//  JSObjectBridging.h
//  JSObject
//
//  Created by TanHao on 14-4-27.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "JSObjectDefines.h"

// Returns the shared class definition for block function wrappers.
JSClassRef BlockFunctionClass();

// Returns the shared class definition for native object wrappers.
JSClassRef NativeObjectClass();