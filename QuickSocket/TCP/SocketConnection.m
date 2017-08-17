//
//  SocketConnection.m
//  SocketDemo
//
//  Created by zhuruhong on 15/6/18.
//  Copyright (c) 2015年 zhuruhong. All rights reserved.
//

#import "SocketConnection.h"
#define kConnectMaxCount            1000    //tcp断开重连次数
#define kConnectTimerInterval       5       //单位秒s



NSString * const SocketQueueSpecific = @"com.flamegrace@hotmail.com.socket.SocketQueueSpecific";

@interface SocketConnection () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) dispatch_queue_t socketQueue;
@property (nonatomic, assign) void *IsOnSocketQueueOrTargetQueueKey;

@property (nonatomic, strong) GCDAsyncSocket *asyncSocket;

/**
 *  心跳定时器，这里使用的是NSTimer，在断开连接后，需要手动停止心跳定时器(使用MSWeakTimer更好)
 */
@property (strong, nonatomic) dispatch_source_t heartbeatTimer;

/**
 *  自动重连使用的计时器
 */
@property (nonatomic, strong, readonly) NSTimer *reConnectTimer;

/**
 *  开始自动重连后，尝试重连次数，默认为500次
 */
@property (nonatomic, assign, readonly) NSInteger reConnectCount;

/**
 *  开始自动重连后，首次重连时间间隔，默认为5秒，后面每常识重连10次增加5秒
 */
@property (nonatomic, assign, readonly) NSTimeInterval reConnectTimerInterval;


@end


@implementation SocketConnection

- (instancetype)init
{
    if (self = [super init]) {
        //queue
        _socketQueue = dispatch_queue_create([SocketQueueSpecific UTF8String], DISPATCH_QUEUE_PRIORITY_DEFAULT);
        
    }
    return self;
}


- (instancetype)initWithAsyncSocket:(GCDAsyncSocket *)aSocket
{
    if (self = [super init]) {
        //queue
        [self updateAsyncSocket:aSocket];
    }
    return self;
}

- (void)updateAsyncSocket:(GCDAsyncSocket *)aSocket
{
    _socketQueue = dispatch_queue_create([SocketQueueSpecific UTF8String], DISPATCH_QUEUE_PRIORITY_DEFAULT);
    _asyncSocket = aSocket;
    [_asyncSocket setDelegate:self delegateQueue:_socketQueue];
    [self.asyncSocket readDataWithTimeout:-1 tag:0];
    if(self.connectParam.autoHeartbeat)
    {
        [self startHeartbeatTimer:self.connectParam.heartbeatInterval];
    }
}


#pragma mark - SocketConnection protocol

- (void)connectWithParam:(SocketConnectParam *)connectParam
{
    if(connectParam.host.length < 1 || connectParam.port <= 0)
    {
        return ;
    }
    
    if([self isConnected])
    {
       [self disconnect];
    }
    _connectParam = connectParam;
    
    self.asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketQueue];
    [self.asyncSocket setIPv4PreferredOverIPv6:NO];
    
    NSError *error = nil;
    [self.asyncSocket connectToHost:connectParam.host onPort:connectParam.port withTimeout:connectParam.timeout error:&error];
    if (error)
    { 
        if([self.delegate respondsToSelector:@selector(didDisconnect:withError:)])
        {
            [self.delegate didDisconnect:self withError:error];
        }
        return ;
    }
    
    if(self.connectParam.autoHeartbeat)
    {
        [self startHeartbeatTimer:self.connectParam.heartbeatInterval];
    }
}

- (void)disconnect
{
    [self stopHeartbeatTimer];
    [self.asyncSocket disconnect];
    self.asyncSocket.delegate = nil;
    self.asyncSocket = nil;
}

- (void)dealloc
{
    [self stopHeartbeatTimer];
    [self stopReConnectTimer];
    [self.asyncSocket disconnect];
    self.asyncSocket.delegate = nil;
    self.asyncSocket = nil;
}



- (BOOL)isConnected
{
    return [self.asyncSocket isConnected];
}

- (NSString *)connectedHost
{
    return [self.asyncSocket connectedHost];
}

- (int16_t)connectedPort
{
    return [self.asyncSocket connectedPort];
}


#pragma mark - read & write

-(void)readDataToData:(NSData *)data timeout:(NSTimeInterval)timeout tag:(long)tag
{
    [self.asyncSocket readDataToData:data withTimeout:timeout tag:tag];
}

