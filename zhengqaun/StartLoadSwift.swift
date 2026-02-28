//
//  StartLoadSwift.swift
//  zhengqaun
//
//  OC startLoad 转 Swift。需在项目中提供：
//  - DataModel：shared、ipDataArray、proxyIpDataArray、isProxy、proxyURL、tcpping(ipArray:completion:)
//  - xiaoIPProxyModel：shared、proxyIpDataArray
//  - 当前 VC 实现 updateLineView()
//

import UIKit

// MARK: - 将下方 startLoad() 复制到你的 ViewController 中即可使用

/*
func startLoad() {
    DataModel.shared.ipDataArray = []
    xiaoIPProxyModel.shared.proxyIpDataArray = []
    DataModel.shared.proxyIpDataArray = []

    let arr = [
        "https://13.231.202.103:51000",
        "https://35.72.5.84:51000"
    ]

    for i in 0..<arr.count {
        let name = "线路\(i + 1)"
        DataModel.shared.ipDataArray.append(["name": name, "value": arr[i]])
    }

    let domainArray = [
        "52.195.189.185",
        "54.250.165.226",
        "52.192.168.3",
        "43.207.198.214",
        "103.45.64.34"
    ]

    xiaoIPProxyModel.shared.proxyIpDataArray.append(contentsOf: domainArray)
    DataModel.shared.proxyIpDataArray.append(contentsOf: domainArray)

    let lines = [
        "183.240.252.113:24846@b4ea7947-5872-4253-ad9f-ce3464a6e801",
        "183.240.252.114:24846@b4ea7947-5872-4253-ad9f-ce3464a6e801",
        "183.240.252.126:24846@b4ea7947-5872-4253-ad9f-ce3464a6e801"
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
        DataModel.tcpping(ipArray) { [weak self] results in
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
                DataModel.shared.isProxy = true
                DataModel.shared.proxyURL = url
                DispatchQueue.main.async { self?.updateLineView() }
            } else {
                DataModel.shared.isProxy = false
                DispatchQueue.main.async { self?.updateLineView() }
                Toast.show("节点线路不可用")
            }
        }
    } else {
        DataModel.shared.isProxy = false
        DispatchQueue.main.async { [weak self] in self?.updateLineView() }
        Toast.show("节点线路数据错误")
    }
}
*/
