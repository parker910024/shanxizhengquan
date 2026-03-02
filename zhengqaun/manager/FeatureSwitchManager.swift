//
//  FeatureSwitchManager.swift
//  zhengqaun
//
//  功能开关管理器：通过 /api/Indexnew/sgandps 接口获取功能模块开关状态
//

import Foundation

class FeatureSwitchManager {
    static let shared = FeatureSwitchManager()
    private init() {}

    // 通知名称，当开关数据加载完成后发送
    static let didUpdateNotification = Notification.Name("FeatureSwitchDidUpdate")

    // MARK: - 功能开关
    /// 大宗交易是否显示
    var isDzjyEnabled: Bool = true
    /// 新股申购是否显示
    var isXgsgEnabled: Bool = true
    /// 线下配售是否显示
    var isXxpsEnabled: Bool = true

    // MARK: - 功能名称（后端可配置）
    var nameDzjy: String = "大宗交易"
    var nameXgsg: String = "新股申购"
    var nameXxps: String = "战略配售"

    // MARK: - 数据列表
    var listDzjy: [[String: Any]] = []
    var listPs: [[String: Any]] = []
    var listSg: [[String: Any]] = []

    /// 是否已加载过
    private(set) var isLoaded: Bool = false

    // MARK: - 加载开关配置
    func loadConfig() {
        SecureNetworkManager.shared.request(
            api: "/api/Indexnew/sgandps",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any] else { return }

                // 解析开关状态（支持 "1" 或者数字 1）
                let isDzjyVal = data["is_dzjy"]
                self.isDzjyEnabled = (isDzjyVal as? String == "1") || (isDzjyVal as? Int == 1)
                
                let isXgsgVal = data["is_xgsg"]
                self.isXgsgEnabled = (isXgsgVal as? String == "1") || (isXgsgVal as? Int == 1)
                
                let isXxpsVal = data["is_xxps"]
                self.isXxpsEnabled = (isXxpsVal as? String == "1") || (isXxpsVal as? Int == 1)

                // 解析功能名称
                if let n = data["name_dzjy"] as? String, !n.isEmpty { self.nameDzjy = n }
                if let n = data["name_xgsg"] as? String, !n.isEmpty { self.nameXgsg = n }
                // 解析 name_xxps 取代本地默认的「战略配售」
                if let n = data["name_xxps"] as? String, !n.isEmpty { self.nameXxps = n }

                // 打印原始类型帮助排查解析失败
                print("[调试] sgandps 原始 list_dzjy 类型: \(type(of: data["list_dzjy"]))")
                print("[调试] sgandps 原始 list_ps 类型: \(type(of: data["list_ps"]))")
                if let dzjyRaw = data["list_dzjy"] { print("[调试] list_dzjy 有值: \(dzjyRaw)") }
                
                // 解析列表数据（兼容 NSArray 格式）
                if let dzjyArr = data["list_dzjy"] as? [Any] {
                    self.listDzjy = dzjyArr.compactMap { $0 as? [String: Any] }
                } else {
                    self.listDzjy = []
                }
                
                if let psArr = data["list_ps"] as? [Any] {
                    self.listPs = psArr.compactMap { $0 as? [String: Any] }
                } else {
                    self.listPs = []
                }
                
                if let sgArr = data["list_sg"] as? [Any] {
                    self.listSg = sgArr.compactMap { $0 as? [String: Any] }
                } else {
                    self.listSg = []
                }

                self.isLoaded = true

                // 发送通知，各页面收到后刷新UI
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: FeatureSwitchManager.didUpdateNotification, object: nil)
                }

            case .failure(_): break
            }
        }
    }
}
