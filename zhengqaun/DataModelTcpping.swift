//
//  DataModelTcpping.swift
//  zhengqaun
//
//  OC tcpping / pingIP 转 Swift（TCP 测延迟，并发限制 + 主线程回调）
//

import Foundation
import Darwin

// Swift 无 FD_ZERO/FD_SET 宏，需手动操作 fd_set
private func fdZero(_ set: inout fd_set) {
    withUnsafeMutablePointer(to: &set) {
        $0.withMemoryRebound(to: Int32.self, capacity: 32) {
            for i in 0..<32 { $0[i] = 0 }
        }
    }
}

private func fdSet(_ fd: Int32, _ set: inout fd_set) {
    withUnsafeMutablePointer(to: &set) {
        $0.withMemoryRebound(to: Int32.self, capacity: 32) {
            let idx = Int(fd) / 32
            let bit = Int(fd) % 32
            $0[idx] |= 1 << bit
        }
    }
}

/// 可放在 DataModel 中作为静态方法，或独立工具类
enum DataModelTcpping {

    private static let resultQueue = DispatchQueue(label: "tcpping.result.queue", attributes: .concurrent)
    private static let maxConcurrent = 10
    private static let semaphore = DispatchSemaphore(value: maxConcurrent)

    /// 对一组 VLESS URL 做 TCP ping，回调每个 url 及延迟(ms)，5000 表示超时/失败
    static func tcpping(_ ipArray: [String], completion: @escaping ([[String: Any]]) -> Void) {
        guard !ipArray.isEmpty else {
            completion([])
            return
        }

        let group = DispatchGroup()
        var results: [[String: Any]] = []

        for url in ipArray {
            semaphore.wait()
            group.enter()

            let ip = parseIP(from: url)
            pingIP(ip, timeout: 5) { latency in
                resultQueue.async(flags: .barrier) {
                    results.append(["url": url, "latency": latency])
                }
                semaphore.signal()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            resultQueue.sync {
                completion(results)
            }
        }
    }

    /// 从 vless://uuid@host:port?... 中解析出 host
    private static func parseIP(from url: String) -> String {
        guard let atRange = url.range(of: "@") else { return "" }
        let afterAt = url[atRange.upperBound...]
        guard let colonRange = afterAt.range(of: ":") else { return String(afterAt) }
        return String(afterAt[..<colonRange.lowerBound])
    }

    /// TCP 连接测延迟，超时或失败返回 5000
    static func pingIP(_ ip: String, timeout: Int, completion: @escaping (Int) -> Void) {
        guard !ip.isEmpty else {
            DispatchQueue.main.async { completion(5000) }
            return
        }

        DispatchQueue.global(qos: .default).async {
            var latency = 5000
            let sockfd = socket(AF_INET, SOCK_STREAM, 0)
            defer { if sockfd >= 0 { close(sockfd) } }

            if sockfd < 0 {
                DispatchQueue.main.async { completion(5000) }
                return
            }

            var serv_addr = sockaddr_in()
            serv_addr.sin_family = sa_family_t(AF_INET)
            serv_addr.sin_port = UInt16(80).bigEndian
            guard ip.withCString({ inet_pton(AF_INET, $0, &serv_addr.sin_addr) == 1 }) else {
                DispatchQueue.main.async { completion(5000) }
                return
            }

            var start = timeval(tv_sec: 0, tv_usec: 0)
            var end = timeval(tv_sec: 0, tv_usec: 0)
            gettimeofday(&start, nil)

            var flags = fcntl(sockfd, F_GETFL, 0)
            _ = fcntl(sockfd, F_SETFL, flags | O_NONBLOCK)

            let res = withUnsafePointer(to: &serv_addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    connect(sockfd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }

            if res == 0 {
                gettimeofday(&end, nil)
                latency = Int(end.tv_sec - start.tv_sec) * 1000 + Int(end.tv_usec - start.tv_usec) / 1000
            } else if errno == EINPROGRESS {
                var wf = fd_set()
                fdZero(&wf)
                fdSet(sockfd, &wf)
                var tv = timeval(tv_sec: __darwin_time_t(Int32(timeout)), tv_usec: 0)
                let sel = select(sockfd + 1, nil, &wf, nil, &tv)
                if sel > 0 {
                    var so_error: Int32 = 0
                    var len = socklen_t(MemoryLayout<Int32>.size)
                    getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &so_error, &len)
                    if so_error == 0 {
                        gettimeofday(&end, nil)
                        latency = Int(end.tv_sec - start.tv_sec) * 1000 + Int(end.tv_usec - start.tv_usec) / 1000
                    }
                }
            }

            if latency > timeout * 1000 { latency = 5000 }
            DispatchQueue.main.async { completion(latency) }
        }
    }
}
