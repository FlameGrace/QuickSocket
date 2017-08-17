//
//  SingleClientSocketServer.m
//  flamegrace@hotmail.com
//
//  Created by Flame Grace on 2017/7/19.
//  Copyright © 2017年 flamegrace@hotmail.com. All rights reserved.
//

#import "SingleClientServer.h"

@interface SingleClientServer() <SocketServerDelegate, SocketConnectionDelegate>



@property (strong, nonatomic) dispatch_queue_t socketQueue;


@end

@implementation SingleClientServer

- (instancetype)init
{
    if(self = [super init])
    {
        [self run];
    }
    
    return self;
}


- (void)run
{
    [self.server startServerOnRandomPort];
}

- (void)runOnPort:(int16_t)port
{
    [self.server startServerOnPort:port error:nil];
}

- (BOOL)isRunning
{
    return [self.server isBinding];
}


- (BOOL)haveClientConneted
{
    return [self.client isConnected];
}


- (int16_t)bindPort
{
    return [self.server bindPort];
}

- (void)disConnectedToClient
{
    self.client.delegate = nil;
    [self.client stopHeartbeatTimer];
    [self.client disconnect];
    self.client = nil;
}

- (void)dealloc
{
    [self disConnectedToClient];
    self.server.delegate = nil;
    self.server = nil;
    self.socketQueue = nil;
}

- (NSString *)clientHost
{
    return [self.client connectedHost];
}

- (BOOL)sendDataToClient:(NSData *)data timeout:(NSTimeInterval)timeout tag:(long)tag
{
    if(![self haveClientConneted])
    {
        return NO;
    }
    
    [self.client writeData:data timeout:timeout tag:tag];
    
    return YES;
}

- (void)singleClientServerClientDidConnect:(SingleClientServer *)server
{
    if(self.delegate&&[self.delegate respondsToSelector:@selector(singleClientServerClientDidConnect:)])
    {
        dispatch_sync(self.socketQueue, ^{
            [self.delegate singleClientServerClientDidConnect:server];
        });
        
    }
}

- (void)singleClientServerClientDidDisConnect:(SingleClientServer *)server
{
    if(self.delegate&&[self.delegate respondsToSelector:@selector(singleClientServerClientDidDisConnect:)])
    {
        dispatch_sync(self.socketQueue, ^{
            [self.delegate singleClientServerClientDidDisConnect:server];
        });
        
    }
}

- (void)singleClientServerClient:(SingleClientServer *)server recievedData:(NSData *)data
{
    if(self.delegate&&[self.delegate respondsToSelector:@selector(singleClientServerClient:recievedData:)])
    {
        dispatch_sync(self.socketQueue, ^{
            [self.delegate singleClientServerClient:server recievedData:data];
        });
    }
}

- (void)singleClientServerClient:(SingleClientServer *)server didSendDataWithTag:(long)tag
{
    if(self.delegate&&[self.delegate respondsToSelector:@selector(singleClientServerClient:didSendDataWithTag:)])
    {
        dispatch_sync(self.socketQueue, ^{
            [self.delegate singleClientServerClient:server didSendDataWithTag:tag];
        });
        
    }
}



- (void)didRead:(id<SocketConnectionProtocol>)con withData:(NSData *)data tag:(long)tag
{
    [con readDataWithTimeout:-1 tag:0];
    [self singleClientServerClient:self recievedData:data];
}


- (void)didWrite:(id<SocketConnectionProtocol>)con withTag:(long)tag
{
    [con readDataWithTimeout:-1 tag:0];
    [self singleClientServerClient:self didSendDataWithTag:tag];
}


-(void)didDisconnect:(id<SocketConnectionProtocol>)con withError:(NSError *)err
{
    [self singleClientServerClientDidDisConnect:self];
}

- (void)socketServer:(SocketServer *)server didAcceptNewClient:(SocketConnection *)newClient
{
    //防止多次重复链接
    if([[self.client connectedHost]isEqualToString:[newClient connectedHost]]&&[self.client isConnected])
    {
        return;
    }
    [self disConnectedToClient];
    self.client = newClient;
    [self.client startHeartbeatTimer:1];
    NSString *heartbeat = @"hb";
    self.client.heartbeat = [heartbeat dataUsingEncoding:NSUTF8StringEncoding];
    self.client.delegate = self;
    [self.client readDataWithTimeout:-1 tag:0];
    [self singleClientServerClientDidConnect:self];
    
}

- (void)didConnect:(id<SocketConnectionProtocol>)con toHost:(NSString *)host port:(uint16_t)port
{
    [self singleClientServerClientDidConnect:self];
}



- (dispatch_queue_t)socketQueue
{
    if(!_socketQueue)
    {
        NSString *time = [NSString stringWithFormat:@"%@%f",NSStringFromClass([self class]),[[NSDate date]timeIntervalSince1970]];
        _socketQueue = dispatch_queue_create([time UTF8String], DISPATCH_QUEUE_PRIORITY_DEFAULT);
    }
    
    return _socketQueue;
}
- (SocketServer *)server
{
    if(!_server)
    {
        _server = [[SocketServer alloc]init];
        _server.delegate = self;
    }
    return _server;
}

@end
