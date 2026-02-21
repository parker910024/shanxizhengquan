import Foundation
import CryptoKit

/// 加密网络请求管理类
/// - 功能：
///   - Path 生成（pathFn）+ confusePath
///   - AES‑256‑GCM 加解密（SHA256(key+unixString) 派生密钥，IV 12 字节）
///   - 解密时兼容 unixString 的 current/prev/next 三档（±1 分钟）
///   - 请求：POST raw text/plain，body 为密文 base64(IV||ciphertext+tag)
///   - 响应：尝试整体 body 或 JSON 中 cipher/ciphertext/data/result/payload 字段解密
final class SecureNetworkManager {

    // 单例
    static let shared = SecureNetworkManager()
    private init() {}

    /// 在这里配置固定的 BaseURL 和 加密 key
    /// TODO: 按你实际环境改成自己的地址和 key
    private let baseURL = URL(string: "http://112.213.108.32:12025")!
    private let cryptoKey = "123@abc"

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }

    // MARK: - 对外请求接口（你只需要传 api / method / params）

    /// 统一请求入口：
    /// - 你只需要传：api（如 "/api/dev"）、method（.get / .post）、params（字典）
    /// - BaseURL / 加密 key / 加解密细节都在类内部处理
    func request(
        api: String,
        method: HTTPMethod,
        params: [String: Any],
        session: URLSession = .shared,
        completion: @escaping (Result<(decrypted: [String: Any]?, raw: String, statusCode: Int, unixUsed: String?), Error>) -> Void
    ) {
        // 构造与前端 HTML 相同结构的明文 JSON：
        // {
        //   "url": api,
        //   "method": "GET" / "POST",
        //   "param": { ... },
        //   "token": ""   // 如需要可改成实际 token
        // }
        var payload: [String: Any] = [
            "url": api,
            "method": method.rawValue,
            "param": params
        ]
        // 如果你后面有登录态，可以在这里把 token 塞进去
        payload["token"] = ""

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let plainJSON = String(data: jsonData, encoding: .utf8) else {
            let err = NSError(domain: "SecureNetworkManager",
                              code: -100,
                              userInfo: [NSLocalizedDescriptionKey: "参数无法序列化为 JSON"])
            completion(.failure(err))
            return
        }

        // 调用内部加密发送逻辑
        sendEncryptedRequest(
            httpMethod: method.rawValue,
            api: api,
            plainJSON: plainJSON,
            session: session,
            completion: completion
        )
    }

    // MARK: - 内部加密发送实现

    /// 内部：真正发起加密请求
    private func sendEncryptedRequest(
        httpMethod: String,
        api: String,
        plainJSON: String,
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

        // 2. 生成 path + confusePath
        let realPath = PathHelper.pathFn(key: cryptoKey, unixString: baseUnixString)
        let confusePath = PathHelper.confusePath(realPath)
        let finalURL = baseURL.appendingPathComponent(confusePath)

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

        var request = URLRequest(url: finalURL)
        request.httpMethod = httpMethod
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = cipherB64.data(using: .utf8)

        // 5. 发送请求
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            var statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let bodyData = data ?? Data()
            let rawBody = String(data: bodyData, encoding: .utf8) ?? ""

            // 6. 尝试解密响应
            let result = ResponseDecryptor.tryDecryptResponseBody(
                rawData: bodyData,
                key: self.cryptoKey,
                baseUnixString: baseUnixString
            )
            if result.ok {
                // 解密成功时，尝试把明文 JSON 转成字典返回
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
                // 解不出来也返回原文，方便调试
                completion(.success((
                    decrypted: nil,
                    raw: rawBody,
                    statusCode: statusCode,
                    unixUsed: nil
                )))
            }
        }
        task.resume()
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

    /// 规范化 base64（支持 URL-safe，补齐 padding）
    private static func normalizeBase64(_ s: String) -> String {
        var t = s.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = t.count % 4
        if pad != 0 { t.append(String(repeating: "=", count: 4 - pad)) }
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

