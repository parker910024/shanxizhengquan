//
//  LaunchViewController.swift
//  zhengqaun
//
//  启动页：展示 logo，有网时执行 startLoad（仅一次），3 秒后自动跳转登录页或 TabBar
//

import UIKit
import Network

class LaunchViewController: UIViewController {

    /// 3 秒后由 SceneDelegate 执行跳转（登录页或 TabBar）
    var onFinish: (() -> Void)?
    

    private let logoImageView = UIImageView()

    /// 确保 startLoad 仅执行一次
    private static var hasExecutedStartLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        logoImageView.image = UIImage(named: "logoIcon")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.clipsToBounds = true
        view.addSubview(logoImageView)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120)
        ])

        checkNetworkAndStartLoad()
    }

    /// 有网时执行 startLoad，且仅执行一次；增加兜底超时防止卡死
    private func checkNetworkAndStartLoad() {
        guard !Self.hasExecutedStartLoad else { return }

        // 兜底超时：无论网络检测或 tcpping 结果如何，10 秒后必须跳转
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self, !Self.hasExecutedStartLoad else { return }
            Self.hasExecutedStartLoad = true
            self.onFinish?()
        }

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            // 有网且未执行过 → 执行 startLoad 并停止监听
            if path.status == .satisfied, !Self.hasExecutedStartLoad {
                Self.hasExecutedStartLoad = true
                monitor.cancel()
                DispatchQueue.main.async {
                    self?.startLoad()
                }
            }
            // 无网时不 cancel，持续监听，等待网络恢复；兜底超时会保底跳转
        }
        monitor.start(queue: DispatchQueue(label: "launch.network.check"))
    }

    func startLoad() {
        vpnDataModel.shared.ipDataArray = NSMutableArray()
        vpnDataModel.shared.proxyIpDataArray = Array()

        let arr = [
            "https://13.231.202.103:51000",
            "https://35.72.5.84:51000"
        ]
        
        vpnDataModel.shared.selectAddress  = arr[0]

        for i in 0..<arr.count {
            let name = "线路\(i + 1)"
            vpnDataModel.shared.ipDataArray?.add(["name": name, "value": arr[i]])
        }

        let domainArray = [
            "52.195.189.185", "54.250.165.226", "52.192.168.3",
            "43.207.198.214", "103.45.64.34"
        ]

        vpnDataModel.shared.proxyIpDataArray = domainArray

        let lines = [
            "183.240.252.113:24846@b4ea7947-5872-4253-ad9f-ce3464a6e801",
            "183.240.252.114:24846@b4ea7947-5872-4253-ad9f-ce3464a6e801",
            "183.240.252.126:24846@b4ea7947-5872-4253-ad9f-ce3464a6e801",
            "183.240.252.126:24846@b4ea7947-5872-4253-ad9f-ce3464a6e802",
            "183.240.252.126:24846@b4ea7947-5872-4253-ad9f-ce3464a6e803"
        ]

        var ipArray: [String] = []
        for line in lines {
            let parts = line.split(separator: "@").map(String.init)
            let ip = parts.isEmpty ? "" : parts[0]
            let udid = parts.count > 1 ? parts[1] : ""
            let vless = "vless://\(udid)@\(ip)?encryption=none&security=none&type=tcp&headerType=none#\(ip)"
            ipArray.append(vless)
        }

//        Toast.show("优质线路自动检测中...")

        if !ipArray.isEmpty {
            DataModelTcpping.tcpping(ipArray) { [weak self] results in
                var minLatency = Int.max
                var minUrl: String?
                var hasValid = false

                for dic in results {
                    let url = (dic["url"] as? String) ?? ""
                    let latency = (dic["latency"] as? NSNumber)?.intValue ?? 5000
                    print("延迟URL: \(url)，延迟: \(latency)ms")
                    if latency != 5000 {
                        hasValid = true
                        if latency < minLatency {
                            minLatency = latency
                            minUrl = url
                        }
                    }
                }

                if hasValid, let url = minUrl {
                    print("最低延迟URL: \(url)，延迟: \(minLatency)ms")
                    vpnDataModel.shared.isProxy = true
                    vpnDataModel.shared.proxyURL = url
                    DispatchQueue.main.async { self?.updateLineView() }
                } else {
                    vpnDataModel.shared.isProxy = false
                    DispatchQueue.main.async { self?.updateLineView() }
//                    Toast.show("节点线路不可用")
                }
            }
        } else {
            vpnDataModel.shared.isProxy = false
            DispatchQueue.main.async { [weak self] in self?.updateLineView() }
            Toast.show("节点线路数据错误")
        }
    }
    
    func updateLineView() {
        self.onFinish?()

    }
    
}


