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
    var nameXxps: String = "线下配售"

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

                // 解析开关状态（"1" 为开启，其他为关闭）
                self.isDzjyEnabled = (data["is_dzjy"] as? String ?? "0") == "1"
                self.isXgsgEnabled = (data["is_xgsg"] as? String ?? "0") == "1"
                self.isXxpsEnabled = (data["is_xxps"] as? String ?? "0") == "1"

                // 解析功能名称
                if let n = data["name_dzjy"] as? String, !n.isEmpty { self.nameDzjy = n }
                if let n = data["name_xgsg"] as? String, !n.isEmpty { self.nameXgsg = n }
                if let n = data["name_xxps"] as? String, !n.isEmpty { self.nameXxps = n }

                // 解析列表数据
                self.listDzjy = data["list_dzjy"] as? [[String: Any]] ?? []
                self.listPs   = data["list_ps"] as? [[String: Any]] ?? []
                self.listSg   = data["list_sg"] as? [[String: Any]] ?? []

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
