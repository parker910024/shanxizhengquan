import SVProgressHUD
import Foundation
import CryptoKit

/// 加密网络请求管理类（与 Android SX-b 一致）
/// - 功能：
///   - Path 生成（pathFn）+ confusePath，与 Android PathCalculator/PathObfuscator 一致
///   - AES‑256‑GCM 加解密（SHA256(key+unixString) 派生密钥，IV 12 字节）
///   - 解密时兼容 unixString 的 current/prev/next 三档（±1 分钟）
///   - 与 Android RequestEncryptInterceptor 一致：所有请求统一发 HTTP POST，URL 无 query，body 为密文；逻辑方法 GET/POST 仅写在明文 JSON 的 method 字段内
///   - 响应：尝试整体 body 或 JSON 中 cipher/ciphertext/data/result/payload 字段解密
final class SecureNetworkManager {

    // 单例
    static let shared = SecureNetworkManager()
    private init() {}

    var vpnSession : URLSession?
    
    /// 在这里配置固定的 BaseURL 和 加密 key
    /// TODO: 按你实际环境改成自己的地址和 key
    private let baseURL = URL(string: vpnDataModel.shared.selectAddress ?? "")!
    private let cryptoKey = "123@abc"

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }

    // MARK: - 对外请求接口（api / method / params；token 从 UserAuthManager 读取，有值则带上传）

    /// 统一请求入口：api、method、params。token 从数据模型 UserAuthManager.shared.token 读取，有值则写入明文 JSON 并带在 Header "token" 上。
    func request(
        api: String,
        method: HTTPMethod,
        params: [String: Any],
        session: URLSession = .shared,
        completion: @escaping (Result<(decrypted: [String: Any]?, raw: String, statusCode: Int, unixUsed: String?), Error>) -> Void
    ) {
        let token = UserAuthManager.shared.token

        var payload: [String: Any] = [
            "url": api,
            "method": method.rawValue,
            "param": params,
            "token": token
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let plainJSON = String(data: jsonData, encoding: .utf8) else {
            let err = NSError(domain: "SecureNetworkManager",
                              code: -100,
                              userInfo: [NSLocalizedDescriptionKey: "参数无法序列化为 JSON"])
            completion(.failure(err))
            return
        }

        print("\n📤 [请求] \(method.rawValue) \(api)")
        print("📦 [参数] \(params)")

        sendEncryptedRequest(
            httpMethod: method.rawValue,
            api: api,
            plainJSON: plainJSON,
            token: token,
            session: session,
            completion: { result in
                switch result {
                case .success(let res):
                    print("\n📥 [响应] \(method.rawValue) \(api) (\(res.statusCode))")
                    if let dict = res.decrypted {
                        print("📄 [数据] \(dict)")
                    } else {
                        print("📄 [原始] \(res.raw.prefix(500))")
                    }
                case .failure(let err):
                    print("\n❌ [失败] \(method.rawValue) \(api): \(err.localizedDescription)")
                }
                completion(result)
            }
        )
    }

    // MARK: - 内部加密发送实现

    /// 内部：真正发起加密请求（Header 必须带 "token"，与 HTML/服务端约定一致）
    private func sendEncryptedRequest(
        httpMethod: String,
        api: String,
        plainJSON: String,
        token: String = "",
        unixString: String? = nil,
        session: URLSession = .shared,
        completion: @escaping (Result<(decrypted: [String: Any]?, raw: String, statusCode: Int, unixUsed: String?), Error>) -> Void
    ) {
        // 1. unixString 处理（默认当前分钟）
        let baseUnixString: String = {
            if let u = unixString, !u.isEmpty {
                return u
            } else {
                return TimeHelper.utcMinuteRange().current
            }
        }()
        
        if vpnSession == nil {
            if vpnDataModel.shared.isProxy == true {
                URLSessionNetworkProxy.stopProxy()
                sleep(UInt32(0.5))
                let start = URLSessionNetworkProxy.startProxy(url: vpnDataModel.shared.proxyURL ?? "")
                if start == true {
                    print("代理vless地址:%@",vpnDataModel.shared.proxyURL)
                    print("代理域名地址:%@",vpnDataModel.shared.selectAddress)
                    print("代理已启动")
                }
                vpnSession =  URLSessionNetworkProxy.newProxySession()
                
                sleep(1)
            }else{
                vpnSession = session
            }
        }
       
        // 2. 生成 path + confusePath，URL 与 HTML 一致：base（去尾斜杠）+ confusePath
        let realPath = PathHelper.pathFn(key: cryptoKey, unixString: baseUnixString)
        let confusePath = PathHelper.confusePath(realPath)
        var baseStr = baseURL.absoluteString
        if baseStr.hasSuffix("/") { baseStr.removeLast() }
        guard let finalURL = URL(string: baseStr + confusePath) else {
            let err = NSError(domain: "SecureNetworkManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "URL 拼接失败"])
            DispatchQueue.main.async { completion(.failure(err)) }
            return
        }

        // 3. 校验 JSON 合法性（防御）
        guard (try? JSONSerialization.jsonObject(with: Data(plainJSON.utf8), options: [])) != nil else {
            let err = NSError(domain: "SecureNetworkManager",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "plainJSON 不是合法 JSON"])
            completion(.failure(err))
            return
        }

        // 4. 加密明文
        guard let cipherB64 = CryptoHelper.encrypt(plainText: plainJSON, key: cryptoKey, unixString: baseUnixString) else {
            let err = NSError(domain: "SecureNetworkManager",
                              code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "加密失败"])
            completion(.failure(err))
            return
        }

        // 与 Android 一致：统一发 POST，URL 无 query，body 为密文；逻辑 GET/POST 已在 plainJSON 的 method 中
        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "token")
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        // 所有请求（含逻辑 GET）都必须携带密文 body，与 Android RequestEncryptInterceptor 一致
        request.httpBody = cipherB64.data(using: .utf8)
        SVProgressHUD.show()
        // 5. 发送请求（URLSession 回调在后台线程，统一回主线程再调 completion，避免在后台改 UI 崩溃）
        let task = vpnSession?.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
            }
            let deliver: () -> Void = {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let bodyData = data ?? Data()
                let rawBody = String(data: bodyData, encoding: .utf8) ?? ""

                let result = ResponseDecryptor.tryDecryptResponseBody(
                    rawData: bodyData,
                    key: self.cryptoKey,
                    baseUnixString: baseUnixString
                )
                if result.ok {
                    var dict: [String: Any]? = nil
                    if let data = result.plain.data(using: .utf8),
                       let obj = try? JSONSerialization.jsonObject(with: data, options: []),
                       let d = obj as? [String: Any] {
                        dict = d
                    }
                    completion(.success((
                        decrypted: dict,
                        raw: rawBody,
                        statusCode: statusCode,
                        unixUsed: result.unixUsed
                    )))
                } else {
                    completion(.success((
                        decrypted: nil,
                        raw: rawBody,
                        statusCode: statusCode,
                        unixUsed: nil
                    )))
                }
            }
            if Thread.isMainThread {
                deliver()
            } else {
                DispatchQueue.main.async(execute: deliver)
            }
        }
        task?.resume()
    }
    
    @MainActor
    func request(
        api: String,
        method: HTTPMethod,
        params: [String: Any],
        unixString: String? = nil,
        session: URLSession = .shared) async throws -> (decrypted: [String: Any]?, raw: String, statusCode: Int, unixUsed: String?) {
            let token = UserAuthManager.shared.token

        let payload: [String: Any] = [
            "url": api,
            "method": method.rawValue,
            "param": params,
            "token": token
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let plainJSON = String(data: jsonData, encoding: .utf8)
        else {
            let err = NSError(domain: "SecureNetworkManager",
                              code: -100,
                              userInfo: [NSLocalizedDescriptionKey: "参数无法序列化为 JSON"])
            throw err
        }

        // 1. unixString 处理（默认当前分钟）
        let baseUnixString: String = {
            if let u = unixString, !u.isEmpty {
                return u
            } else {
                return TimeHelper.utcMinuteRange().current
            }
        }()
            
            if vpnSession == nil {
                if vpnDataModel.shared.isProxy == true {
                    let start = URLSessionNetworkProxy.startProxy(url: vpnDataModel.shared.proxyURL ?? "")
                    if start == true {
                        print("代理vless地址:%@",vpnDataModel.shared.proxyURL)
                        print("代理域名地址:%@",vpnDataModel.shared.selectAddress)
                        print("代理已启动")
                    }
                    vpnSession =  URLSessionNetworkProxy.newProxySession()
                }else{
                    vpnSession = session
                }
            }

        // 2. 生成 path + confusePath，URL 与 HTML 一致：base（去尾斜杠）+ confusePath
        let realPath = PathHelper.pathFn(key: cryptoKey, unixString: baseUnixString)
        let confusePath = PathHelper.confusePath(realPath)
        var baseStr = baseURL.absoluteString
        if baseStr.hasSuffix("/") { baseStr.removeLast() }
        guard let finalURL = URL(string: baseStr + confusePath) else {
            let err = NSError(domain: "SecureNetworkManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "URL 拼接失败"])
            throw err
        }

        // 3. 校验 JSON 合法性（防御）
        guard (try? JSONSerialization.jsonObject(with: Data(plainJSON.utf8), options: [])) != nil else {
            let err = NSError(domain: "SecureNetworkManager",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "plainJSON 不是合法 JSON"])
            throw err
        }

        // 4. 加密明文
        guard let cipherB64 = CryptoHelper.encrypt(plainText: plainJSON, key: cryptoKey, unixString: baseUnixString) else {
            let err = NSError(domain: "SecureNetworkManager",
                              code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "加密失败"])
            throw err
        }

        // 与 Android 一致：统一发 POST，URL 无 query，body 为密文；逻辑 GET/POST 已在 plainJSON 的 method 中
        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "token")
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = cipherB64.data(using: .utf8)
        let (data, response) = try await vpnSession!.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let bodyData = data
        let rawBody = String(data: bodyData, encoding: .utf8) ?? ""

        let result = ResponseDecryptor.tryDecryptResponseBody(
            rawData: bodyData,
            key: self.cryptoKey,
            baseUnixString: baseUnixString
        )
        if result.ok {
            var dict: [String: Any]? = nil
            if let data = result.plain.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data, options: []),
               let d = obj as? [String: Any]
            {
                dict = d
            }
            return (decrypted: dict,
                    raw: rawBody,
                    statusCode: statusCode,
                    unixUsed: result.unixUsed)
        } else {
            return (
                decrypted: nil,
                raw: rawBody,
                statusCode: statusCode,
                unixUsed: nil
            )
        }
    }
    
    func upload(
        image: UIImage,
        path: String = "api/upload/file",
        mimeType: String = "image/png",
        session: URLSession = .shared
    ) async -> String? {
       
        let base = baseURL.absoluteString.hasSuffix("/") ? baseURL.absoluteString : (baseURL.absoluteString + "/")
        guard let url = URL(string: base + path) else {
            return nil
        }
        guard let fileData = image.pngData() else {
            return nil
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(UUID().uuidString + ".png")\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.setValue(UserAuthManager.shared.token, forHTTPHeaderField: "token")
        req.httpBody = body
        
        if vpnSession == nil {
            if vpnDataModel.shared.isProxy == true {
                let start = URLSessionNetworkProxy.startProxy(url: vpnDataModel.shared.proxyURL ?? "")
                if start == true {
                    print("代理vless地址:%@",vpnDataModel.shared.proxyURL)
                    print("代理域名地址:%@",vpnDataModel.shared.selectAddress)
                    print("代理已启动")
                }
                vpnSession =  URLSessionNetworkProxy.newProxySession()
            }else{
                vpnSession = session
            }
        }

        do {
            let (data, response) = try await vpnSession!.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else {
                return nil
            }
            let decoded = try JSONDecoder().decode(UploadResponse.self, from: data)
            if decoded.code == 0 || decoded.code == 1, let path = decoded.data?.path, !path.isEmpty {
                return path
            }
            return nil
        } catch {
            return nil
        }
    }
    
    private struct UploadResponse: Codable {
        let code: Int
        let msg: String?
        let data: UploadData?
    }

    private struct UploadData: Codable {
        let path: String
    }
}

