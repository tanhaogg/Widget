//
//  QMWidgetWindowController.h
//  Widget
//
//  Created by tanhao on 14-5-10.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "QMWidgetBridge.h"

@protocol WidgetPluginInterface <NSObject>

- (id)initWithWebView:(WebView *)webView;
- (void)windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject;

@end

@interface QMWidgetWindowController : NSWindowController
{
    IBOutlet WebView *webView;
    QMWidgetBridge *widgetBridge;
    
    NSString *widgetPath;
    NSBundle *widgetBundle;
    NSBundle *pluginBundle;
    id<WidgetPluginInterface> plugin;
    
    NSMutableDictionary *languageDic;
}
@property (nonatomic, retain) NSString *widgetPath;

- (id)initWithPath:(NSString *)path;

@end
