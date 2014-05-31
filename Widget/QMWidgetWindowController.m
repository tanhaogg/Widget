//
//  QMWidgetWindowController.m
//  Widget
//
//  Created by tanhao on 14-5-10.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "QMWidgetWindowController.h"
#import "QMWidgetWindow.h"
#import "QMWidgetHelper.h"
#import "DOMNode+Widget.h"

@interface QMWidgetWindowController ()
@end

@implementation QMWidgetWindowController
@synthesize webView,widgetPath;

- (id)initWithPath:(NSString *)path
{
    self = [super initWithWindowNibName:NSStringFromClass(self.class)];
    if (self)
    {
        widgetPath = [path copy];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
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
        @autoreleasepool
        {
            NSString *pluginPath = [widgetPath stringByAppendingPathComponent:pluginName];
            NSBundle *pluginBundle = [NSBundle bundleWithPath:pluginPath];
            Class Plugin = [pluginBundle principalClass];
            plugin = [[Plugin alloc] initWithWebView:webView];
        }
    }
    
    [webView setDrawsBackground:NO];
    [webView setUIDelegate:self];
    [webView setEditingDelegate:self];
    [webView setFrameLoadDelegate:self];
    [webView setPolicyDelegate:self];
    [webView setResourceLoadDelegate:self];
    
    NSURL *mainURL = [NSURL fileURLWithPath:mainPath];
    NSString *htmlString = [[NSString alloc] initWithContentsOfURL:mainURL encoding:NSUTF8StringEncoding error:NULL];
    htmlString = [QMWidgetHelper compatibleHTML:htmlString];
    if (htmlString)
    {
        [webView.mainFrame loadHTMLString:htmlString baseURL:mainURL];
    }else
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:mainURL];
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
    [webView release];
    [widgetPath release];
    [widgetBridge release];
    [widgetBundle release];
    if (plugin) [plugin release];
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