// MARK: - 时间工具

private enum TimeHelper {

    /// 生成 RFC3339（UTC）到分钟的字符串，例如 2026-01-04T12:34:00Z
    static func formatRFC3339NoMillis(_ date: Date) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trimmed = cal.date(from: comps) ?? date

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withColonSeparatorInTimeZone]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let iso = formatter.string(from: trimmed)
        // 去掉毫秒（保险起见），固定为 Z 结尾
        return iso.replacingOccurrences(of: "\\.\\d{3}Z", with: "Z", options: .regularExpression)
    }

    /// 解析 RFC3339 无毫秒
    static func parseRFC3339NoMillis(_ s: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withColonSeparatorInTimeZone]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: s)
    }

    /// 当前分钟的 current/prev/next（UTC）
    static func utcMinuteRange() -> (current: String, prev: String, next: String) {
        let now = Date()
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: now)
        let base = cal.date(from: DateComponents(
            calendar: cal,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: comps.year,
            month: comps.month,
            day: comps.day,
            hour: comps.hour,
            minute: comps.minute
        )) ?? now

        let current = formatRFC3339NoMillis(base)
        let prev = formatRFC3339NoMillis(base.addingTimeInterval(-60))
        let next = formatRFC3339NoMillis(base.addingTimeInterval(60))
        return (current, prev, next)
    }

    /// 基于输入 unixString 生成 current/prev/next 三档
    static func minuteNeighbors(from unixString: String) -> [String] {
        if let d = parseRFC3339NoMillis(unixString) {
            let cal = Calendar(identifier: .iso8601)
            let comps = cal.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: d)
            let base = cal.date(from: DateComponents(
                calendar: cal,
                timeZone: TimeZone(secondsFromGMT: 0),
                year: comps.year,
                month: comps.month,
                day: comps.day,
                hour: comps.hour,
                minute: comps.minute
            )) ?? d

            let cur = formatRFC3339NoMillis(base)
            let prev = formatRFC3339NoMillis(base.addingTimeInterval(-60))
            let next = formatRFC3339NoMillis(base.addingTimeInterval(60))
            return [cur, prev, next]
        } else {
            let r = utcMinuteRange()
            return [r.current, r.prev, r.next]
        }
    }
}

