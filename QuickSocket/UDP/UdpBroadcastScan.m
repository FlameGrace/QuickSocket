//
//  SocketSearchService.m
//  p2p
//
//  Created by Flame Grace on 16/10/27.
//  Copyright © 2016年 hello. All rights reserved.
//

#import "UdpBroadcastScan.h"
#import "LocalIPAddressHandle.h"
#import "UDPSocket.h"

@interface UdpBroadcastScan() <UDPSocketDelegate>

//是否在搜寻设备中
@property (readwrite, assign, nonatomic) BOOL isScaning;

//是否在搜寻设备中
@property (readwrite, assign, nonatomic) BOOL isBinding;

//当前监听的端口
@property (readwrite, assign, nonatomic) uint32_t bindPort;

//是否已经打开广播模式
@property (readwrite, assign, nonatomic) BOOL isOpenBroadcast;

@property (assign, nonatomic) uint32_t scanPort;

//搜寻套接字
@property (strong, nonatomic)UDPSocket *scanSocket;
//定时搜寻
@property (strong, nonatomic) NSTimer *scanTimer;

@property (assign,nonatomic) NSInteger scanTimeInterval;

@end


@implementation UdpBroadcastScan

- (id)init
{
    if(self = [super init])
    {
        self.scanSocket = [[UDPSocket alloc]init];
        self.scanSocket.delegate = self;
    }
    return self;
}

/**
 搜寻车机时发送的数据
 @return 搜寻车机时发送的数据
 */
- (NSData *)searchDataForUdpBroadcastScan:(UdpBroadcastScan *)scan
{
    NSData *data = nil;
    if(self.delegate && [self.delegate respondsToSelector:@selector(searchDataForUdpBroadcastScan:)])
    {
        data = [self.delegate searchDataForUdpBroadcastScan:scan];
    }
    return data;
}

//接收到数据
- (void)udpBroadcastScan:(UdpBroadcastScan *)scan didRecieveData:(NSData *)data fromHost:(NSString *)host
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(udpBroadcastScan:didRecieveData:fromHost:)])
    {
        [self.delegate udpBroadcastScan:scan didRecieveData:data fromHost:host];
    }
}

- (void)udpBroadcastScanDidReachMaxScanTime:(UdpBroadcastScan *)scan
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(udpBroadcastScanDidReachMaxScanTime:)])
    {
        [self.delegate udpBroadcastScanDidReachMaxScanTime:scan];
    }
}



- (NSData *)searchData
{
    NSData *searchData = [self searchDataForUdpBroadcastScan:self];
    return searchData;
}

//开始搜寻
- (BOOL)initScanOnPort:(uint32_t)port needBind:(BOOL)needBind error:(NSError **)error;
{
    
    self.scanPort = port;
    
    if(self.isBinding)
    {
        return YES;
    }
    
    if(needBind)
    {
        if(![self.scanSocket bindRandomPort])
        {
            Log(UnKnow,@"绑定端口失败");
            return NO;
        }
        
        self.isBinding = YES;
        
        if(![self.scanSocket beginReceiving:error])
        {
            Log(UnKnow,@"Error 开始接收数据失败");
            return NO;
        }
        
    }
    
    self.isOpenBroadcast  = [self.scanSocket enableBroadcast:YES error:error];
    
    return self.isOpenBroadcast;
}




//开始搜索
- (void)start
{
    self.isScaning = YES;
    self.scanTimeInterval = 0;
    [self performSelectorOnMainThread:@selector(startTimers) withObject:nil waitUntilDone:NO];
    
}


//发送搜寻指令
- (void)sendSearchData
{
    
    if(self.maxScanTimeInterval != 0 && self.maxScanTimeInterval <=self.scanTimeInterval)
    {
        [self stop];
        [self udpBroadcastScanDidReachMaxScanTime:self];
        return;
    }
    
    NSMutableArray *searchIPs = [[NSMutableArray alloc]init];
    LocalIPAddressHandle *localIP = [[LocalIPAddressHandle alloc]init];
    
    if(localIP.bridgeAddress)
    {
        [searchIPs addObject:localIP.bridgeAddress.broadcast];
    }
    if(localIP.innerAddress)
    {
        [searchIPs addObject:localIP.innerAddress.broadcast];
    }
    
    for (NSString  *host in searchIPs)
    {
        NSData *data = self.searchData;
        
        if(data)
        {
            [self.scanSocket sendData:data toHost:host port:self.scanPort withTimeout:0 tag:0];
            
        #ifdef InP2PDebug
            if(self.scanTimeInterval%10 ==1)
            {
                [[AlertViewManager shareAlertViewManager]showAlertMessage:@"已经发送搜寻数据" inModalDialogWindow:NO withKeys:nil callBackHandles:nil];
            }
            
        #endif
        }
        
    }
    
    self.scanTimeInterval ++;
}


//开启定时器
- (void)startTimers
{
    self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendSearchData) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:self.scanTimer forMode:NSDefaultRunLoopMode];
}

//停止定时器
-(void)endTimers
{
    [self.scanTimer invalidate];
    self.scanTimer = nil;
}



//停止搜寻服务
- (void)stop
{
    [self performSelectorOnMainThread:@selector(endTimers) withObject:nil waitUntilDone:NO];
    self.isScaning = NO;
}


//关闭服务
- (void)close
{
    if(self.isScaning)
    {
        [self stop];
    }
    [self.scanSocket restartSocket];
    self.isBinding = NO;
}

- (void)dealloc
{
    [self close];
}

- (void)sendData:(NSData *)data toHost:(NSString *)host
{
    [self.scanSocket sendData:data toHost:host port:self.scanPort withTimeout:0 tag:3];
}




/**-------------------------UDPSocket的代理方法---------------------------**/


- (void)UDPSocket:(UDPSocket *)socket didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    
    Log(UnKnow,@"发送数据失败:%ld出错：%@",tag,error);
}

- (void)UDPSocket:(UDPSocket *)socket didSendDataWithTag:(long)tag
{
    
}

- (void)UDPSocket:(UDPSocket *)socket didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    
    NSString *host = [UDPSocket getIpAddressFormData:address];
    //非法的地址丢弃
    
    if(![LocalIPAddress isIpAddressValid:host])
    {
        return;
    }
    //本机发送的消息丢弃
    if([[LocalIPAddressHandle local] isContainIPAddress:host])
    {
        return;
    }
    [self udpBroadcastScan:self didRecieveData:data fromHost:host];
}


/**-------------------------GCDAsyncUdpSocket的代理方法---------------------------**/




@end
