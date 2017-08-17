//
//  UDPSocket.h
//  flamegrace@hotmail.com
//
//  Created by Flame Grace on 16/12/22.
//  Copyright © 2016年 flamegrace@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@class UDPSocket;

@protocol UDPSocketDelegate <NSObject>

@optional
/**
 连接上某个地址
 **/
- (void)UDPSocket:(UDPSocket * _Nonnull)socket didConnectToAddress:(NSData * _Nullable)address;

/**
 连接失败时回调
 **/
- (void)UDPSocket:(UDPSocket * _Nonnull)socket didNotConnect:(NSError * _Nullable)error;

/**
 * 发送数据成功时回调
 **/
- (void)UDPSocket:(UDPSocket * _Nonnull)socket didSendDataWithTag:(long)tag;

/**
 发送数据失败时回调
 **/
- (void)UDPSocket:(UDPSocket * _Nonnull)socket didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error;

/**
 * 接收到数据时回调
 **/
- (void)UDPSocket:(UDPSocket * _Nonnull)socket didReceiveData:(NSData * _Nonnull)data fromAddress:(NSData * _Nonnull)address
     withFilterContext:(nullable id)filterContext;

/**
 * 
 socket关闭时回调
 **/
- (void)UDPSocketDidClose:(UDPSocket * _Nonnull)socket withError:(NSError * _Nullable)error;

@end


@interface UDPSocket : NSObject

@property (weak, nonatomic) id<UDPSocketDelegate> _Nullable delegate;

//是否在监听端口中
@property (readonly, nonatomic) BOOL isBinding;
//正在监听的端口
@property (readonly, nonatomic) uint32_t bindPort;
//是否已经打开广播模式
@property (readonly, nonatomic) BOOL isOpenBroadcast;

//开始监听端口
- (BOOL)bindToPort:(uint32_t)port  error:(NSError  * _Nullable * _Nullable)error;
//监听随机端口
- (BOOL)bindRandomPort;

/**
 设置是否打开广播模式
 */
- (BOOL)enableBroadcast:(BOOL)enable error:(NSError * _Nullable * _Nullable)error;


/**
 设置开始接收数据
 */
- (BOOL)beginReceiving:(NSError * _Nullable * _Nullable)error;

- (void)pauseReceiving;


/**
 发送数据
 */
- (void)sendData:(NSData * _Nonnull)data
          toHost:(NSString * _Nonnull)host
            port:(uint16_t)port
     withTimeout:(NSTimeInterval)timeout
             tag:(long)tag;


/**
 链接某个UDP服务器
 */
- (BOOL)connectToHost:(NSString * _Nonnull)host onPort:(uint16_t)port error:(NSError * _Nullable * _Nullable)errPtr;


/**
 从Address数据中获取ip地址
 */
+ (NSString  * _Nullable)getIpAddressFormData:(NSData  * _Nonnull)address;

/**
 重启链接
 */
- (void)restartSocket;

/**
 关闭链接
 */
- (void)close;

@end
