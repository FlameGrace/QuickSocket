//
//  SocketServer.m
//  flamegrace@hotmail.com
//
//  Created by Flame Grace on 16/12/28.
//  Copyright © 2016年 flamegrace@hotmail.com. All rights reserved.
//

#import "SocketServer.h"
#import "GCDAsyncSocket.h"

@interface SocketServer() <GCDAsyncSocketDelegate>

@property (readwrite,assign, nonatomic) uint16_t bindPort;

@property (readwrite,assign, nonatomic) BOOL isBinding;

@property (strong, nonatomic) GCDAsyncSocket *server;

@property (strong, nonatomic) dispatch_queue_t serverDelegetQueue;

@end

@implementation SocketServer

- (instancetype)init
{
    if(self = [super init])
    {
        NSTimeInterval timeInterval = [[NSDate date]timeIntervalSince1970];
        NSString *queueName = [NSString stringWithFormat:@"UpdSocketDelegateQueue%f",timeInterval];
        
        self.serverDelegetQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_PRIORITY_DEFAULT);
        self.server = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:self.serverDelegetQueue];
    }
    
    return self;
}

- (BOOL)startServerOnPort:(uint16_t)port error:(NSError **)err
{
    NSError *error;
    if(![self.server acceptOnPort:port error:&error])
    {
        NSLog(@"监听端口失败%@",error);
        return NO;
    }
    
    self.bindPort = port;
    self.isBinding = YES;
    
    return YES;
}

- (BOOL)serverBindRandomPort
{
    uint32_t startCheckPort = 4444 + 1;
    BOOL bindOk = NO;
    while (!bindOk)
    {
        bindOk = [self.server acceptOnPort:startCheckPort error:nil];
        if(bindOk)
        {
            self.bindPort = startCheckPort;
            self.isBinding = YES;
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


- (BOOL)startServerOnRandomPort
{
    if(self.isBinding)
    {
        return YES;
    }
    return [self serverBindRandomPort];
}


- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    @synchronized (self)
    {
        NSString *host = [newSocket connectedHost];
        if(host == nil || !host.length)
        {
            return ;
        }
        
        SocketConnection *con = [[SocketConnection alloc]initWithAsyncSocket:newSocket];
        
        if([self.delegate respondsToSelector:@selector(socketServer:didAcceptNewClient:)])
        {
            [self.delegate socketServer:self didAcceptNewClient:con];
        }
        
    }
}




@end
