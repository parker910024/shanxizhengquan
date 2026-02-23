//
//  NSURLRequest+ProxyCanonicalRequest.h
//  FrameworkCommon
//
//  Created by md on 2025/4/29.
//  Copyright © 2018 md. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLRequest (ProxyCanonicalRequest)

- (NSURLRequest *)cdz_canonicalRequest;

@end

NS_ASSUME_NONNULL_END
