//
//  AppDelegate.h
//  Widget
//
//  Created by tanhao on 14-4-16.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSMenu *widgetMenu;
    NSMutableArray *widgetArray;
    IBOutlet NSMenuItem *openFileItem;
}
@end
