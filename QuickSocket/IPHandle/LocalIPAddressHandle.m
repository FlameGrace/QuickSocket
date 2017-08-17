//
//  LocalIPAddressHandle.m
//  p2p
//
//  Created by Flame Grace on 16/10/28.
//  Copyright © 2016年 hello. All rights reserved.
//

#import "LocalIPAddressHandle.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IOS_Loopback    @"lo0"
#define IOS_Bridge      @"bridge"






@interface LocalIPAddressHandle()


@property (readwrite, strong, nonatomic) LocalIPAddress *loopbackAddress;//回环地址

@property (readwrite, strong, nonatomic) LocalIPAddress *innerAddress;//内网地址

@property (readwrite, strong, nonatomic) LocalIPAddress *outerAddress; //外网地址

@property (readwrite, strong, nonatomic) LocalIPAddress *bridgeAddress; //桥接地址


@end


@implementation LocalIPAddressHandle


+(instancetype)local
{
    LocalIPAddressHandle *handle = [[LocalIPAddressHandle alloc]init];
    return handle;
}


- (instancetype)init
{
    if(self = [super init])
    {
        [self updateIPAddresses];
    }
    return self;
}



- (void)updateIPAddresses
{
    NSArray *ips = [[self class] getLocalIpAddresses];
    
    for (LocalIPAddress *ip in ips) {
        if(ip.type == LocalIPAddressLoopback)
        {
            self.loopbackAddress = ip;
        }
        if(ip.type == LocalIPAddressInner)
        {
            self.innerAddress = ip;
        }
        if(ip.type == LocalIPAddressOuter)
        {
            self.outerAddress = ip;
        }
        if(ip.type == LocalIPAddressBridge)
        {
            self.bridgeAddress = ip;
        }
    }
}


- (BOOL)isContainIPAddress:(NSString *)ipAddress
{
    __block BOOL contain = NO;
    NSArray *ips = [[self class] getLocalIpAddresses];
    [ips enumerateObjectsUsingBlock:^(LocalIPAddress * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj.iPAddress isEqualToString:ipAddress])
        {
            contain = YES;
        }
    }];
    return contain;
}


+(NSArray <LocalIPAddress *> *)getLocalIpAddresses
{
    NSMutableArray* addresses = [[NSMutableArray alloc] init];
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    @try
    {
        // retrieve the current interfaces - returns 0 on success
        NSInteger success = getifaddrs(&interfaces);
        //NSLog(@"%@, success=%d", NSStringFromSelector(_cmd), success);
        if(success == 0)
        {
            // Loop through linked list of interfaces
            temp_addr = interfaces;
            while(temp_addr != NULL)
            {
                if(temp_addr->ifa_addr->sa_family == AF_INET)
                {
                    // Get NSString from C String
                    NSString* ifaName = [NSString stringWithUTF8String:temp_addr->ifa_name];
                    NSString* address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) temp_addr->ifa_addr)->sin_addr)];
                    NSString* mask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) temp_addr->ifa_netmask)->sin_addr)];
                    NSString* broadcast = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) temp_addr->ifa_dstaddr)->sin_addr)];
                    
                    if(ifaName.length && address.length)
                    {
                        LocalIPAddress *netAddress = [[LocalIPAddress alloc]init];
                        netAddress.iPAddress = address;
                        netAddress.netMask = mask;
                        netAddress.broadcast = broadcast;
                        if([ifaName isEqualToString:IOS_CELLULAR])
                        {
                            netAddress.type = LocalIPAddressOuter;
                        }
                        else if([ifaName isEqualToString:IOS_WIFI])
                        {
                            netAddress.type = LocalIPAddressInner;
                        }
                        else if([ifaName isEqualToString:IOS_Loopback])
                        {
                            netAddress.type = LocalIPAddressLoopback;
                        }
                        else if ([ifaName containsString:IOS_Bridge])
                        {
                            netAddress.type = LocalIPAddressBridge;
                        }
                        else
                        {
                            netAddress.type = LocalIPAddressOther;
                        }
                        [addresses addObject:netAddress];
                    }
                }
                temp_addr = temp_addr->ifa_next;
            }
        }
    }
    @catch(NSException *exception)
    {
        NSLog(@"Exception: %@", exception);
    }
    @finally
    {
        // Free memory
        freeifaddrs(interfaces);
    }
    if(addresses.count < 1)return nil;
    
    return [NSArray arrayWithArray:addresses];
}


@end
