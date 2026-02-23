//
//  xVPNProtocolParser.h
//  xVPN
//
//  Created by DDD on 2022/11/1.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    xVPNProtocolVmess,
    xVPNProtocolVless,
    xVPNProtocolTrojan,
    xVPNProtocolSS,
    xVPNProtocolSocks
} xVPNProtocol;


NS_ASSUME_NONNULL_BEGIN

@interface XiaoNiuParser : NSObject

+(void)setHttpProxyPort:(uint16_t)port;

+(uint16_t)HttpProxyPort;

+(void)setLogLevel:(NSString *)level;

+ (void)setGlobalProxyEnable:(BOOL)enable;

+ (void)setGlobalDirectEnable:(BOOL)enable;

+ (void)setDirectDomainList:(NSArray *)list;

+ (void)setProxyDomainList:(NSArray *)list;

+ (void)setBlockDomainList:(NSArray *)list;

+ (NSDictionary *)parseURI:(NSString *)uri;

+(NSDictionary *)GetStatsPolicy;
@end

NS_ASSUME_NONNULL_END
