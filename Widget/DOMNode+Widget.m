//
//  DOMNode+Widget.m
//  Widget
//
//  Created by TanHao on 14-5-1.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "DOMNode+Widget.h"

@implementation DOMNode (Widget)

- (BOOL)widgetEditable
{
    if (self.isContentEditable
        || [self.nodeName isEqualToString:@"INPUT"]
        || [self.nodeName isEqualToString:@"TEXTAREA"])
    {
        return YES;
    }
    return NO;
}

- (BOOL)widgetClickable
{
    if ([self widgetEditable])
    {
        return YES;
    }
    
    if ([self.nodeName isEqualToString:@"A"] ||
        [self.nodeName isEqualToString:@"SELECT"])
    {
        return YES;
    }
    return NO;
}

- (BOOL)widgetScrollable
{
    //判定是否是滚动条
    if ([self respondsToSelector:@selector(idName)])
    {
        NSString *idName = [self performSelector:@selector(idName)];
        if ([idName isEqualToString:@"dataScroll"] ||
            [idName isEqualToString:@"iScrollBar"])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)widgetDraggable
{
    BOOL editable = NO;
    BOOL isButton = NO;
    BOOL isLink = NO;
    BOOL isDataScroll = NO;
    BOOL hasMouseEvent = NO;
    
    DOMNode *findNode = self;
    while ([findNode isKindOfClass:[DOMNode class]])
    {
        if ([findNode widgetScrollable] || [findNode widgetClickable])
        {
            return NO;
        }
        
        /*
        //是否可编辑
        if ([self widgetEditable])
        {
            editable = YES;
            break;
        }
         */
        
        /*
        DOMNode *roleNode = [findNode.attributes getNamedItem:@"role"];
        //判定是否是按钮
        if ([roleNode.nodeValue isEqualToString:@"button"])
        {
            isButton = YES;
            break;
        }
        
        //判定是否是链接
        if ([roleNode.nodeValue isEqualToString:@"link"])
        {
            isLink = YES;
            break;
        }
         */
        
        /*
        //是否注册了鼠标事件(暂时取消，因为股票Widget的行为)
        DOMNode *mouseDownNode = [findNode.attributes getNamedItem:@"onmousedown"];
        DOMNode *mouseUpNode = [findNode.attributes getNamedItem:@"onmouseup"];
        DOMNode *clickNode = [findNode.attributes getNamedItem:@"onclick"];
        DOMNode *doubleClickNode = [findNode.attributes getNamedItem:@"ondblclick"];
        if (mouseDownNode || mouseUpNode || clickNode || doubleClickNode)
        {
            hasMouseEvent = YES;
            break;
        }
         */
        
        /*
        //判定是否是滚动条
        if ([findNode respondsToSelector:@selector(idName)] &&
            [[findNode performSelector:@selector(idName)] isEqualToString:@"dataScroll"])
        {
            isDataScroll = YES;
            break;
        }
         */
        findNode = findNode.parentElement;
    }
    return YES;
    
    return !(editable||isButton || isLink ||isDataScroll||hasMouseEvent);
}

@end
