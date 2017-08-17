//
//  LocalIPAddressHandle.h
//  p2p
//
//  Created by Flame Grace on 16/10/28.
//  Copyright © 2016年 hello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalIPAddress.h"



@interface LocalIPAddressHandle : NSObject


@property (readonly, nonatomic) LocalIPAddress *loopbackAddress;//回环地址

@property (readonly, nonatomic) LocalIPAddress *innerAddress;//内网地址

@property (readonly, nonatomic) LocalIPAddress *outerAddress; //外网地址

@property (readonly, nonatomic) LocalIPAddress *bridgeAddress; //桥接地址，通常是自己作为热点时分配的地址


+ (instancetype)local;


+(NSArray <LocalIPAddress *> *)getLocalIpAddresses;

//更新当前对象的地址信息
- (void)updateIPAddresses;

- (BOOL)isContainIPAddress:(NSString *)ipAddress;


@end
