//
//  vpnDataModel.swift
//  zhengqaun
//
//  Created by admin on 2026/2/23.
//

import UIKit

class vpnDataModel: NSObject {

    
    @objc static let shared = vpnDataModel()
    
    @objc var ipDataArray:NSMutableArray?
    @objc var proxyIpDataArray:Array<String>?
    
    var isProxy:Bool?
    @objc var proxyURL:String?
    
    @objc var selectAddress:String?
    
}