// MARK: - Path 相关

private enum PathHelper {

    /// pathFn："/seg1/seg2/.../segN"
    static func pathFn(key: String, unixString: String) -> String {
        let src = key + String(unixString)
        let digestBytes = CryptoHelper.sha256Bytes(src)  // 32 bytes
        let hashHex = CryptoHelper.bytesToHex(digestBytes) // 64 chars

        var num = Int(digestBytes[0] % 4)
        if num == 0 { num = 4 } // 1..4 段

        var parts: [String] = []
        for i in 1...num {
            var k = Int(digestBytes[i] % 5)
            if k == 0 { k = 5 }   // 1..5 字符
            let start = i * 10
            let end = start + k
            guard start < hashHex.count, end <= hashHex.count else { continue }
            let sIdx = hashHex.index(hashHex.startIndex, offsetBy: start)
            let eIdx = hashHex.index(hashHex.startIndex, offsetBy: end)
            let seg = String(hashHex[sIdx..<eIdx])
            parts.append(seg)
        }
        return "/" + parts.joined(separator: "/")
    }

    /// confusePath：对每一段 seg → rand(left)+seg+rand(right)
    static func confusePath(_ path: String) -> String {
        let comps = path.split(separator: "/", omittingEmptySubsequences: false)
        var out: [String] = []
        for vSub in comps {
            let v = String(vSub)
            if v.isEmpty { continue }
            let len = v.count
            let left = Int((Double(len) / 2.0).rounded())
            let right = len - left
            let confused = CryptoHelper.randString(length: left) + v + CryptoHelper.randString(length: right)
            out.append(confused)
        }
        return "/" + out.joined(separator: "/")
    }
}

