//
//  QMWidgetHelper.m
//  Widget
//
//  Created by tanhao on 14-5-10.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "QMWidgetHelper.h"

@implementation QMWidgetHelper

+ (NSString *)compatibleHTML:(NSString *)html
{
    if (!html || html.length == 0)
        return html;
    NSMutableString *resultString = [html mutableCopy];
    
    //纠正自闭javascript标签(javascript不允许自闭写法)
    static NSString *slashString = @"/";
    static NSString *closeString = @"</script>";
    NSRange searchRange = NSMakeRange(0, resultString.length);
    while (YES)
    {
        NSRange beginRange = [resultString rangeOfString:@"<script " options:NSCaseInsensitiveSearch range:searchRange];
        if (beginRange.length == 0)
            break;
        
        searchRange = NSMakeRange(NSMaxRange(beginRange), resultString.length-NSMaxRange(beginRange));
        NSRange endRange = [resultString rangeOfString:@">" options:NSCaseInsensitiveSearch range:searchRange];
        if (endRange.length == 0)
            break;
        
        NSRange slashRange = NSMakeRange(endRange.location-slashString.length, slashString.length);
        if ([[resultString substringWithRange:slashRange] isEqualTo:slashString])
        {
            [resultString deleteCharactersInRange:slashRange];
            endRange.location -= slashRange.length;
            
            [resultString insertString:closeString atIndex:NSMaxRange(endRange)];
            endRange.location += closeString.length;
        }
        
        NSUInteger location = NSMaxRange(endRange);
        if (location >= resultString.length)
            break;
        
        searchRange = NSMakeRange(location, resultString.length-location);
    }
    
    return resultString;
}

@end
