//
//  AppDelegate.h
//  Widget
//
//  Created by tanhao on 14-4-16.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "QMWidgetBridge.h"

@protocol WidgetPluginInterface <NSObject>

- (id)initWithWebView:(WebView *)webView;
- (void)windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject;

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow *window;
    IBOutlet WebView *webView;
    QMWidgetBridge *widgetBridge;
    
    NSBundle *widgetBundle;
    NSBundle *pluginBundle;
    id<WidgetPluginInterface> plugin;
}
@property (retain) IBOutlet NSWindow *window;

@end
