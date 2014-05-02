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
#import "DOMNode+Widget.h"

@interface QMWidgetWindow : NSWindow
{
    WebView *webView;
    QMWidgetBridge *bridge;
}
@property (nonatomic, assign) WebView *webView;
@property (nonatomic, assign) QMWidgetBridge *bridge;
@end

@implementation QMWidgetWindow
@synthesize webView;
@synthesize bridge;

- (BOOL)canBecomeKeyWindow
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
    //NSString *widgetPath = [@"~/Library/Widgets/Bluetooth Switch.wdgt" stringByExpandingTildeInPath];
    NSString *widgetPath = [@"~/Library/Widgets/Wikipedia.wdgt" stringByExpandingTildeInPath];
    //NSString *widgetPath = [@"~/Library/Widgets/PEMDAS.wdgt" stringByExpandingTildeInPath];
    
    widgetBundle = [[NSBundle alloc] initWithPath:widgetPath];
    NSString *bunldeIdentifier = [NSString stringWithFormat:@"widget-%@",widgetBundle.bundleIdentifier];
    NSString *mainHTML = [widgetBundle objectForInfoDictionaryKey:@"MainHTML"];
    NSString *mainPath = [widgetPath stringByAppendingPathComponent:mainHTML];
    
    NSNumber *widthValue = [widgetBundle objectForInfoDictionaryKey:@"Width"];
    NSNumber *heightValue = [widgetBundle objectForInfoDictionaryKey:@"Height"];
    //BOOL allowSystem = [[widgetBundle objectForInfoDictionaryKey:@"AllowSystem"] boolValue];
    
    widgetBridge = [[QMWidgetBridge alloc] init];
    widgetBridge.bunldeIdentifier = bunldeIdentifier;
    widgetBridge.webView = webView;
    
    [self.window setOpaque:NO];
    [self.window setHasShadow:NO];
    [self.window setMovableByWindowBackground:YES];
    [self.window setBackgroundColor:[NSColor clearColor]];
    [(QMWidgetWindow*)self.window setWebView:webView];
    [(QMWidgetWindow*)self.window setBridge:widgetBridge];
    
    if (widthValue && heightValue)
    {
        NSRect frame = self.window.frame;
        NSSize size = NSMakeSize([widthValue floatValue], [heightValue floatValue]);
        frame.size = size;
        [self.window setFrame:frame display:YES];
        [self.window center];
    }
    
    NSString *pluginName = [widgetBundle objectForInfoDictionaryKey:@"Plugin"];
    if (pluginName)
    {
        NSString *pluginPath = [widgetPath stringByAppendingPathComponent:pluginName];
        pluginBundle = [NSBundle bundleWithPath:pluginPath];
        [pluginBundle load];
        Class Plugin = [pluginBundle principalClass];
        plugin = [[Plugin alloc] initWithWebView:webView];
    }
    
    [webView setDrawsBackground:NO];
    [webView setUIDelegate:self];
    [webView setEditingDelegate:self];
    [webView setFrameLoadDelegate:self];
    [webView setPolicyDelegate:self];
    [webView setResourceLoadDelegate:self];
    
    //通过document解析一次的目的在于，防止WebView遇上自闭的script标签无法解释的情况
    NSURL *mainURL = [NSURL fileURLWithPath:mainPath];
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:mainURL options:NSXMLDocumentTidyHTML error:NULL];
    NSString *htmlString = [document XMLString];
    [document release];
    if (htmlString.length > 0)
    {
        [webView.mainFrame loadHTMLString:htmlString baseURL:mainURL];
    }else
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:mainPath]];
        [webView.mainFrame loadRequest:request];
    }
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
#pragma mark WebViewEditingDelegate

//禁止WebView选中元素
- (BOOL)webView:(WebView *)sender shouldChangeSelectedDOMRange:(DOMRange *)currentRange
     toDOMRange:(DOMRange *)proposedRange
       affinity:(NSSelectionAffinity)selectionAffinity
 stillSelecting:(BOOL)flag
{
    if (![proposedRange.startContainer widgetEditable] && ![proposedRange.endContainer widgetEditable])
    {
        return NO;
    }
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
        //寻找所有的语言包路径，放入按语言标准名称为Key的字典
        if (!languageDic)
        {
            languageDic = [[NSMutableDictionary alloc] init];
            NSArray *contentsItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:widgetBundle.bundlePath error:NULL];
            for (NSString *subItem in contentsItems)
            {
                if ([subItem.pathExtension isEqualToString:@"lproj"])
                {
                    NSString *fileName = [subItem stringByDeletingPathExtension];
                    NSString *language = [NSLocale canonicalLanguageIdentifierFromString:fileName];
                    [languageDic setObject:subItem forKey:language];
                }
            }
        }
        
        NSString *fileName = [filePath lastPathComponent];
        NSString *superPath = [filePath stringByDeletingLastPathComponent];
        
        NSArray *preferredLanguages = [NSLocale preferredLanguages];
        for (NSString *language in preferredLanguages)
        {
            NSString *localeName = [languageDic objectForKey:language];
            if (!localeName) continue;
            
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

@end
