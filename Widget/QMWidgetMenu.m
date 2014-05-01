//
//  QMWidgetMenu.m
//  Widget
//
//  Created by tanhao on 14-4-21.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "QMWidgetMenu.h"

@implementation QMWidgetMenu
@synthesize view;

- (id)init
{
    self = [super init];
    if (self)
    {
        menu = [[NSMenu alloc] initWithTitle:@""];
    }
    return self;
}

- (void)dealloc
{
    [menu release];
    [super dealloc];
}

#pragma mark -

- (void)itemDidClick:(NSMenuItem *)sender
{
    selectedIdx = sender.tag;
}

- (void)addMenuItem:(id)value
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:value action:@selector(itemDidClick:) keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];
    [item release];
}

- (void)setMenuItemEnabledAtIndex:(id)valueIdx :(id)value
{
    if (![valueIdx isKindOfClass:[NSNumber class]] || ![value isKindOfClass:[NSNumber class]])
    {
        return;
    }
    
    NSInteger idx = [valueIdx intValue];
    BOOL enabled = [value boolValue];
    
    NSArray *itemArray = [menu itemArray];
    if (itemArray.count > idx)
    {
        NSMenuItem *item = [itemArray objectAtIndex:idx];
        [item setEnabled:enabled];
    }
}

- (id)getMenuItemEnabledAtIndex:(id)valueIdx
{
    if (![valueIdx isKindOfClass:[NSNumber class]])
    {
        return nil;
    }
    
    NSInteger idx = [valueIdx intValue];
    NSArray *itemArray = [menu itemArray];
    if (itemArray.count > idx)
    {
        NSMenuItem *item = [itemArray objectAtIndex:idx];
        return [NSNumber numberWithBool:item.isEnabled];
    }
    return nil;
}

- (void)setMenuItemTagAtIndex:(id)valueIdx :(id)value
{
    if (![valueIdx isKindOfClass:[NSNumber class]] || ![value isKindOfClass:[NSNumber class]])
    {
        return;
    }
    
    NSInteger idx = [valueIdx intValue];
    NSInteger tag = [value intValue];
    
    NSArray *itemArray = [menu itemArray];
    if (itemArray.count > idx)
    {
        NSMenuItem *item = [itemArray objectAtIndex:idx];
        item.tag = tag;
    }
}

- (id)getMenuItemTagAtIndex:(id)valueIdx
{
    if (![valueIdx isKindOfClass:[NSNumber class]])
    {
        return nil;
    }
    
    NSInteger idx = [valueIdx intValue];
    NSArray *itemArray = [menu itemArray];
    if (itemArray.count > idx)
    {
        NSMenuItem *item = [itemArray objectAtIndex:idx];
        return [NSNumber numberWithInteger:item.tag];
    }
    return nil;
}

- (void)addSeparatorMenuItem:(id)value
{
    NSMenuItem *item = [NSMenuItem separatorItem];
    [menu addItem:item];
}

- (id)popup:(id)value1 :(id)value2
{
    if (![value1 isKindOfClass:[NSNumber class]] || ![value2 isKindOfClass:[NSNumber class]])
    {
        return nil;
    }
    
    NSPoint point = NSMakePoint([value1 floatValue], [value2 floatValue]);
    point.y = NSHeight(self.view.bounds)-point.y;
    
    [menu popUpMenuPositioningItem:nil atLocation:point inView:self.view];
    
    NSMenuItem *itemItem = [menu highlightedItem];
    if (!itemItem)
    {
        return nil;
    }
    
    return [NSNumber numberWithInteger:[menu indexOfItem:itemItem]];
}

@end
