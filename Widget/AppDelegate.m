//
//  AppDelegate.m
//  Widget
//
//  Created by tanhao on 14-4-16.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "QMWidgetSystem.h"

@interface QMWidgetWindow : NSWindow
{
    NSPoint startPoint;
    NSPoint startOrigin;
    BOOL effectDrag;
    
    WebView *webView;
}
@property (nonatomic, assign) WebView *webView;
@end

@implementation QMWidgetWindow
@synthesize webView;

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    startPoint = [NSEvent mouseLocation];
    startOrigin = self.frame.origin;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint point = [NSEvent mouseLocation];
    NSPoint origin = self.frame.origin;
    
    origin.x = startOrigin.x + (point.x - startPoint.x);
    origin.y = startOrigin.y + (point.y - startPoint.y);
    
    [self setFrameOrigin:origin];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    
}

- (void)sendEvent:(NSEvent *)theEvent
{
    NSEventType type = [theEvent type];
    if (!(type == NSLeftMouseDown || type == NSLeftMouseDragged || type == NSLeftMouseUp))
    {
        [super sendEvent:theEvent];
        return;
    }
    
    if ([theEvent type] == NSLeftMouseDown)
    {
        NSPoint point = [theEvent locationInWindow];
        NSDictionary *info = [webView elementAtPoint:point];
        DOMHTMLElement *domNode = [info objectForKey:@"WebElementDOMNode"];
        BOOL editable = [[info objectForKey:@"WebElementIsContentEditableKey"] boolValue];
        
        BOOL isDataScroll = NO;
        BOOL isButton = NO;
        DOMHTMLElement *findNode = domNode;
        while (findNode)
        {
            NSString *roleName = [findNode.attributes getNamedItem:@"role"].nodeValue;
            //判定是否是按钮
            if ([roleName isEqualToString:@"button"])
            {
                isButton = YES;
                break;
            }
            //判定是否是滚动条
            if ([findNode respondsToSelector:@selector(idName)] && [findNode.idName isEqualToString:@"dataScroll"])
            {
                isDataScroll = YES;
                break;
            }
            findNode = (DOMHTMLElement*)findNode.parentElement;
        }
        
        if (!editable && !isDataScroll && !isButton)
        {
            effectDrag = YES;
            [self mouseDown:theEvent];
        }
    }
    else if ([theEvent type] == NSLeftMouseDragged)
    {
        if (effectDrag)
        {
            [self mouseDragged:theEvent];
            return;
        }
    }
    else if ([theEvent type] == NSLeftMouseUp)
    {
        if (effectDrag)
        {
            effectDrag = NO;
            [self mouseUp:theEvent];
        }
    }
    
    [super sendEvent:theEvent];
}

@end

@implementation AppDelegate
@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //NSString *widgetPath = @"/Library/Widgets/Stickies.wdgt";//便笺
    //NSString *widgetPath = @"/Library/Widgets/Dictionary.wdgt";//词典
    //NSString *widgetPath = @"/Library/Widgets/Unit Converter.wdgt";//单位转换程序
    //NSString *widgetPath = @"/Library/Widgets/Translation.wdgt";//翻译
    //NSString *widgetPath = @"/Library/Widgets/Stocks.wdgt";//股票
    //NSString *widgetPath = @"/Library/Widgets/Calculator.wdgt";//计算器
    //NSString *widgetPath = @"/Library/Widgets/Tile Game.wdgt";//拼贴游戏
    //NSString *widgetPath = @"/Library/Widgets/Calendar.wdgt";//日历
    //NSString *widgetPath = @"/Library/Widgets/World Clock.wdgt";//世界时钟
    //NSString *widgetPath = @"/Library/Widgets/Contacts.wdgt";//通讯录
    //NSString *widgetPath = @"/Library/Widgets/ESPN.wdgt";
    //NSString *widgetPath = @"/Library/Widgets/Flight Tracker.wdgt";
    //NSString *widgetPath = @"/Library/Widgets/Movies.wdgt";
    //NSString *widgetPath = @"/Library/Widgets/Ski Report.wdgt";
    
    //第三方
    //NSString *widgetPath = [@"~/Library/Widgets/iStat nano.wdgt" stringByExpandingTildeInPath];
    //NSString *widgetPath = [@"~/Library/Widgets/Screenshot Plus.wdgt" stringByExpandingTildeInPath];
    //NSString *widgetPath = [@"~/Library/Widgets/Padlock.wdgt" stringByExpandingTildeInPath];
    NSString *widgetPath = [@"~/Library/Widgets/Bluetooth Switch.wdgt" stringByExpandingTildeInPath];
    //NSString *widgetPath = [@"~/Library/Widgets/Wikipedia.wdgt" stringByExpandingTildeInPath];
    //NSString *widgetPath = [@"~/Library/Widgets/PEMDAS.wdgt" stringByExpandingTildeInPath];
    
    widgetBundle = [[NSBundle alloc] initWithPath:widgetPath];
    NSString *bunldeIdentifier = [NSString stringWithFormat:@"widget-%@",widgetBundle.bundleIdentifier];
    NSString *mainHTML = [widgetBundle objectForInfoDictionaryKey:@"MainHTML"];
    NSString *mainPath = [widgetPath stringByAppendingPathComponent:mainHTML];
    
    NSNumber *widthValue = [widgetBundle objectForInfoDictionaryKey:@"Width"];
    NSNumber *heightValue = [widgetBundle objectForInfoDictionaryKey:@"Height"];
    //BOOL allowSystem = [[widgetBundle objectForInfoDictionaryKey:@"AllowSystem"] boolValue];
    
    [self.window setOpaque:NO];
    [self.window setHasShadow:NO];
    [self.window setMovableByWindowBackground:YES];
    [self.window setBackgroundColor:[NSColor clearColor]];
    [(QMWidgetWindow*)self.window setWebView:webView];
    
    if (widthValue && heightValue)
    {
        NSRect frame = self.window.frame;
        NSSize size = NSMakeSize([widthValue floatValue], [heightValue floatValue]);
        frame.size = size;
        [self.window setFrame:frame display:YES];
        [self.window center];
    }
    
    widgetBridge = [[QMWidgetBridge alloc] init];
    widgetBridge.bunldeIdentifier = bunldeIdentifier;
    widgetBridge.webView = webView;
    
    NSString *pluginName = [widgetBundle objectForInfoDictionaryKey:@"Plugin"];
    if (pluginName)
    {
        NSString *pluginPath = [widgetPath stringByAppendingPathComponent:pluginName];
        pluginBundle = [NSBundle bundleWithPath:pluginPath];
        [pluginBundle load];
        Class Plugin = [pluginBundle principalClass];
        plugin = [[Plugin alloc] initWithWebView:webView];
    }
    
    [webView setUIDelegate:self];
    [webView setEditingDelegate:self];
    [webView setFrameLoadDelegate:self];
    [webView setPolicyDelegate:self];
    [webView setResourceLoadDelegate:self];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:mainPath]];
    [webView.mainFrame loadRequest:request];
    [webView setDrawsBackground:NO];
}