- (void)readDataWithTimeout:(NSTimeInterval)timeout tag:(long)tag
{
    [self.asyncSocket readDataWithTimeout:timeout tag:tag];
}

- (void)writeData:(NSData *)data timeout:(NSTimeInterval)timeout tag:(long)tag
{
    [self.asyncSocket writeData:data withTimeout:timeout tag:tag];
}


/*心跳包设置---------*/
- (void)stopHeartbeatTimer
{
    if (self.heartbeatTimer) {
        self.heartbeatTimer = nil;
    }
}

- (void)startHeartbeatTimer:(NSTimeInterval)interval
{
    NSTimeInterval minInterval = MAX(1, interval);
    [self stopHeartbeatTimer];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.heartbeatTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.heartbeatTimer, dispatch_walltime(NULL, 0), minInterval * NSEC_PER_SEC, 0); //每秒执行
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.heartbeatTimer, ^{ //在这里执行事件
        __strong typeof(weakSelf) self = weakSelf;
        [self heartbeatTimerFunction];
    });
    
    dispatch_resume(self.heartbeatTimer);
}

- (void)heartbeatTimerFunction
{
    [self sendHeartbeat];
}

- (void)sendHeartbeat
{
    [self.asyncSocket writeData:self.heartbeat withTimeout:-1 tag:0];
}

/*心跳包设置----------*/


/*-----------自动重连机制--------*/
- (void)startReConnectTimer:(NSTimeInterval)interval
{
    if(self.isConnected)
    {
        return;
    }
    
    if(self.reConnectTimer.isValid)
    {
        return;
    }
    NSTimeInterval minInterval = MAX(5, interval);
    [self stopReConnectTimer];
    _reConnectTimer = [NSTimer scheduledTimerWithTimeInterval:minInterval target:self selector:@selector(reConnectTimerFunction) userInfo:nil repeats:NO];
    [_reConnectTimer fire];
}

- (void)stopReConnectTimer
{
    if (_reConnectTimer) {
        [_reConnectTimer invalidate];
        _reConnectTimer = nil;
    }
}

- (void)reConnectTimerFunction
{
    
    //重连次数超过最大尝试次数，停止
    if (_reConnectCount > kConnectMaxCount) {
        [self stopReConnectTimer];
        return;
    }
    
    _reConnectCount++;
    
    //重连时间策略
    if (_reConnectCount % 10 == 0) {
        _reConnectTimerInterval += kConnectTimerInterval;
        [self startReConnectTimer:_reConnectTimerInterval];
    }
    
    if ([self isConnected]) {
        [self stopReConnectTimer];
        return;
    }
    [self connectWithParam:self.connectParam];
}
/*-----------自动重连机制--------*/



- (void)didDisconnect:(id<SocketConnectionProtocol>)con withError:(NSError *)err
{
    if([self.delegate respondsToSelector:@selector(didDisconnect:withError:)])
    {
        [self.delegate didDisconnect:self withError:err];
    }
}


- (void)didConnect:(id<SocketConnectionProtocol>)con toHost:(NSString *)host port:(uint16_t)port
{
    if([self.delegate respondsToSelector:@selector(didConnect:toHost:port:)])
    {
        [self.delegate didConnect:self toHost:host port:port];
    }
    
    
}


- (void)didRead:(id<SocketConnectionProtocol>)con withData:(NSData *)data tag:(long)tag
{
    if([self.delegate respondsToSelector:@selector(didRead:withData:tag:)])
    {
        [self.delegate didRead:self withData:data tag:tag];
    }
}



- (void)didWrite:(id<SocketConnectionProtocol>)con withTag:(long)tag
{
    if([self.delegate respondsToSelector:@selector(didWrite:withTag:)])
    {
        [self.delegate didWrite:self withTag:tag];
    }
}






#pragma mark - GCDAsyncSocketDelegate

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    [self didDisconnect:self withError:err];
    
}


- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    [self didConnect:self toHost:host port:port];
    
    if (self.connectParam.useSecureConnection) {
        [sock startTLS:self.connectParam.tlsSettings];
        return;
    }

}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    if([self.delegate respondsToSelector:@selector(didStartSecure:)])
    {
        [self.delegate didStartSecure:self];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [self didRead:self withData:data tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    [self didWrite:self withTag:tag];
}


@end
