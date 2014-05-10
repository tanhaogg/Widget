//
//  QMWidgetWindow.h
//  Widget
//
//  Created by tanhao on 14-5-10.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface QMWidgetWindow : NSWindow
{
    WebView *webView;
}
@property (nonatomic, retain) WebView *webView;
@end
