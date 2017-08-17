//
//  P2PDeviceSearch.h
//  p2p
//
//  Created by Flame Grace on 16/10/27.
//  Copyright © 2016年 hello. All rights reserved.
//  使用UDP广播向特定端口发送搜寻数据

#import <Foundation/Foundation.h>




@class UdpBroadcastScan;

@protocol UdpBroadcastScanDelegate <NSObject>

@optional
/**
 搜寻车机时发送的数据
 @return 搜寻车机时发送的数据
 */
- (NSData *)searchDataForUdpBroadcastScan:(UdpBroadcastScan *)scan;


//接收到数据
- (void)udpBroadcastScan:(UdpBroadcastScan *)scan didRecieveData:(NSData *)data fromHost:(NSString *)host;

- (void)udpBroadcastScanDidReachMaxScanTime:(UdpBroadcastScan *)scan;


@end


@interface UdpBroadcastScan : NSObject <UdpBroadcastScanDelegate>

@property (weak, nonatomic) id<UdpBroadcastScanDelegate>delegate;
/**
 进行一次新的扫描最多扫描时间，如果扫描不到自动停止扫描, 为0时，不自动停止扫描
 */
@property (assign, nonatomic) NSInteger maxScanTimeInterval;
//是否在搜寻车机中
@property (readonly, nonatomic) BOOL isScaning;
//是否在监听端口中
@property (readonly, nonatomic) BOOL isBinding;
//正在监听的消息端口
@property (readonly, nonatomic) uint32_t bindPort;

/**
 初始化搜寻通道
 @param Port 在哪个端口搜寻
 @param needBind 是否要监听一个随机端口作为消息接收端口
 @param error 错误
 @return 成功失败标志
 */
- (BOOL)initScanOnPort:(uint32_t)port needBind:(BOOL)needBind error:(NSError **)error;
//开始发送搜寻指令
- (void)start;
//停止发送搜寻指令
- (void)stop;
//停止监听消息端口
- (void)close;
//发送数据
- (void)sendData:(NSData *)data toHost:(NSString *)host;



@end
