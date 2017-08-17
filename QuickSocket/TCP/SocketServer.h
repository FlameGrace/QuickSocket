//
//  SocketServer.h
//  flamegrace@hotmail.com
//
//  Created by Flame Grace on 16/12/28.
//  Copyright © 2016年 flamegrace@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketConnection.h"


@class SocketServer;

@protocol SocketServerDelegate <SocketConnectionDelegate>

- (void)socketServer:(SocketServer *)server didAcceptNewClient:(SocketConnection *)newClient;

@end


@interface SocketServer : NSObject

@property (weak, nonatomic) id <SocketServerDelegate>delegate;

@property (readonly, nonatomic) uint16_t bindPort;

@property (readonly, nonatomic) BOOL isBinding;

- (BOOL)startServerOnPort:(uint16_t)port error:(NSError **)err;

/**
 自动查找可用端口进行监听
 @return 成功或失败
 */
- (BOOL)startServerOnRandomPort;

@end
