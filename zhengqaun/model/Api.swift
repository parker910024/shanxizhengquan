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
    
    //本地上传
    static let upload_api = "/api/upload/file"
    
    //提交实名认证
    static let authentication_api = "/api/user/authentication"
    
    //实名认证详情
    static let authenticationDetail_api = "/api/user/authenticationDetail"
}
