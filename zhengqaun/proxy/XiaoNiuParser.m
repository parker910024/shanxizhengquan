//
//  xVPNProtocolParser.m
//  xVPN
//
//  Created by DDD on 2022/11/1.
//

#import "XiaoNiuParser.h"
#import "XiaoNiuParserVless.h"

static uint16_t __http_proxy_port__ = 1236;
static NSMutableArray *__directDomainList__ = nil;
static NSMutableArray *__proxyDomainList__ = nil;
static NSMutableArray *__blockDomainList__ = nil;

@implementation XiaoNiuParser

+(void)setHttpProxyPort:(uint16_t)port {
    __http_proxy_port__ = port;
    [XiaoNiuParserVless setHttpProxyPort:port];
}

+(uint16_t)HttpProxyPort {
    return __http_proxy_port__;
}

+(void)setLogLevel:(NSString *)level {
    [XiaoNiuParserVless setLogLevel:level];
}

+ (void)setGlobalProxyEnable:(BOOL)enable {
    [XiaoNiuParserVless setGlobalProxyEnable:enable];
}

+ (void)setGlobalDirectEnable:(BOOL)enable {
    [XiaoNiuParserVless setGlobalDirectEnable:enable];
}

+ (void)setDirectDomainList:(NSArray *)list {
    __directDomainList__ = list.mutableCopy;
    [XiaoNiuParserVless setDirectDomainList:list];
}

+ (void)setProxyDomainList:(NSArray *)list {
    __proxyDomainList__ = list.mutableCopy;
    [XiaoNiuParserVless setProxyDomainList:list];
}

+ (void)setBlockDomainList:(NSArray *)list {
    __blockDomainList__ = list.mutableCopy;
    [XiaoNiuParserVless setBlockDomainList:list];
}

+(nullable NSDictionary *)parse:(NSString *)uri protocol:(xVPNProtocol)protocol {
    
    switch (protocol) {
        case xVPNProtocolVless:
            return [XiaoNiuParserVless parseVless:uri];
        default:
            break;
    }
    return nil;
}

+ (NSDictionary *)parseURI:(NSString *)uri {
    NSArray <NSString *>*list = [uri componentsSeparatedByString:@"//"];
    xVPNProtocol protocol;
    if (list.count != 2) {
        list = [uri componentsSeparatedByString:@":"];
        if (list.count != 2) {
            return nil;
        }
    }
    if ([list[0] hasPrefix:@"vmess"]) {
        protocol = xVPNProtocolVmess;
    }
    else if ([list[0] hasPrefix:@"vless"]) {
        protocol = xVPNProtocolVless;
    }
    else if ([list[0] hasPrefix:@"trojan"]) {
        protocol = xVPNProtocolTrojan;
    }
    else if ([list[0] hasPrefix:@"ss"]) {
        protocol = xVPNProtocolSS;
    }
    else if ([list[0] hasPrefix:@"socks"]) {
        protocol = xVPNProtocolSocks;
    }
    else {
        return nil;
    }
    NSDictionary *configuration = [XiaoNiuParser parse:list[1] protocol:protocol];
    return configuration;
}



+(NSDictionary *)GetStatsPolicy {
    NSDictionary *policy = @{
        @"system": @{
            @"statsOutboundUplink": [NSNumber numberWithBool:true],
            @"statsOutboundDownlink": [NSNumber numberWithBool:true]
        }
    };
    return policy;
}

@end