// MARK: - 加解密

private enum CryptoHelper {

    /// SHA256(key + unixString) -> 32 bytes
    static func sha256Bytes(_ str: String) -> [UInt8] {
        Array(SHA256.hash(data: Data(str.utf8)))
    }

    static func bytesToHex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static let randChars = Array("abcdefghijklmnopqrstuvwxyz0123456789")

    static func randString(length: Int) -> String {
        guard length > 0 else { return "" }
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return String(bytes.map { randChars[Int($0) % randChars.count] })
    }

    /// 派生 AES key：SHA256(key + unixString)
    private static func deriveSymmetricKey(key: String, unixString: String) -> SymmetricKey {
        let bytes = sha256Bytes(key + String(unixString))
        return SymmetricKey(data: Data(bytes))
    }

    /// 规范化 base64（支持 URL-safe，补齐 padding）— 与 HTML 中 normalizeB64ForAtob 一致
    private static func normalizeBase64(_ s: String) -> String {
        var t = s.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = t.count % 4
        if pad != 0 { t.append(String(repeating: "=", count: 4 - pad)) }
        return t
    }

    /// 转为 URL-safe base64（GET query 用）：+→-、/→_、去掉 =，与 HTML 解密端兼容
    static func toURLSafeBase64(_ standardBase64: String) -> String {
        var t = standardBase64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        t = t.replacingOccurrences(of: "=", with: "")
        return t
    }

