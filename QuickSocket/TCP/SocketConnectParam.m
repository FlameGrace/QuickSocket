//
//  SocketConnectParam.m
//  Example
//
//  Created by zhuruhong on 16/8/15.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import "SocketConnectParam.h"

@implementation SocketConnectParam

- (instancetype)init
{
    if (self = [super init]) {
        _useSecureConnection = NO;
        _timeout = 15;
        _autoHeartbeat = YES;
        _heartbeatInterval = 20;
        _autoReconnect = NO;
    }
    return self;
}

- (NSDictionary *)tlsSettings
{
    if (nil == _tlsSettings) {
        // Configure SSL/TLS settings
        NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
        settings[(NSString *)kCFStreamSSLPeerName] = _host;
        self.tlsSettings= settings;
    }
    return _tlsSettings;
}

@end
