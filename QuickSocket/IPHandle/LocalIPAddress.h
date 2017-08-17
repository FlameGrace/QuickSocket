//
//  AXNetAddress.h
//  p2p
//
//  Created by Flame Grace on 16/10/28.
//  Copyright © 2016年 hello. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,LocalIPAddressType)
{
    LocalIPAddressOther = -1, //其他地址
    LocalIPAddressLoopback,//回环地址
    LocalIPAddressInner,//内网地址
    LocalIPAddressOuter, //外网地址
    LocalIPAddressBridge, //桥接地址
    
};

@interface LocalIPAddress : NSObject

@property (assign, nonatomic)LocalIPAddressType type;//
@property (strong, nonatomic)NSString* iPAddress;//ip地址
@property (strong, nonatomic)NSString* netMask;//子网掩码
@property (strong, nonatomic)NSString* broadcast;//网关


//检查IP地址是否合法
+ (BOOL)isIpAddressValid:(NSString *)ipAddress;

@end
