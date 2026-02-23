//
//  Api.swift
//  zhengqaun
//
//  Created by admin on 2026/2/22.
//

import UIKit

class Api: NSObject {
    
    //登录
    static let login_api = "/api/user/login"

    //获取用户信息
    static let user_info_api = "/api/stock/info"
    
    //立即开户
    static let create_account_api = "/api/user/register"
    
    //消息列表
    static let message_list_api = "/api/news/index"
    
    //消息详情
    static let message_detail_api = "/api/news/detail"
    
    // 新股申购列表
    static let subscribe_api = "/api/subscribe/lst"
    
}
