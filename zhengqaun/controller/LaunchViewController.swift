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

    /// 有网时执行 startLoad，且仅执行一次；无网则 3 秒后跳转
    private func checkNetworkAndStartLoad() {
        guard !Self.hasExecutedStartLoad else { return }

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            monitor.cancel()
            if path.status == .satisfied, !Self.hasExecutedStartLoad {
                Self.hasExecutedStartLoad = true
                DispatchQueue.main.async {
                    self?.startLoad()
                }
            } else {
                // 无网：3 秒后跳转，避免卡在启动页
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//                    self?.onFinish?()
//                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "launch.network.check"))
    }

    func startLoad() {
        vpnDataModel.shared.ipDataArray = NSMutableArray()
        vpnDataModel.shared.proxyIpDataArray = Array()

        let arr = [
            "http://112.213.108.32:12025",
            "http://112.213.108.32:12025",
            "http://112.213.108.32:12025",
            "http://112.213.108.32:12025"
        ]
        
        vpnDataModel.shared.selectAddress  = arr[0]

        for i in 0..<arr.count {
            let name = "线路\(i + 1)"
            vpnDataModel.shared.ipDataArray?.add(["name": name, "value": arr[i]])
        }

        let domainArray = [
            "112.213.108.32", "112.213.108.32", "112.213.108.32",
            "112.213.108.32", "112.213.108.32"
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

        Toast.show("优质线路自动检测中...")

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
                    Toast.show("节点线路不可用")
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
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        // 3 秒后跳转
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
//            self?.onFinish?()
//        }
    }
}


