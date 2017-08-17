//
//  AXNetAddress.m
//  p2p
//
//  Created by Flame Grace on 16/10/28.
//  Copyright © 2016年 hello. All rights reserved.
//

#import "LocalIPAddress.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>



@implementation LocalIPAddress
    
+ (BOOL)isIpAddressValid:(NSString *)ipAddress
{
    if([ipAddress isEqualToString:@"0.0.0.0"])
    {
        return NO;
    }
    struct in_addr pin;
    int success = inet_aton([ipAddress UTF8String],&pin);
    if (success == 1) return YES;
    return NO;
}


@end
