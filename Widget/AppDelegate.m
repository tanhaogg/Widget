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
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:20] retain];
    NSImage *statusImage = [NSImage imageNamed:@"dashboard"];
    [statusImage setSize:NSMakeSize(20, 20)];
    statusItem.image = statusImage;
    
    NSMenu *statusMenu = [[NSMenu alloc] init];
    NSMenuItem *openItem = [[NSMenuItem alloc] init];
    openItem.title = @"Open...";
    [statusMenu addItem:openItem];
    [openItem release];
    
    NSMenuItem *quitItem = [[NSMenuItem alloc] init];
    quitItem.title = @"Quit";
    quitItem.keyEquivalent = @"Q";
    quitItem.target = self;
    quitItem.action = @selector(quitAction:);
    [statusMenu addItem:quitItem];
    [quitItem release];
    
    [statusItem setMenu:statusMenu];
    [statusMenu release];
    
    widgetMenu = [[NSMenu alloc] init];
    widgetArray = [[NSMutableArray alloc] init];
    
    NSArray *searchArray = @[@"/Library/Widgets/",[@"~/Library/Widgets/" stringByExpandingTildeInPath]];
    for (NSString *searchPath in searchArray)
    {
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:searchPath error:NULL];
        for (NSString *subItem in contents)
        {
            if ([subItem.pathExtension.lowercaseString isEqualToString:@"wdgt"])
            {
                NSString *widgetPath = [searchPath stringByAppendingPathComponent:subItem];
                NSMenuItem *menuItem = [[NSMenuItem alloc] init];
                NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:widgetPath];
                [image setSize:NSMakeSize(16, 16)];
                menuItem.image = image;
                menuItem.title = [[NSFileManager defaultManager] displayNameAtPath:widgetPath];
                menuItem.action = @selector(openWidgetAction:);
                menuItem.target = self;
                menuItem.representedObject = widgetPath;
                [widgetMenu addItem:menuItem];
                [menuItem release];
            }
        }
    }
    [openItem setSubmenu:widgetMenu];
}

- (void)windowWillClose:(NSWindow *)aWindow
{
    QMWidgetWindowController *widgetWC = nil;
    for (QMWidgetWindowController *windowController in widgetArray)
    {
        if (windowController.window == aWindow)
        {
            widgetWC = windowController;
            break;
        }
    }
    if (widgetWC)
    {
        NSArray *items = [widgetMenu itemArray];
        for (NSMenuItem *item in items)
        {
            if ([item.representedObject isEqualToString:widgetWC.widgetPath])
            {
                [item setState:NSOffState];
            }
        }
        
        [widgetWC close];
        [widgetArray removeObject:widgetWC];
    }
}

- (void)quitAction:(id)sender
{
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    [NSApp terminate:nil];
}

- (void)openWidgetAction:(id)sender
{
    NSMenuItem *item = (NSMenuItem *)sender;
    NSString *widgetPath = [item representedObject];
    
    QMWidgetWindowController *widgetWC = nil;
    for (QMWidgetWindowController *windowController in widgetArray)
    {
        if ([windowController.widgetPath isEqualTo:widgetPath])
        {
            widgetWC = windowController;
            break;
        }
    }
    
    if (widgetWC)
    {
        [item setState:NSOffState];
        [widgetWC.window close];
        [widgetArray removeObject:widgetWC];
    }else
    {
        [item setState:NSOnState];
        widgetWC = [[QMWidgetWindowController alloc] initWithPath:widgetPath];
        [widgetWC.window makeKeyAndOrderFront:nil];
        [widgetArray addObject:widgetWC];
        [widgetWC release];
    }
}

- (void)dealloc
{
    [statusItem release];
    [widgetMenu release];
    [widgetArray release];
    [super dealloc];
}

@end
