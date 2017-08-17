//
//  SingleClientSocketServer.h
//  flamegrace@hotmail.com
//
//  Created by Flame Grace on 2017/7/19.
//  Copyright © 2017年 flamegrace@hotmail.com. All rights reserved.
//  单客户端TCP服务器

#import <Foundation/Foundation.h>
#import "SocketServer.h"
#import "SocketConnection.h"

@class SingleClientServer;

@protocol SingleClientServerDelegate <NSObject>

@optional
//有新链接过来
- (void)singleClientServerClientDidConnect:(SingleClientServer *)server;
//客户端失去链接
- (void)singleClientServerClientDidDisConnect:(SingleClientServer *)server;
//接收到客户端发来的消息
- (void)singleClientServerClient:(SingleClientServer *)server recievedData:(NSData *)data;
//发送消息到客户端成功，tag可以用来判断是那个消息
- (void)singleClientServerClient:(SingleClientServer *)server didSendDataWithTag:(long)tag;

@end


@interface SingleClientServer : NSObject <SingleClientServerDelegate,SocketServerDelegate>

@property (strong, nonatomic) SocketServer *server;

@property (strong, nonatomic) SocketConnection *client;

@property (weak, nonatomic) id<SingleClientServerDelegate>delegate;

//随机可用端口
- (void)run;
//监听特定端口
- (void)runOnPort:(int16_t)port;
//是否有客户端链接
- (BOOL)haveClientConneted;
//是否已经在监听运行中
- (BOOL)isRunning;
//关闭与客户端的链接
- (void)disConnectedToClient;
//当前监听端口
- (int16_t)bindPort;
//当前客户端的ip地址
- (NSString *)clientHost;
//发送消息到客户端，tag用来标识消息
- (BOOL)sendDataToClient:(NSData *)data timeout:(NSTimeInterval)timeout tag:(long)tag;

@end
