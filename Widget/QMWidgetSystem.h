//
//  QMWidgetSystem.h
//  Widget
//
//  Created by TanHao on 14-4-26.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMBridget.h"
#import "JSObject.h"

@interface QMWidgetSystem : QMBridget
{
    NSString *outputString;
    NSString *errorString;
    NSNumber *status;
    
    id onreadoutput;
    id onreaderror;
    
    NSTask *task;
    JSContextRef context;
    id jsCallback;
}
@property (nonatomic, assign) JSContextRef context;

@property (nonatomic, retain) NSString *outputString;
@property (nonatomic, retain) NSString *errorString;
@property (nonatomic, retain) NSNumber *status;
@property (nonatomic, retain) id onreadoutput;
@property (nonatomic, retain) id onreaderror;

- (id)initWithString:(NSString *)string;

- (void)startWithCallback:(id)callback;

- (void)cancel;
- (void)write:(NSString *)string;
- (void)close;

@end
