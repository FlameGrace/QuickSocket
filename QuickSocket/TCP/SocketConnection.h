//
//  SocketConnection.h
//  SocketDemo
//
//  Created by zhuruhong on 15/6/18.
//  Copyright (c) 2015年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketConnectionProtocol.h"
#import "GCDAsyncSocket.h"




/**
 *  socket connection的回调代理协议
 */
@protocol SocketConnectionDelegate <NSObject>

@required


/**
 *  和socket服务器 连接失败/断开连接 的回调方法
 *
 *  @param con 当前socket connection
 *  @param err 错误原因
 */
- (void)didDisconnect:(id<SocketConnectionProtocol>)con withError:(NSError *)err;

/**
 *  和socket服务器连接成功的回调方法
 *
 *  @param con  当前socket connection
 *  @param host 连接成功的服务器地址ip
 *  @param port 连接成功的服务器端口port
 */
- (void)didConnect:(id<SocketConnectionProtocol>)con toHost:(NSString *)host port:(uint16_t)port;

/**
 *  接收到从socket服务器推送下来的下行数据(原始数据流)回调方法
 *
 *  @param con  当前socket connection
 *  @param data 推送过来的下行数据
 *  @param tag  数据tag标记，和readDataWithTimeout:tag/writeData:timeout:tag:中的tag对应。
 */
- (void)didRead:(id<SocketConnectionProtocol>)con withData:(NSData *)data tag:(long)tag;


/**
 *  写入socket服务器数据的回调方法
 *
 *  @param con  当前socket connection
 *  @param tag  数据tag标记，和readDataWithTimeout:tag/writeData:timeout:tag:中的tag对应。
 */
- (void)didWrite:(id<SocketConnectionProtocol>)con withTag:(long)tag;


@optional

/**
 *  和socket服务器 开始使用安全链接
 *
 *  @param con 当前socket connection
 */
- (void)didStartSecure:(id<SocketConnectionProtocol>)con;



@end



@class SocketConnection;

/**
 *  socket网络连接对象，只负责socket网络的连接通信，内部使用GCDAsyncSocket。
 *  1-只公开GCDAsyncSocket的主要方法，增加使用的便捷性。
 *  2-封装的另一个目的是，易于后续更新调整。如果不想使用GCDAsyncSocket，只想修改内部实现即可，对外不产生影响。
 */
@interface SocketConnection : NSObject <SocketConnectionProtocol>

@property (weak, nonatomic) id<SocketConnectionDelegate>delegate;

@property (nonatomic, strong) SocketConnectParam *connectParam;

/**
 *  固定心跳包 (设置心跳包，在连接成功后，开启心态定时器)
 */
@property (nonatomic, strong) NSData *heartbeat;

//停止定时发送心跳包
- (void)stopHeartbeatTimer;
//开始定时发送心跳包
- (void)startHeartbeatTimer:(NSTimeInterval)interval;
//发送心跳包
- (void)sendHeartbeat;

//开启断线重连
- (void)startReConnectTimer:(NSTimeInterval)interval;
//停止断线重连
- (void)stopReConnectTimer;

- (instancetype)initWithAsyncSocket:(GCDAsyncSocket *)aSocket;

- (void)updateAsyncSocket:(GCDAsyncSocket *)aSocket;

- (NSString *)connectedHost;

- (int16_t)connectedPort;




@end
