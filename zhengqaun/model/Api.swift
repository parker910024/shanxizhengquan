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
    
    //资产(个人中心)
    static let getUserPrice_all_api = "/api/user/getUserPrice_all"
    
    //验证支付密码
    static let checkOldpay_api = "/api/user/checkOldpay"
    
    //修改支付密码
    static let editPass_api = "/api/user/editPass"
    static let editPass1_api = "/api/user/editPass1"  // 修改登录密码
    
    //本地上传
    static let upload_api = "/api/upload/file"
    
    //提交实名认证
    static let authentication_api = "/api/user/authentication"
    
    //实名认证详情
    static let authenticationDetail_api = "/api/user/authenticationDetail"

    //消息列表
    static let message_list_api = "/api/news/index"
    
    //消息详情
    static let message_detail_api = "/api/news/detail"
    
    // 新股申购列表
    static let subscribe_api = "/api/subscribe/lst"

    //银行卡列表
    static let accountLst_api = "/api/user/accountLst"
    
    //绑定银行卡
    static let bindaccount_api = "/api/user/bindaccount"
    
    //合同列表
    static let contracts_api = "/api/stock/contracts"
    
    //合同签约
    static let dosignContract_api = "/api/user/dosignContract"
}
