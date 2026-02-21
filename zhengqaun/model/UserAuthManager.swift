//
//  UserAuthManager.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import Foundation

/// 用户登录状态管理类
class UserAuthManager {
    
    static let shared = UserAuthManager()
    
    private let isLoggedInKey = "UserAuthManager.isLoggedIn"
    private let usernameKey = "UserAuthManager.username"
    private let phoneKey = "UserAuthManager.phone"

    
    var phoneRegister = false

    private init() {}
    
    /// 是否已登录
    var isLoggedIn: Bool {
        get {
            return UserDefaults.standard.bool(forKey: isLoggedInKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: isLoggedInKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    var token: String {
        get {
            return UserDefaults.standard.value(forKey: "token") as? String ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "token")
            UserDefaults.standard.synchronize()
        }
    }
    
    var userID: String {
        get {
            return UserDefaults.standard.value(forKey: "userID") as? String ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userID")
            UserDefaults.standard.synchronize()
        }
    }
    
    /// 当前登录用户名
    var currentUsername: String? {
        get {
            return UserDefaults.standard.string(forKey: usernameKey)
        }
        set {
            if let username = newValue {
                UserDefaults.standard.set(username, forKey: usernameKey)
            } else {
                UserDefaults.standard.removeObject(forKey: usernameKey)
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    /// 当前登录手机号
    var currentPhone: String? {
        get {
            return UserDefaults.standard.string(forKey: phoneKey)
        }
        set {
            if let phone = newValue {
                UserDefaults.standard.set(phone, forKey: phoneKey)
            } else {
                UserDefaults.standard.removeObject(forKey: phoneKey)
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    /// 登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - phone: 手机号
    func login(username: String, phone: String) {
        isLoggedIn = true
        currentUsername = username
        currentPhone = phone
    }
    
    /// 注册并登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - phone: 手机号
    func registerAndLogin(username: String, phone: String) {
        isLoggedIn = true
        currentUsername = username
        currentPhone = phone
    }
    
    /// 登出
    func logout() {
        isLoggedIn = false
        currentUsername = nil
        currentPhone = nil
    }
    
}


