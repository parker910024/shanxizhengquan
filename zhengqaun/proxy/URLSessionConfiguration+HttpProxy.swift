//
//  URLSessionConfiguration+HttpProxy.swift
//  HttpProxyDemo
//
//  Created by md on 2021/5/5.
//  Copyright © 2021 md. All rights reserved.
//

import Foundation

fileprivate let httpProxyKey = kCFNetworkProxiesHTTPEnable as String
fileprivate let httpHostKey = kCFNetworkProxiesHTTPProxy as String
fileprivate let httpPortKey = kCFNetworkProxiesHTTPPort as String
fileprivate let httpsProxyKey = "HTTPSEnable"
fileprivate let httpsHostKey = "HTTPSProxy"
fileprivate let httpsPortKey = "HTTPSPort"

typealias HttpProxyConfig = (host: String, port: Int)
let httpSchemes = ["http", "https"]

extension URLSessionConfiguration {
    @objc
    func addProxyConfig(_ xhost:String, xport: Int) {
        let (host, port) = (xhost, xport)
        let proxyDict: [String: Any] = [httpProxyKey: true,
                                        httpHostKey: host,
                                        httpPortKey: port,
                                        httpsProxyKey: true,
                                        httpsHostKey: host,
                                        httpsPortKey: port]
        connectionProxyDictionary = proxyDict
    }
     
    func hasProxyConfig(_ xhost:String, xport: Int) -> Bool {
        guard let proxyDic = connectionProxyDictionary,
              let host = proxyDic[httpHostKey] as? String,
              let port = proxyDic[httpPortKey] as? Int,
              (host, port) == (xhost, xport)
        else {
            return false
        }
        return true
    }
}



