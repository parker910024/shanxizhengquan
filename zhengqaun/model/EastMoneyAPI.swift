//
//  EastMoneyAPI.swift
//  zhengqaun
//
//  东方财富公开 API 请求服务
//  龙虎榜数据来源：datacenter-web.eastmoney.com
//

import Foundation

/// 东方财富 API 请求服务（公开接口，无需加密，直接 URLSession 请求）
final class EastMoneyAPI {

    static let shared = EastMoneyAPI()
    private init() {}

    private let baseURL = "https://datacenter-web.eastmoney.com/api/data/v1/get"
    private let session = URLSession.shared

    // MARK: - 龙虎榜列表

    // 东方财富多种报表名组合，与 Android 对齐
    private let reportNames = [
        "RPT_DAILYBILLBOARD_DETAILS",
        "RPT_DAILYBILLBOARD",
        "RPT_BILLBOARD_DAILY",
        "RPT_BLOCKOPERATION"
    ]

    /// 请求龙虎榜日榜列表（引入内部重试及去重机制）
    /// - Parameters:
    ///   - date: 交易日期，格式 "yyyy-MM-dd"
    ///   - completion: 返回结果（主线程回调）
    func fetchLongHuBangList(
        date: String,
        completion: @escaping (Result<LongHuBangResponse, Error>) -> Void
    ) {
        // Android 中的 filter 写法组合：
        let filters = [
            "(TRADE_DATE<='\(date)')",
            "(TRADE_DATE='\(date)')",
            "(ONLIST_DATE>='\(date)')",
            "(TRADE_DATE='\(date.replacingOccurrences(of: "-", with: ""))')"
        ]
        
        let combinations: [(report: String, filter: String)] = reportNames.flatMap { r in
            filters.map { f in (report: r, filter: f) }
        }
        
        // 使用递归或异步闭包链逐个尝试，直到成功获取到非空数据或者全部失败
        tryFetch(date: date, combinations: combinations, index: 0) { finalResult in
            switch finalResult {
            case .success(let response):
                // 成功获取到数据后，对齐 Android 做去重
                if let items = response.result?.data, !items.isEmpty {
                    // 1. 过滤日期：只保留 TRADE_DATE 以参数 date 开头的项
                    let sameDayItems = items.filter { $0.TRADE_DATE?.hasPrefix(date) == true }
                    let dayItems = sameDayItems.isEmpty ? items : sameDayItems
                    
                    // 2. 按 code 去重，保留净买入 (BILLBOARD_NET_AMT) 绝对值最大的
                    var grouped: [String: LongHuBangRawItem] = [:]
                    for item in dayItems {
                        guard let code = item.SECURITY_CODE else { continue }
                        if let existing = grouped[code] {
                            let currNet = abs(item.BILLBOARD_NET_AMT ?? 0)
                            let existNet = abs(existing.BILLBOARD_NET_AMT ?? 0)
                            if currNet > existNet {
                                grouped[code] = item
                            }
                        } else {
                            grouped[code] = item
                        }
                    }
                    
                    let deduped = Array(grouped.values)
                    
                    // 构造新的 response 回传
                    let newResult = LongHuBangResult(pages: response.result?.pages, count: deduped.count, data: deduped)
                    let newResponse = LongHuBangResponse(success: response.success, message: response.message, result: newResult)
                    DispatchQueue.main.async { completion(.success(newResponse)) }
                } else {
                    DispatchQueue.main.async { completion(.success(response)) }
                }
            case .failure(let error):
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    private func tryFetch(date: String, combinations: [(report: String, filter: String)], index: Int, completion: @escaping (Result<LongHuBangResponse, Error>) -> Void) {
        if index >= combinations.count {
            let err = NSError(domain: "EastMoneyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "所有接口和过滤条件尝试均失败或无数据"])
            completion(.failure(err))
            return
        }
        
        let combo = combinations[index]
        fetchSingle(reportName: combo.report, filter: combo.filter, page: 1, pageSize: 500) { result in
            switch result {
            case .success(let response):
                if let data = response.result?.data, !data.isEmpty {
                    // 成功拿到非空数据，直接返回
                    completion(.success(response))
                } else {
                    // 数据为空，尝试下一种组合
                    self.tryFetch(date: date, combinations: combinations, index: index + 1, completion: completion)
                }
            case .failure(let error):
                // 如果是网络或解析错误，也继续尝试
                self.tryFetch(date: date, combinations: combinations, index: index + 1, completion: completion)
            }
        }
    }

    private func fetchSingle(
        reportName: String,
        filter: String,
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<LongHuBangResponse, Error>) -> Void
    ) {
        let columns = [
            "SECURITY_CODE", "SECUCODE", "SECURITY_NAME_ABBR", "TRADE_DATE", "EXPLAIN",
            "CLOSE_PRICE", "CHANGE_RATE", "BILLBOARD_NET_AMT", "BILLBOARD_BUY_AMT",
            "BILLBOARD_SELL_AMT", "BILLBOARD_DEAL_AMT", "ACCUM_AMOUNT", "DEAL_NET_RATIO",
            "DEAL_AMOUNT_RATIO", "TURNOVERRATE", "FREE_MARKET_CAP", "EXPLANATION",
            "D1_CLOSE_ADJCHRATE", "D2_CLOSE_ADJCHRATE", "D5_CLOSE_ADJCHRATE",
            "D10_CLOSE_ADJCHRATE", "SECURITY_TYPE_CODE"
        ].joined(separator: ",")

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "reportName", value: reportName),
            URLQueryItem(name: "columns", value: columns),
            URLQueryItem(name: "filter", value: filter),
            URLQueryItem(name: "pageNumber", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "sortColumns", value: "SECURITY_CODE,TRADE_DATE"),
            URLQueryItem(name: "sortTypes", value: "1,-1"),
            URLQueryItem(name: "source", value: "WEB"),
            URLQueryItem(name: "client", value: "WEB")
        ]

        guard let url = components.url else {
            let err = NSError(domain: "EastMoneyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL 构建失败"])
            completion(.failure(err))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("https://data.eastmoney.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                let err = NSError(domain: "EastMoneyAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "响应数据为空"])
                completion(.failure(err))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(LongHuBangResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

// MARK: - 响应数据模型

/// 东方财富龙虎榜 API 响应
struct LongHuBangResponse: Decodable {
    let success: Bool
    let message: String?
    let result: LongHuBangResult?
}

struct LongHuBangResult: Decodable {
    let pages: Int?
    let count: Int?
    let data: [LongHuBangRawItem]?
}

/// 单条龙虎榜原始数据（与 API 字段对应）
struct LongHuBangRawItem: Decodable {
    // 股票代码，如 "000004"
    let SECURITY_CODE: String?
    // 含交易所后缀，如 "000004.SZ"
    let SECUCODE: String?
    // 股票简称，如 "*ST国华"
    let SECURITY_NAME_ABBR: String?
    // 交易日期
    let TRADE_DATE: String?
    // 收盘价
    let CLOSE_PRICE: Double?
    // 涨跌幅 (%)
    let CHANGE_RATE: Double?
    // 龙虎榜净买入 (元)
    let BILLBOARD_NET_AMT: Double?
    // 龙虎榜买入 (元)
    let BILLBOARD_BUY_AMT: Double?
    // 龙虎榜卖出 (元)
    let BILLBOARD_SELL_AMT: Double?
    // 龙虎榜成交额 (元)
    let BILLBOARD_DEAL_AMT: Double?
    // 成交总额 (元)
    let ACCUM_AMOUNT: Double?
    // 上榜原因摘要
    let EXPLAIN: String?
    // 上榜原因详细
    let EXPLANATION: String?
    // 换手率
    let TURNOVERRATE: Double?
    // 流通市值
    let FREE_MARKET_CAP: Double?

    /// 从 SECUCODE 提取交易所标识
    var exchangeLabel: String {
        guard let code = SECUCODE else { return "" }
        if code.hasSuffix(".SZ") { return "深" }
        if code.hasSuffix(".SH") { return "沪" }
        if code.hasSuffix(".BJ") { return "北" }
        return ""
    }

    /// 将净买入金额格式化为 "亿" 或 "万" 带单位的字符串
    var formattedNetBuy: String {
        guard let amt = BILLBOARD_NET_AMT else { return "--" }
        let absAmt = abs(amt)
        let sign = amt < 0 ? "-" : ""
        if absAmt >= 100_000_000 {
            // 亿
            return String(format: "%@%.2f亿", sign, absAmt / 100_000_000)
        } else if absAmt >= 10_000 {
            // 万
            return String(format: "%@%.2f万", sign, absAmt / 10_000)
        } else {
            return String(format: "%@%.0f", sign, absAmt)
        }
    }

    /// 涨跌幅格式化字符串
    var formattedChangeRate: String {
        guard let rate = CHANGE_RATE else { return "--" }
        return String(format: "%@%.2f%%", rate >= 0 ? "+" : "", rate)
    }

    /// 收盘价格式化字符串
    var formattedClosePrice: String {
        guard let price = CLOSE_PRICE else { return "--" }
        return String(format: "%.2f", price)
    }

    /// 转换为 UI 使用的 LongHuBangItem
    func toDisplayItem() -> LongHuBangItem {
        return LongHuBangItem(
            name: SECURITY_NAME_ABBR ?? "--",
            code: SECURITY_CODE ?? "--",
            exchange: exchangeLabel,
            close: formattedClosePrice,
            netBuy: formattedNetBuy,
            changePercent: formattedChangeRate,
            netBuyValue: BILLBOARD_NET_AMT ?? 0,
            changeRateValue: CHANGE_RATE ?? 0
        )
    }
}

// MARK: - 热门个股 (股吧人气榜)

extension EastMoneyAPI {
    
    /// 获取东方财富当前最热门（人气最高）的股票列表
    /// - Parameters:
    ///   - count: 获取的数量，默认 6 只
    ///   - completion: 请求回调，返回 (名称, 代码) 元组数组
    func fetchHotSearchStocks(count: Int = 6, completion: @escaping (Result<[(name: String, code: String)], Error>) -> Void) {
        
        // 1. 获取当前人气榜单 (仅含 sc)
        guard let rankUrl = URL(string: "https://emappdata.eastmoney.com/stockrank/getAllCurrentList") else { return }
        var request = URLRequest(url: rankUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://data.eastmoney.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let params = ["appId": "appId01", "globalId": "7324"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataList = json["data"] as? [[String: Any]] else {
                let respStr = String(data: data ?? Data(), encoding: .utf8) ?? "nil"
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "EastMoneyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "人气榜解析失败, response: \(respStr)"])))
                }
                return
            }
            
            let topItems = dataList.prefix(count)
            var secids: [String] = []
            for item in topItems {
                if let sc = item["sc"] as? String {
                    // sc 格式例如 SZ000988, SH600410
                    if sc.hasPrefix("SZ") {
                        secids.append("0.\(sc.dropFirst(2))")
                    } else if sc.hasPrefix("SH") {
                        secids.append("1.\(sc.dropFirst(2))")
                    } else if sc.hasPrefix("BJ") {
                        secids.append("0.\(sc.dropFirst(2))") // 北交所在这里用0.（通常）
                    } else {
                        secids.append("0.\(sc)")
                    }
                }
            }
            
            if secids.isEmpty {
                DispatchQueue.main.async { completion(.success([])) }
                return
            }
            
            // 2. 将 secids 拼接获取股票名称
            self?.fetchStockDetails(secids: secids, completion: completion)
            
        }.resume()
    }
    
    private func fetchStockDetails(secids: [String], completion: @escaping (Result<[(name: String, code: String)], Error>) -> Void) {
        let secidsStr = secids.joined(separator: ",")
        let urlStr = "https://push2.eastmoney.com/api/qt/ulist.np/get?secids=\(secidsStr)&fields=f12,f14"
        guard let url = URL(string: urlStr) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataDict = json["data"] as? [String: Any],
                  let diffList = dataDict["diff"] as? [[String: Any]] else {
                let respStr = String(data: data ?? Data(), encoding: .utf8) ?? "nil"
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "EastMoneyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "详情解析失败, response: \(respStr)"])))
                }
                return
            }
            
            var results: [(name: String, code: String)] = []
            for item in diffList {
                let code = item["f12"] as? String ?? ""
                let name = item["f14"] as? String ?? ""
                if !code.isEmpty && !name.isEmpty {
                    results.append((name: name, code: code))
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(results))
            }
        }.resume()
    }
}