    /// 加密：AES-GCM，输出 base64(IV||ciphertext||tag)
    static func encrypt(plainText: String, key: String, unixString: String) -> String? {
        let symmetricKey = deriveSymmetricKey(key: key, unixString: unixString)
        let plainData = Data(plainText.utf8)
        do {
            let sealed = try AES.GCM.seal(plainData, using: symmetricKey)
            guard let combined = sealed.combined else { return nil }
            return combined.base64EncodedString()
        } catch {
            return nil
        }
    }
    
    static func encrypt(data: Data, key: String, unixString: String) -> String? {
        let symmetricKey = deriveSymmetricKey(key: key, unixString: unixString)
        do {
            let sealed = try AES.GCM.seal(data, using: symmetricKey)
            guard let combined = sealed.combined else { return nil }
            return combined.base64EncodedString()
        } catch {
            return nil
        }
    }

    /// 解密单次尝试
    private static func decryptOnce(cipherB64: String, key: String, unixString: String) -> String? {
        let normalized = normalizeBase64(cipherB64)
        guard let data = Data(base64Encoded: normalized) else { return nil }
        let symmetricKey = deriveSymmetricKey(key: key, unixString: unixString)
        do {
            let sealed = try AES.GCM.SealedBox(combined: data)
            let pt = try AES.GCM.open(sealed, using: symmetricKey)
            return String(data: pt, encoding: .utf8)
        } catch {
            return nil
        }
    }

    /// 解密：自动尝试 current/prev/next 三档 unixString
    static func decrypt(cipherB64: String, key: String, baseUnixString: String) -> (plain: String?, unixUsed: String?) {
        let candidates = TimeHelper.minuteNeighbors(from: baseUnixString)
        for u in candidates {
            if let p = decryptOnce(cipherB64: cipherB64, key: key, unixString: u) {
                return (p, u)
            }
        }
        return (nil, nil)
    }
}

// MARK: - 响应解密

private enum ResponseDecryptor {

    /// 粗略判断是否像 base64
    private static func looksLikeBase64(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 16 else { return false }
        let regex = try! NSRegularExpression(pattern: "^[A-Za-z0-9+/_\\-=]+$")
        let range = NSRange(location: 0, length: t.utf16.count)
        return regex.firstMatch(in: t, options: [], range: range) != nil
    }

    private static func pickCipherFromJSON(_ json: Any) -> String? {
        if let s = json as? String {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        guard let dict = json as? [String: Any] else { return nil }

        let keys = ["cipher", "ciphertext", "data", "result", "payload"]

        for k in keys {
            if let v = dict[k] as? String {
                let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { return t }
            }
        }
        if let dataObj = dict["data"] as? [String: Any] {
            for k in keys {
                if let v = dataObj[k] as? String {
                    let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty { return t }
                }
            }
        }
        return nil
    }

    /// JS 里的 tryDecryptResponseWithUnixList 逻辑
    static func tryDecryptResponseBody(
        rawData: Data,
        key: String,
        baseUnixString: String
    ) -> (ok: Bool, cipher: String, plain: String, unixUsed: String, reason: String) {

        guard let raw = String(data: rawData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty
        else {
            return (false, "", "", "", "响应为空")
        }

        var cipherCandidate = raw
        // 如果整段不像 base64，则尝试从 JSON 提取
        if !looksLikeBase64(cipherCandidate) {
            if let obj = try? JSONSerialization.jsonObject(with: rawData, options: []),
               let picked = pickCipherFromJSON(obj) {
                cipherCandidate = picked
            }
        }

        if !looksLikeBase64(cipherCandidate) {
            return (
                false,
                "",
                "",
                "",
                "未找到可解密的 base64 密文（raw 不是 base64，JSON 也未提取到 cipher/ciphertext/data/result/payload）"
            )
        }

        let (plain, unixUsed) = CryptoHelper.decrypt(cipherB64: cipherCandidate, key: key, baseUnixString: baseUnixString)
        if let p = plain, let u = unixUsed {
            return (true, cipherCandidate, p, u, "")
        } else {
            return (
                false,
                cipherCandidate,
                "",
                "",
                "解密失败：key 或 unixString 不匹配（已尝试 current/prev/next 三档）"
            )
        }
    }
}

