//
//  AppDelegate.m
//  Widget
//
//  Created by tanhao on 14-4-16.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "AppDelegate.h"
#import "QMWidgetWindowController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    widgetMenu = [[NSMenu alloc] init];
    widgetArray = [[NSMutableArray alloc] init];
    
    NSArray *searchArray = @[@"/Library/Widgets/",[@"~/Library/Widgets/iStat nano.wdgt" stringByExpandingTildeInPath]];
    for (NSString *searchPath in searchArray)
    {
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:searchPath error:NULL];
        for (NSString *subItem in contents)
        {
            if ([subItem.pathExtension.lowercaseString isEqualToString:@"wdgt"])
            {
                NSString *widgetPath = [searchPath stringByAppendingPathComponent:subItem];
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:subItem action:@selector(openWidgetAction:) keyEquivalent:@""];
                menuItem.target = self;
                menuItem.representedObject = widgetPath;
                [widgetMenu addItem:menuItem];
                [menuItem release];
            }
        }
    }
    [openFileItem setSubmenu:widgetMenu];
    
    /*
    QMWidgetWindowController *widgetWC = [[QMWidgetWindowController alloc] initWithPath:widgetPath];
    [widgetWC.window orderFront:nil];
     */
}

- (void)openWidgetAction:(id)sender
{
    NSMenuItem *item = (NSMenuItem *)sender;
    QMWidgetWindowController *widgetWC = [[QMWidgetWindowController alloc] initWithPath:item.representedObject];
    [widgetWC.window orderFront:nil];
    [widgetArray addObject:widgetWC];
    [widgetWC release];
}

- (void)dealloc
{
    [widgetMenu release];
    [widgetArray release];
    [super dealloc];
}

@end
