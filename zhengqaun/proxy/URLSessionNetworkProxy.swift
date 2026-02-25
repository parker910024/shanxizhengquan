//
//  MMWebView.swift
//  x-sing-box
//
//  Created by xjj on 2025/5/8.
//

import UIKit
import WebKit
import Pi

@objcMembers
class URLSessionNetworkProxy: NSObject, PiApplePrinterProtocol {
    
    private static let _engine: URLSessionNetworkProxy = URLSessionNetworkProxy();
    static let shared: URLSessionNetworkProxy = {
        return _engine;
    }();
    
    func applePrint(_ log: String?) {
        guard let log = log else { return ; }
        NSLog("GoJNI: \(log)")
    }
    
    private func start(proxy:String) -> Bool {
        XiaoNiuParser.setGlobalProxyEnable(true)
        
        let json = XiaoNiuParser.parseURI(proxy)
        do {
            let data = try JSONSerialization.data(withJSONObject: json)
            let x = PiStartVPN(data, proxy)
            return x.isEmpty
        }
        catch(let exception) {
            NSLog("ec: \(exception)")
            return false
        }
    }
    
    private func stop(){
        PiStopVPN();
    }
    
    static func newProxyWebView(frame:CGRect) -> WKWebView {
        let config = WKWebViewConfiguration();
        config.addProxyConfig("127.0.0.1", xport: 1236)
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        let webView = WKWebView(frame: frame, configuration: config)
        return webView;
    }
    
    static func newProxySession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.addProxyConfig("127.0.0.1", xport: 1236)
        
        let sessionDelegate = HttpProxySession.Delegate()
        return URLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
    }
    
    static func startProxy(url:String) -> Bool {
        PiSetApplePrinter(URLSessionNetworkProxy.shared)
        return URLSessionNetworkProxy.shared.start(proxy: url)
    }
    
    static func stopProxy(){
        URLSessionNetworkProxy.shared.stop();
    }
    

}
