//
//  UDPSocket.m
//  flamegrace@hotmail.com
//
//  Created by Flame Grace on 16/12/22.
//  Copyright © 2016年 flamegrace@hotmail.com. All rights reserved.
//

#import "UDPSocket.h"
#import "GCDAsyncUdpSocket.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

@interface UDPSocket() <GCDAsyncUdpSocketDelegate>

//是否在搜寻设备中
@property (readwrite, assign, nonatomic) BOOL isBinding;
//是否已经打开广播模式
@property (readwrite, assign, nonatomic) BOOL isOpenBroadcast;
//当前监听的端口
@property (readwrite, assign, nonatomic) uint32_t bindPort;
//搜寻套接字
@property (strong, nonatomic)GCDAsyncUdpSocket *udpScocket;

@property (strong, nonatomic) dispatch_queue_t delegateQueue;

@end

@implementation UDPSocket

- (instancetype)init
{
    if(self = [super init])
    {
        [self restartSocket];
    }
    return self;
}



//开始监听端口
- (BOOL)bindToPort:(uint32_t)port  error:(NSError **)error
{
    if(self.isBinding && self.bindPort == port)
    {
        return YES;
    }
    self.isBinding = [self.udpScocket bindToPort:port error:error];
    if(self.isBinding)
    {
        self.bindPort = port;
    }
    return self.isBinding;
}


- (BOOL)bindRandomPort
{
    uint32_t startCheckPort = 4666;
    BOOL bindOk = NO;
    while (!bindOk)
    {
        bindOk = [self bindToPort:startCheckPort error:nil];
        if(bindOk)
        {
            self.bindPort = startCheckPort;
            break;
        }
        startCheckPort ++;
        if(startCheckPort > 65536)
        {
            break;
        }
    }
    return bindOk;
}

- (BOOL)enableBroadcast:(BOOL)enable error:(NSError **)error
{
     self.isOpenBroadcast = [self.udpScocket enableBroadcast:enable error:error];
    return self.isOpenBroadcast;
}

- (BOOL)beginReceiving:(NSError **)error
{
    BOOL flag = [self.udpScocket beginReceiving:error];
    return flag;
}

- (void)pauseReceiving
{
    [self.udpScocket pauseReceiving];
}

- (void)sendData:(NSData *)data
          toHost:(NSString *)host
            port:(uint16_t)port
     withTimeout:(NSTimeInterval)timeout
             tag:(long)tag
{
    [self.udpScocket sendData:data toHost:host port:port withTimeout:timeout tag:tag];
}


- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port error:(NSError **)errPtr
{
    BOOL flag = [self.udpScocket connectToHost:host onPort:port error:errPtr];
    return flag;
}

- (void)restartSocket
{
    [self close];
    
    NSTimeInterval timeInterval = [[NSDate date]timeIntervalSince1970];
    NSString *queueName = [NSString stringWithFormat:@"UpdSocketDelegateQueue%f",timeInterval];
    
    self.delegateQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_PRIORITY_DEFAULT);
    self.udpScocket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:self.delegateQueue];
    
}

- (void)close
{
    if(self.udpScocket)
    {
        [self.udpScocket close];
        self.udpScocket = nil;
        self.delegateQueue = nil;
    }
}


+ (NSString *)getIpAddressFormData:(NSData *)address
{
    const struct sockaddr_in *dd= [address bytes];
    NSString *ad =[NSString stringWithUTF8String:inet_ntoa(dd->sin_addr)];
    return ad;
}


/**-------------------------GCDAsyncUdpSocket的代理方法---------------------------**/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    if([self.delegate respondsToSelector:@selector(UDPSocket:didConnectToAddress:)])
    {
        [self.delegate UDPSocket:self didConnectToAddress:address];
    }
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(nonnull NSError *)error
{
    if([self.delegate respondsToSelector:@selector(UDPSocket:didNotConnect:)])
    {
        [self.delegate UDPSocket:self didNotConnect:error];
    }
    
}


- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(UDPSocketDidClose:withError:)])
    {
        [self.delegate UDPSocketDidClose:self withError:error];
    }
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    if([self.delegate respondsToSelector:@selector(UDPSocket:didSendDataWithTag:)])
    {
        [self.delegate UDPSocket:self didSendDataWithTag:tag];
    }
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(UDPSocket:didNotSendDataWithTag:dueToError:)])
    {
        [self.delegate UDPSocket:self didNotSendDataWithTag:tag dueToError:error];
    }

}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    if([self.delegate respondsToSelector:@selector(UDPSocket:didReceiveData:fromAddress:withFilterContext:)])
    {
        [self.delegate UDPSocket:self didReceiveData:data fromAddress:address withFilterContext:filterContext];
    }
}


- (void)dealloc
{
    [self close];
}




@end
