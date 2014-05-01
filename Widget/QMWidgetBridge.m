//
//  QMWidgetBridge.m
//  Widget
//
//  Created by tanhao on 14-4-16.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "QMWidgetBridge.h"
#import <JavaScriptCore/JavaScript.h>
#import <QuartzCore/QuartzCore.h>
#import "QMWidgetMenu.h"
#import "QMWidgetSystem.h"

@implementation QMWidgetBridge
@synthesize bunldeIdentifier;
@synthesize identifier,ondragstart,ondragend,onshow,onhide,onsync,onremove;
@synthesize webView;
@synthesize testfunction;

- (id)init
{
    self = [super init];
    if (self)
    {
        identifier = @"mgr";
    }
    return self;
}

#pragma mark - Methods

- (void)log:(NSString *)log
{
    NSLog(@"%@",log);
}

- (void)test:(id)value
{
    JSObjectRef jsRef = [(WebScriptObject*)value JSObject];
    JSContextRef ctx = [[webView mainFrame] globalContext];
    
    bool isFun = JSObjectIsFunction(ctx, jsRef);
    if (isFun)
    {
        JSValueRef obj = JSValueWithNSObject(ctx, self, NULL);
        JSObjectCallAsFunction(ctx, jsRef, NULL, 1, &obj, NULL);
    }
}

- (void)openApplication:(NSString *)value
{
    if (![value isKindOfClass:[NSString class]])
    {
        return;
    }
    
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:value
                                                         options:NSWorkspaceLaunchDefault
                                  additionalEventParamDescriptor:NULL
                                                launchIdentifier:NULL];
}

- (void)openURL:(id)value
{
    if (![value isKindOfClass:[NSString class]])
    {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:value];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (id)preferenceForKey:(id)key
{
    if (!key || ![key isKindOfClass:[NSString class]])
    {
        return nil;
    }
    
    CFStringRef widgetID = (CFStringRef)bunldeIdentifier;
    CFPreferencesAppSynchronize(widgetID);
    id result = (id)CFPreferencesCopyAppValue((__bridge CFStringRef)key, widgetID);
    return [result autorelease];
}

- (void)setPreferenceForKey:(id)value :(id)key
{
    if (!key || ![key isKindOfClass:[NSString class]])
    {
        return;
    }
    
    CFStringRef widgetID = (CFStringRef)bunldeIdentifier;
    CFPreferencesAppSynchronize(widgetID);
    CFPreferencesSetAppValue((CFStringRef)key, (CFPropertyListRef)value, widgetID);
    CFPreferencesAppSynchronize(widgetID);
}

- (void)prepareForTransition:(id)value
{
    CATransition *transition = [CATransition animation];
    transition.type = @"cube";
    transition.subtype = kCATransitionFromRight;
    transition.duration = 0.5;
    NSWindow *window = [[NSApp delegate] performSelector:@selector(window)];
    [window.contentView setWantsLayer:YES];
    [(NSView*)window.contentView display];
    
    //动画
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [window.contentView setWantsLayer:NO];
    }];
    [[window.contentView layer] addAnimation:transition forKey:@""];
    [CATransaction commit];
}

- (void)performTransition
{
    
}

- (void)setCloseBoxOffset:(id)value1 :(id)value2
{
    
}

- (id)system:(id)value1 :(id)value2
{
    if (![value1 isKindOfClass:[NSString class]])
        return nil;
    
    JSContextRef context = [[webView mainFrame] globalContext];
    
    QMWidgetSystem *system = [[QMWidgetSystem alloc] initWithString:value1];
    system.context = context;
    [system startWithCallback:value2];
    return system;
}

- (id)createMenu:(id)value
{
    QMWidgetMenu *widgetMenu = [[QMWidgetMenu alloc] init];
    widgetMenu.view = self.webView;
    
    return [widgetMenu autorelease];
}

//此方法出现在:Movies.wdgt
- (void)resizeAndMoveTo:(id)value1 :(id)value2 :(id)value3 :(id)value4
{
    //此方法不用任何响应,因为外层已经实现了对窗口大小的调整
    /*
    if (![value1 isKindOfClass:[NSNumber class]] ||
        ![value2 isKindOfClass:[NSNumber class]] ||
        ![value3 isKindOfClass:[NSNumber class]] ||
        ![value4 isKindOfClass:[NSNumber class]])
        return;
    
    NSRect frame = NSMakeRect([value1 floatValue],
                              [value2 floatValue],
                              [value3 floatValue],
                              [value4 floatValue]);
    
    NSWindow *window = [[NSApp delegate] performSelector:@selector(window)];
    [window setFrame:frame display:YES];
     */
}

@end