- (void)viewFrameDidChanged:(NSNotification *)notify
{
    NSView *documentView = [[[webView mainFrame] frameView] documentView];
    if (notify.object == documentView)
    {
        NSRect frame = self.window.frame;
        NSSize size = documentView.bounds.size;
        frame.origin.y -= size.height - NSHeight(frame);
        frame.size = size;
        [self.window setFrame:frame display:YES];
    }
}

- (void)dealloc
{
    [widgetBundle release];
    [widgetBridge release];
    if (plugin) [plugin release];
    if (pluginBundle) [pluginBundle release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark -
#pragma mark WebUIDelegate

- (NSUInteger)webView:(WebView *)sender dragSourceActionMaskForPoint:(NSPoint)point
{
    return WebDragSourceActionNone;
}

- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo
{
    return WebDragDestinationActionNone;
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    return nil;
}

#pragma mark -
#pragma mark WebEditingDelegate

//禁止WebView选中元素
- (BOOL)webView:(WebView *)sender shouldChangeSelectedDOMRange:(DOMRange *)currentRange
     toDOMRange:(DOMRange *)proposedRange
       affinity:(NSSelectionAffinity)selectionAffinity
 stillSelecting:(BOOL)flag
{
    return YES;
}

#pragma mark -
#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    //计算器无需本地支持(如果支持的话,需要实现calculator属性)
    if ([widgetBundle.bundleIdentifier isEqualToString:@"com.apple.widget.calculator"])
    {
        return;
    }
    [windowObject setValue:widgetBridge forKey:@"widget"];
    [plugin windowScriptObjectAvailable:windowObject];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    //隐藏滑块
    NSView <WebDocumentView> *documentView = [[[webView mainFrame] frameView] documentView];
    NSScrollView *scrollView = [documentView enclosingScrollView];
    [scrollView setHasVerticalScroller:NO];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
    [scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
    
    //注册视图大小改变的通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewFrameDidChanged:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:documentView];
}

#pragma mark -
#pragma mark WebResourceLoadDelegate

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    NSURL *url = [request URL];
    if (![url isFileURL])
        return request;
    
    //当加载的资源不存在时，在本地化文件中查找
    NSString *filePath = [[request URL] path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSString *fileName = [filePath lastPathComponent];
        NSString *superPath = [filePath stringByDeletingLastPathComponent];
        
        //NSArray *localizations = [widgetBundle preferredLocalizations];
        
        NSArray *localizations = [widgetBundle localizations];
        
        NSArray *preferredLanguages = [NSLocale preferredLanguages];
        
        for (NSString *localeIdentifier in localizations)
        {
            NSString *localeName = [localeIdentifier stringByAppendingPathExtension:@"lproj"];
            NSString *localeFilePath = [[superPath stringByAppendingPathComponent:localeName] stringByAppendingPathComponent:fileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:localeFilePath])
            {
                request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:localeFilePath]];
                break;
            }
        }
    }
    return request;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
    static NSMutableDictionary *info = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        info = [[NSMutableDictionary alloc] init];
    });
    
    for (WebResource *subSource in dataSource.subresources)
    {
        if (![info objectForKey:[subSource.URL absoluteString]])
        {
            [info setObject:@(YES) forKey:[subSource.URL absoluteString]];
            if ([[subSource.URL absoluteString] hasSuffix:@"js"])
            {
                NSString *string = [[NSString alloc] initWithContentsOfURL:subSource.URL
                                                                  encoding:NSUTF8StringEncoding
                                                                     error:NULL];
                if ([string rangeOfString:@"onfocus"].length > 0)
                {
                    NSLog(@"%@",[subSource.URL absoluteString]);
                }
            }
        }
    }
}

@end
