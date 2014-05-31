//
//  QMWidgetWindow.m
//  Widget
//
//  Created by tanhao on 14-5-10.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "QMWidgetWindow.h"
#import "DOMNode+Widget.h"

@implementation QMWidgetWindow
@synthesize webView;

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

- (void)sendEvent:(NSEvent *)theEvent
{
    if (theEvent.type != NSLeftMouseDown)
    {
        [super sendEvent:theEvent];
        return;
    }
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    
    //获得鼠标点击的元素
    NSPoint point = [theEvent locationInWindow];
    NSDictionary *info = [webView elementAtPoint:point];
    DOMNode *domNode = [info objectForKey:@"WebElementDOMNode"];
    BOOL editable = [[info objectForKey:@"WebElementIsContentEditableKey"] boolValue];
    
    //如果元素可以编辑或不可以拖动,让Web处理
    if (editable ||
        ![domNode isKindOfClass:[DOMNode class]] ||
        ![domNode widgetDraggable])
    {
        [super sendEvent:theEvent];
        return;
    }
    
    //以下代码的目的是当有拖动事件时，截获鼠标点击事件，否则执行点击事件
    NSPoint startPoint = [NSEvent mouseLocation];
    NSPoint startOrigin = self.frame.origin;
    BOOL mouseDragged = NO;
    
    NSEvent *nextEvent = nil;
    while ((nextEvent = [self nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask]))
    {
        if (nextEvent.type == NSLeftMouseDragged)
        {
            mouseDragged = YES;
            
            NSPoint point = [NSEvent mouseLocation];
            NSPoint origin = self.frame.origin;
            origin.x = startOrigin.x + (point.x - startPoint.x);
            origin.y = startOrigin.y + (point.y - startPoint.y);
            [self setFrameOrigin:origin];
        }
        
        if (nextEvent.type == NSLeftMouseUp)
        {
            if (!mouseDragged)
            {
                [super sendEvent:theEvent];
                [super sendEvent:nextEvent];
            }
            break;
        }
    }
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if (theEvent.type == NSKeyDown &&
        theEvent.keyCode == 13 &&
        (theEvent.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask)
    {
        [[NSApp delegate] performSelector:@selector(windowWillClose:) withObject:self];
        return YES;
    }
    return [super performKeyEquivalent:theEvent];
}

- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}

/*
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return ([menuItem action] == @selector(performClose:)) ? YES : [super validateMenuItem:menuItem];
}
 */

- (void)dealloc
{
    if (webView) [webView release];
    [super dealloc];
}

@end
