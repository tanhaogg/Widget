//
//  QMWidgetBridge.h
//  Widget
//
//  Created by tanhao on 14-4-16.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "QMBridget.h"
#import "JSObject.h"

@interface QMWidgetBridge : QMBridget
{
    id bunldeIdentifier;
    id identifier;
    id ondragstart;
    id ondragend;
    
    id onshow;
    id onhide;
    id onsync;
    id onremove;
    id onfocus;
    id onblur;
    
    WebView *webView;
}
@property (nonatomic,retain) id bunldeIdentifier;
@property (nonatomic,retain) id identifier;
@property (nonatomic,retain) id ondragstart;
@property (nonatomic,retain) id ondragend;

@property (nonatomic,retain) id onshow;
@property (nonatomic,retain) id onhide;
@property (nonatomic,retain) id onremove;
@property (nonatomic,retain) id onsync; //WorldClock中出现

@property (nonatomic,assign) WebView *webView;

@end
