//
//  HoldingDetailViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// 持仓详情数据模型
struct HoldingDetail {
    let stockCode: String
    let stockName: String
    let exchange: String
    let shares: String
    let purchasePrice: String
    let purchaseValue: String
    var transactionFee: String
    let profitLoss: String
    let plRate: String // 盈亏比例
    let purchaseTime: String // 买入时间
    // 历史特有字段
    var sellPrice: String? = nil
    var stampDuty: String? = nil
    var sellTime: String? = nil
}

class HoldingDetailViewController: ZQViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let closePositionButton = UIButton(type: .system)
    private var detail: HoldingDetail?
    
    var isHistorical: Bool = false
    var hiddingButton: Bool = false
    var fromBulkTrade: Bool = false
    
    /// 调用方传入的持仓原始数据（来自 API 返回）
    var holdingData: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navTitle = isHistorical ? "历史持仓详情" : "持仓详情"
        gk_navBackgroundColor = isHistorical ? UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) : .white
        gk_navTitleColor = isHistorical ? .white : Constants.Color.textPrimary
        gk_statusBarStyle = isHistorical ? .lightContent : .default
        gk_navTintColor = isHistorical ? .white : Constants.Color.textPrimary
        gk_backStyle = isHistorical ? .white : .black
    }
    
    private func setupUI() {
        view.backgroundColor = Constants.Color.backgroundMain
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.backgroundColor = .white
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 按钮处理
        let btnTitle = isHistorical ? "返回" : "平仓"
        let btnColor = isHistorical ? UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) : UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        
        closePositionButton.setTitle(btnTitle, for: .normal)
        closePositionButton.setTitleColor(.white, for: .normal)
        closePositionButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        closePositionButton.backgroundColor = btnColor
        closePositionButton.layer.cornerRadius = 8
        closePositionButton.addTarget(self, action: #selector(closePositionTapped), for: .touchUpInside)
        closePositionButton.isHidden = hiddingButton
        view.addSubview(closePositionButton)
        closePositionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight+10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: closePositionButton.topAnchor, constant: -16),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            closePositionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closePositionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closePositionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            closePositionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func loadData() {
        guard !holdingData.isEmpty else {
            // 没有传入数据，显示空状态
            return
        }
        
        let code = holdingData["code"] as? String ?? "--"
        let title = holdingData["title"] as? String ?? "--"
        let allcode = holdingData["allcode"] as? String ?? ""
        // 兼容 String/Int 类型
        let number = "\(holdingData["number"] ?? "0")"
        let number_val = Double(number) ?? 0
        let buyPrice = holdingData["buyprice"] as? Double ?? Double("\(holdingData["buyprice"] ?? 0)") ?? 0
        
        // 修复买入市值
        var citycc = holdingData["citycc"] as? Double ?? Double("\(holdingData["citycc"] ?? 0)") ?? 0
        if isHistorical && citycc == 0 {
            citycc = buyPrice * number_val
        }
        // 金额字段：对齐安卓 HoldingItem.money
        let moneyVal = Double("\(holdingData["money"] ?? "0")") ?? 0
        // 历史记录用 money（金额）显示，当前持仓用 citycc（市值）
        let displayValue = isHistorical ? (moneyVal > 0 ? moneyVal : citycc) : citycc
        
        
        // 手续费：兼容 String/Double/Int/NSNumber，统一两位小数
        let allMoneyRaw = holdingData["allMoney"] ?? holdingData["allmoney"] ?? holdingData["fee"] ?? holdingData["sell_fee"]
        var allMoneyVal: Double
        if let d = allMoneyRaw as? Double { allMoneyVal = d }
        else if let n = allMoneyRaw as? NSNumber { allMoneyVal = n.doubleValue }
        else if let s = allMoneyRaw as? String, let d = Double(s.trimmingCharacters(in: .whitespacesAndNewlines)) { allMoneyVal = d }
        else { allMoneyVal = 0 }
        
        // 对齐安卓 BuyActivity：如果 allMoney 为 0 且是历史持仓，使用 maic_fee(卖出费率) × 卖出价 × 股数 计算平仓手续费
        if allMoneyVal == 0 && isHistorical {
            let sellPriceRaw = holdingData["cai_buy"]
            let sellPrice: Double
            if let d = sellPriceRaw as? Double { sellPrice = d }
            else if let n = sellPriceRaw as? NSNumber { sellPrice = n.doubleValue }
            else if let s = sellPriceRaw as? String, let d = Double(s) { sellPrice = d }
            else { sellPrice = 0 }
            
            if sellPrice > 0 && number_val > 0 {
                // 默认卖出费率 0.0001，与安卓 BuyActivity.DEFAULT_FEE_RATE 一致
                let defaultSellFeeRate = 0.0001
                let amount = sellPrice * number_val
                allMoneyVal = amount * defaultSellFeeRate
                
                // 尝试从配置接口获取实际费率（异步更新）
                loadSellFeeRate { [weak self] feeRate in
                    guard let self = self, let detail = self.detail else { return }
                    let recalculated = amount * feeRate
                    self.detail?.transactionFee = String(format: "%.2f", recalculated)
                    self.setupDetailContent()
                }
            }
        }
        let allMoney = String(format: "%.2f", allMoneyVal)
        
        // 盈亏：兼容 Double/String/Int/NSNumber，统一两位小数
        let plVal: Double
        if let d = holdingData["profitLose"] as? Double { plVal = d }
        else if let n = holdingData["profitLose"] as? NSNumber { plVal = n.doubleValue }
        else if let s = holdingData["profitLose"] as? String, let d = Double(s) { plVal = d }
        else { plVal = 0 }
        let profitLose = String(format: "%.2f", plVal)
        let plRate = "\(holdingData["profitLose_rate"] ?? "--")"
        let createTime = "\(holdingData["createtime_name"] ?? "--")"
        
        // 推导交易所
        let typeVal = holdingData["type"] as? Int ?? 0
        let exchangeStr: String
        switch typeVal {
        case 1: exchangeStr = "沪"
        case 2: exchangeStr = "深"
        case 3: exchangeStr = "创"
        case 4: exchangeStr = "京"
        case 5: exchangeStr = "科"
        default:
            if allcode.lowercased().hasPrefix("sh") {
                if allcode.hasPrefix("sh688") { exchangeStr = "科" } else { exchangeStr = "沪" }
            } else if allcode.lowercased().hasPrefix("bj") {
                exchangeStr = "京"
            } else if allcode.lowercased().hasPrefix("sz") {
                if allcode.hasPrefix("sz30") { exchangeStr = "创" } else { exchangeStr = "深" }
            } else {
                if code.hasPrefix("688") { exchangeStr = "科" }
                else if code.hasPrefix("30") { exchangeStr = "创" }
                else if code.hasPrefix("8") || code.hasPrefix("4") { exchangeStr = "京" }
                else if code.hasPrefix("6") { exchangeStr = "沪" }
                else { exchangeStr = "深" }
            }
        }
        
        detail = HoldingDetail(
            stockCode: code,
            stockName: title,
            exchange: exchangeStr,
            shares: number,
            purchasePrice: String(format: "%.2f", buyPrice),
            purchaseValue: String(format: "%.2f", displayValue),
            transactionFee: allMoney,
            profitLoss: profitLose,
            plRate: plRate,
            purchaseTime: createTime
        )
        
        if isHistorical {
            // 对齐安卓：卖出价使用 cai_buy 字段
            let sellPriceVal: Double
            if let d = holdingData["cai_buy"] as? Double { sellPriceVal = d }
            else if let n = holdingData["cai_buy"] as? NSNumber { sellPriceVal = n.doubleValue }
            else if let s = holdingData["cai_buy"] as? String, let d = Double(s) { sellPriceVal = d }
            else { sellPriceVal = 0 }
            detail?.sellPrice = String(format: "%.2f", sellPriceVal)
            // 对齐安卓：印花税使用 yhfee 字段，兼容多种类型
            let yhfeeVal: Double
            if let d = holdingData["yhfee"] as? Double { yhfeeVal = d }
            else if let n = holdingData["yhfee"] as? NSNumber { yhfeeVal = n.doubleValue }
            else if let s = holdingData["yhfee"] as? String, let d = Double(s) { yhfeeVal = d }
            else { yhfeeVal = 0 }
            detail?.stampDuty = String(format: "%.2f", yhfeeVal)
            detail?.sellTime = "\(holdingData["outtime_name"] ?? "--")"
        }
        setupDetailContent()
    }
    
    private func setupDetailContent() {
        guard let detail = detail else { return }
        
        // 清除旧内容
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        var previousView: UIView?
        // 判断盈亏正负，用于颜色标记
        let plValue = Double(detail.profitLoss) ?? 0
        let isProfit = plValue >= 0
        
        let plRateVal = holdingData["profitLose_rate"] as? String ?? ""
        let plRateStr = plRateVal.isEmpty ? "--" : plRateVal
        
        var items: [(String, String, UIColor?)] = []
        let profitColor = isProfit ? Constants.Color.stockRise : Constants.Color.stockFall
        
        if isHistorical {
            let numberVal = Double("\(holdingData["number"] ?? "0")") ?? 0
            var lotsStr = String(format: "%.2f", numberVal / 100.0)
            if lotsStr.hasSuffix(".00") { lotsStr = String(lotsStr.dropLast(3)) }
            
            let buyPriceVal = holdingData["buyprice"] as? Double ?? Double("\(holdingData["buyprice"] ?? 0)") ?? 0
            let buyMarketValueStr = String(format: "%.2f", buyPriceVal * numberVal)
            
            let moneyVal = Double("\(holdingData["money"] ?? "0")") ?? 0
            let moneyStr = moneyVal > 0 ? String(format: "%.2f", moneyVal) : buyMarketValueStr
            
            let cjlxRaw = holdingData["cjlx"] as? String ?? ""
            let cjlxStr = cjlxRaw.isEmpty ? "平仓" : cjlxRaw
            
            items = [
                ("股票", "\(detail.exchange) \(detail.stockCode)", nil),
                ("买入数量(股)", detail.shares, nil),
                ("买入手数", lotsStr, nil),
                ("买入价格", detail.purchasePrice, nil),
                ("买入市值", buyMarketValueStr, nil),
                ("本金", moneyStr, nil),
                ("买入手续费", "0", nil),
                ("盈亏", detail.profitLoss, profitColor),
                ("平仓手续费", detail.transactionFee, nil),
                ("买入时间", detail.purchaseTime, nil),
                ("卖出类型", cjlxStr, nil),
                ("卖出价格", detail.sellPrice ?? "0.00", nil),
                ("印花税", detail.stampDuty ?? "0.00", nil),
                ("卖出时间", detail.sellTime ?? "--", nil)
            ]
        } else {
            items = [
                ("股票代码", "\(detail.exchange) \(detail.stockCode)", nil),
                ("股票名称", detail.stockName, nil),
                ("持股数", detail.shares, nil),
                ("买入价格", detail.purchasePrice, nil),
                ("买入市值", detail.purchaseValue, nil),
                ("手续费", detail.transactionFee, nil),
                ("盈亏", detail.profitLoss, profitColor),
                ("盈亏比例", plRateStr, profitColor),
                ("买入时间", detail.purchaseTime, nil)
            ]
        }
        
        for (index, item) in items.enumerated() {
            let row = createDetailRow(title: item.0, value: item.1, valueColor: item.2, isFirst: index == 0)
            contentView.addSubview(row)
            row.translatesAutoresizingMaskIntoConstraints = false
            
            if let prev = previousView {
                NSLayoutConstraint.activate([
                    row.topAnchor.constraint(equalTo: prev.bottomAnchor),
                    row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    row.heightAnchor.constraint(equalToConstant: 56)
                ])
            } else {
                NSLayoutConstraint.activate([
                    row.topAnchor.constraint(equalTo: contentView.topAnchor),
                    row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    row.heightAnchor.constraint(equalToConstant: 56)
                ])
            }
            
            previousView = row
        }
        
        // 最后一个view约束到底部
        if let last = previousView {
            NSLayoutConstraint.activate([
                last.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
            ])
        }
    }
    
    private func createDetailRow(title: String, value: String, valueColor: UIColor?, isFirst: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        
        // 左侧标题，只保留固定文案，例如“股票”
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = Constants.Color.textPrimary
        titleLabel.numberOfLines = 1
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 如果是"股票代码"行，特殊处理：带红色边框的角标 + 黑色代码文本
        if title == "股票代码" || title == "代码" || title == "股票" {
            let exchangeView = UIView()
            exchangeView.backgroundColor = .clear // 透明背景
            exchangeView.layer.cornerRadius = 2
            exchangeView.layer.borderWidth = 0.5
            exchangeView.layer.borderColor = Constants.Color.stockRise.cgColor // 红色边框
            container.addSubview(exchangeView)
            exchangeView.translatesAutoresizingMaskIntoConstraints = false
            
            let exchangeLabel = UILabel()
            exchangeLabel.text = value.components(separatedBy: " ").first ?? ""
            exchangeLabel.font = UIFont.systemFont(ofSize: 10)
            exchangeLabel.textColor = Constants.Color.stockRise // 红色字体
            exchangeLabel.textAlignment = .center
            exchangeView.addSubview(exchangeLabel)
            exchangeLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let codeLabel = UILabel()
            codeLabel.text = value.components(separatedBy: " ").last ?? ""
            codeLabel.font = UIFont.systemFont(ofSize: 15)
            codeLabel.textColor = Constants.Color.textPrimary
            container.addSubview(codeLabel)
            codeLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                
                exchangeView.trailingAnchor.constraint(equalTo: codeLabel.leadingAnchor, constant: -4),
                exchangeView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                exchangeView.widthAnchor.constraint(equalToConstant: 16),
                exchangeView.heightAnchor.constraint(equalToConstant: 16),
                
                exchangeLabel.centerXAnchor.constraint(equalTo: exchangeView.centerXAnchor),
                exchangeLabel.centerYAnchor.constraint(equalTo: exchangeView.centerYAnchor),
                
                codeLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                codeLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        } else {
            // 通用行：标题 + 右侧数值
            let valueLabel = UILabel()
            valueLabel.text = value
            valueLabel.font = UIFont.systemFont(ofSize: 15)
            valueLabel.textColor = valueColor ?? Constants.Color.textPrimary
            valueLabel.textAlignment = .right
            container.addSubview(valueLabel)
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                
                valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
            ])
        }
        
        // 分隔线（除了第一行）
        if !isFirst {
            let separator = UIView()
            separator.backgroundColor = Constants.Color.separator
            container.addSubview(separator)
            separator.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                separator.topAnchor.constraint(equalTo: container.topAnchor),
                separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
            ])
        }
        
        return container
    }
    
    @objc private func closePositionTapped() {
        if isHistorical {
            navigationController?.popViewController(animated: true)
            return
        }
        guard let detail = detail else { return }
        
        if fromBulkTrade {
            showConfirmCloseDialog(for: detail)
        } else {
            verifySellAndNavigate(for: detail)
        }
    }
    
    // MARK: - 普通持仓卖出校验并跳转
    private func verifySellAndNavigate(for detail: HoldingDetail) {
        Task {
            do {
                let result = try await SecureNetworkManager.shared.request(api: "/api/deal/mrSellLst", method: .get, params: ["keyword": detail.stockCode])
                guard let dict = result.decrypted,
                      let data = dict["data"] as? [[String: Any]],
                      let holding = data.first else {
                    DispatchQueue.main.async { Toast.show("获取信息失败") }
                    return
                }
                
                guard let id = holding["id"] as? Int else {
                    DispatchQueue.main.async { Toast.show("数据异常，无法获取ID") }
                    return
                }
                
                // 从 mrSellLst 中提取可卖数量
                var canBuy = 0
                if let str = holding["canBuy"] as? String, let val = Int(str) {
                    canBuy = val
                } else if let val = holding["canBuy"] as? Int {
                    canBuy = val
                }
                
                if canBuy <= 0 {
                    DispatchQueue.main.async { Toast.show("当前无可用份额") }
                    return
                }
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "确认全仓卖出？", message: "当前可卖 \(canBuy) 手", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak self] _ in
                        self?.submitNormalClosePosition(id: id, canBuy: canBuy)
                    }))
                    self.present(alert, animated: true)
                }
            } catch {
                DispatchQueue.main.async { Toast.show("校验失败: \(error.localizedDescription)") }
            }
        }
    }
    
    private func submitNormalClosePosition(id: Int, canBuy: Int) {
        closePositionButton.isEnabled = false
        SecureNetworkManager.shared.request(
            api: "/api/deal/sell",
            method: .post,
            params: [
                "id": id,
                "canBuy": canBuy
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.closePositionButton.isEnabled = true
                switch result {
                case .success(let res):
                    if let dict = res.decrypted, let retCode = dict["code"] as? Int, retCode == 1 {
                        let alert = UIAlertController(title: "卖出委托已提交", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
                            self?.navigationController?.popViewController(animated: true)
                        }))
                        self?.present(alert, animated: true)
                    } else {
                        let msg = res.decrypted?["msg"] as? String ?? "提交失败"
                        Toast.show(msg)
                    }
                case .failure(let error):
                    Toast.show("卖出失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 撮合交易持仓平仓验证及弹窗 (跳过 T+N 拦截)
    private func showConfirmCloseDialog(for detail: HoldingDetail) {
        self.presentConfirmCloseAlert(detail: detail)
    }
    
    private func presentConfirmCloseAlert(detail: HoldingDetail) {
        let price = Double(detail.purchasePrice) ?? 0
        let shares = Int(detail.shares) ?? 0
        let total = price * Double(shares)
        
        let msg = String(format: "股票名称：%@\n买入价格：%.2f\n数量：%d股\n总计：%.2f",
                         detail.stockName.isEmpty ? detail.stockCode : detail.stockName, price, shares, total)
        
        let alert = UIAlertController(title: "确认平仓吗?", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak self] _ in
            self?.submitClosePosition(detail: detail, price: price, shares: shares)
        }))
        self.present(alert, animated: true)
    }
    
    private func submitClosePosition(detail: HoldingDetail, price: Double, shares: Int) {
        let lots = max(0, shares / 100)
        if lots <= 0 {
            Toast.show("股数无效")
            return
        }
        
        let idRaw = holdingData["id"]
        let idInt = Int("\(idRaw ?? "0")") ?? 0
        let allcode = holdingData["allcode"] as? String ?? ""
        
        closePositionButton.isEnabled = false
        SecureNetworkManager.shared.request(
            api: "/api/deal/sell",
            method: .post,
            params: [
                "id": idInt,
                "allcode": allcode,
                "canBuy": lots,
                "sellprice": price
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.closePositionButton.isEnabled = true
                switch result {
                case .success(let res):
                    if let dict = res.decrypted, let retCode = dict["code"] as? Int, retCode == 1 {
                        let alert = UIAlertController(title: "平仓成功", message: "平仓成功", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
                            self?.navigationController?.popViewController(animated: true)
                        }))
                        self?.present(alert, animated: true)
                    } else {
                        let msg = res.decrypted?["msg"] as? String ?? "平仓失败，请重试"
                        Toast.show(msg)
                    }
                case .failure(let err):
                    Toast.show("平仓失败: \(err.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 获取卖出费率
    /// 从配置接口 /api/stock/getconfig 获取 maic_fee（卖出手续费率）
    /// 对齐安卓 BuyActivity.loadConfig() 获取 maic_fee 的逻辑
    private func loadSellFeeRate(completion: @escaping (Double) -> Void) {
        SecureNetworkManager.shared.request(
            api: "/api/stock/getconfig",
            method: .get,
            params: [:]
        ) { result in
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any] else {
                    return
                }
                // 对齐安卓：maic_fee 为卖出手续费率，默认 0.0001
                let maicFeeStr = "\(data["maic_fee"] ?? "0.0001")"
                let feeRate = Double(maicFeeStr) ?? 0.0001
                if feeRate > 0 {
                    completion(feeRate)
                }
            case .failure(_):
                break
            }
        }
    }
}

