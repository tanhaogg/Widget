//
//  QMWidgetSystem.m
//  Widget
//
//  Created by TanHao on 14-4-26.
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "QMWidgetSystem.h"

@implementation QMWidgetSystem
@synthesize context;
@synthesize outputString,errorString,status;
@synthesize onreadoutput,onreaderror;

- (id)initWithString:(NSString *)string
{
    self = [super init];
    if (self)
    {
        /*
        //先将空白地址转义
        NSString *aliasString = @"_$_";
        NSString *commandString = [string stringByReplacingOccurrencesOfString:@"\\ " withString:aliasString];
        
        //通过空格分离出可执行文件和各个参数
        NSArray *components = [commandString componentsSeparatedByString:@" "];
        if (components.count == 0)
        {
            [self release];
            return nil;
        }
        
        //可执行文件地址
        NSString *taskPath = [components objectAtIndex:0];
        taskPath = [taskPath stringByReplacingOccurrencesOfString:aliasString withString:@" "];
        if (![[NSFileManager defaultManager] fileExistsAtPath:taskPath])
        {
            [self release];
            return nil;
        }
        
        task = [[NSTask alloc] init];
        [task setLaunchPath:taskPath];
        
        //参数
        NSMutableArray *arguments = [NSMutableArray array];
        for (int i=1; i<components.count; i++)
        {
            NSString *arg = [components objectAtIndex:i];
            arg = [arg stringByReplacingOccurrencesOfString:aliasString withString:@"\\ "];
            [arguments addObject:arg];
        }
        [task setArguments:arguments];
         */
        
        if (!string)
        {
            [self release];
            return nil;
        }
        
        task = [[NSTask alloc] init];
        [task setLaunchPath:@"/bin/sh"];
        [task setArguments:@[@"-c",string]];
        
        //设定输入输出通道
        NSPipe *inputPipe = [NSPipe pipe];
        NSPipe *outputPipe = [NSPipe pipe];
        NSPipe *errorPipe = [NSPipe pipe];
        
        [task setStandardInput:inputPipe];
        [task setStandardOutput:outputPipe];
        [task setStandardError:errorPipe];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedData:)
                                                     name:NSFileHandleDataAvailableNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(taskDidTerminate:)
                                                     name:NSTaskDidTerminateNotification
                                                   object:task];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [task release];
    if (outputString) [outputString release];
    if (errorString) [errorString release];
    if (status) [status release];
    if (onreadoutput) [onreadoutput release];
    if (onreaderror) [onreaderror release];
    if (jsCallback) [jsCallback release];
    [super dealloc];
}

- (void)receivedData:(NSNotification *)notify
{
    NSFileHandle *readHandle = [notify object];
    NSData *availableData = [readHandle availableData];
    NSString *availableString = [[[NSString alloc] initWithData:availableData encoding:NSUTF8StringEncoding] autorelease];
    
    if (availableString.length == 0)
        return;
    
    //标准输出和标准错误
    if (readHandle == [[task standardOutput] fileHandleForReading])
    {
        self.outputString = outputString ? [outputString stringByAppendingString:availableString] : availableString;
        
        if (onreadoutput)
            [onreadoutput callJSFunction:context parameters:@[availableString]];
    }
    
    else if (readHandle == [[task standardError] fileHandleForReading])
    {
        self.errorString = errorString ? [errorString stringByAppendingString:availableString] : availableString;
        
        if (onreaderror)
            [onreaderror callJSFunction:context parameters:@[availableString]];
    }
    
    [readHandle waitForDataInBackgroundAndNotify];
}

- (void)taskDidTerminate:(NSNotification *)notify
{
    if (status)
        return;
    
    status = @([task terminationStatus]);
    
    //标准输出和标准错误
    NSFileHandle *outputHandle = [[task standardOutput] fileHandleForReading];
    NSFileHandle *errorHandle = [[task standardError] fileHandleForReading];
    
    NSData *outputData = [outputHandle readDataToEndOfFile];
    NSString *outputAvailableString = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
    self.outputString = outputString ? [outputString stringByAppendingString:outputAvailableString] : outputAvailableString;
    
    NSData *errorData = [errorHandle readDataToEndOfFile];
    NSString *errorAvailableString = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
    self.errorString = errorString ? [errorString stringByAppendingString:errorAvailableString] : errorAvailableString;
    
    //如果绑定了事件，将最后获得的数据发送到事件
    if (onreadoutput && outputAvailableString.length>0)
        [onreadoutput callJSFunction:context parameters:@[outputAvailableString]];
    
    if (onreaderror && errorAvailableString.length>0)
        [onreaderror callJSFunction:context parameters:@[errorAvailableString]];
    
    //调用JS的回调
    if (jsCallback)
    {
        [jsCallback callJSFunction:context parameters:@[self]];
    }
}

#pragma mark -

- (void)startWithCallback:(id)callback
{
    [task launch];
    
    NSFileHandle *outputHandle = [[task standardOutput] fileHandleForReading];
    NSFileHandle *errorHandle = [[task standardError] fileHandleForReading];
    
    if (!callback || ![callback isJSFunction:context])
    {
        [task waitUntilExit];
        [self taskDidTerminate:nil];
    }else
    {
        //监听标准输出与错误输出
        [outputHandle waitForDataInBackgroundAndNotify];
        [errorHandle waitForDataInBackgroundAndNotify];
        
        //保存JS回调方法
        if (jsCallback != callback)
        {
            [jsCallback release];
            jsCallback = [callback retain];
        }
    }
}

- (void)cancel
{
    [task terminate];
}

- (void)write:(NSString *)string
{
    if (!string || string.length==0)
        return;
    
    NSFileHandle *inputHandle = [[task standardInput] fileHandleForWriting];
    [inputHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)close
{
    NSFileHandle *inputHandle = [[task standardInput] fileHandleForWriting];
    [inputHandle closeFile];
}

@end
