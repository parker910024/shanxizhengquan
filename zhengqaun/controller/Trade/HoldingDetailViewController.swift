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
    let transactionFee: String
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
        let btnColor = isHistorical ? UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) : UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
        
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
        
        // 手续费：兼容 String/Double/Int
        let allMoney = "\(holdingData["allMoney"] ?? "0")"
        
        // 盈亏：支持 Double 和 String 两种返回格式
        let profitLose: String
        if let plDouble = holdingData["profitLose"] as? Double {
            profitLose = String(format: "%.2f", plDouble)
        } else {
            profitLose = "\(holdingData["profitLose"] ?? "0")"
        }
        let plRate = "\(holdingData["profitLose_rate"] ?? "--")"
        let createTime = "\(holdingData["createtime_name"] ?? "--")"
        
        // 推导交易所
        let typeVal = holdingData["type"] as? Int ?? 0
        let exchangeStr: String
        switch typeVal {
        case 1, 5: exchangeStr = "沪"
        case 2, 3: exchangeStr = "深"
        case 4:    exchangeStr = "京"
        default:
            if allcode.lowercased().hasPrefix("sh") { exchangeStr = "沪" }
            else if allcode.lowercased().hasPrefix("bj") { exchangeStr = "京" }
            else { exchangeStr = "深" }
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
            let sellPrice = Double("\(holdingData["cai_buy"] ?? 0)") ?? 0
            detail?.sellPrice = String(format: "%.2f", sellPrice)
            // 对齐安卓：印花税使用 yhfee 字段，兼容 String/Double
            detail?.stampDuty = "\(holdingData["yhfee"] ?? "0.00")"
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
        
        // 对齐安卓截图字段顺序：股票代码→股票名称→持股数→买入价格→买入市值→手续费→盈亏→买入时间→(历史)卖出价格→印花税→卖出时间
        var items: [(String, String, Bool)] = [
            ("股票代码", "\(detail.exchange) \(detail.stockCode)", false),
            ("股票名称", detail.stockName, false),
            ("持股数", detail.shares, false),
            ("买入价格", detail.purchasePrice, false),
            ("买入市值", detail.purchaseValue, false),
            ("手续费", detail.transactionFee, false),
            ("盈亏", detail.profitLoss, true),
            ("买入时间", detail.purchaseTime, false),
        ]
        
        if isHistorical {
            if let sp = detail.sellPrice { items.append(("卖出价格", sp, false)) }
            if let sd = detail.stampDuty { items.append(("印花税", sd, false)) }
            if let st = detail.sellTime { items.append(("卖出时间", st, false)) }
        }
        
        for (index, item) in items.enumerated() {
            let row = createDetailRow(title: item.0, value: item.1, isRed: item.2, isFirst: index == 0)
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
    
    private func createDetailRow(title: String, value: String, isRed: Bool, isFirst: Bool) -> UIView {
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
        
        // 如果是"股票"行，特殊处理：只显示左侧“股票”+ 右侧交易所标识和代码
        if title == "股票" {
            // 右侧不再使用通用的 valueLabel，避免出现多余的一行
            let exchangeView = UIView()
            exchangeView.backgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // 蓝色
            exchangeView.layer.cornerRadius = 4
            container.addSubview(exchangeView)
            exchangeView.translatesAutoresizingMaskIntoConstraints = false
            
            let exchangeLabel = UILabel()
            exchangeLabel.text = value.components(separatedBy: " ").first ?? ""
            exchangeLabel.font = UIFont.systemFont(ofSize: 12)
            exchangeLabel.textColor = .white
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
                
                exchangeView.trailingAnchor.constraint(equalTo: codeLabel.leadingAnchor, constant: -8),
                exchangeView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                exchangeView.widthAnchor.constraint(equalToConstant: 30),
                exchangeView.heightAnchor.constraint(equalToConstant: 20),
                
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
            valueLabel.textColor = isRed ? Constants.Color.stockRise : Constants.Color.textPrimary
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
        Task {
            do {
                let result = try await SecureNetworkManager.shared.request(api: "/api/deal/mrSellLst", method: .get, params: ["keyword": detail.stockCode])
                guard let dict = result.decrypted,
                      let data = dict["data"] as? [[String: Any]],
                      let holding = data.first else { return }
                guard let id = holding["id"] else {
                    Toast.show("获取信息失败")
                    return
                }
                
                guard let canBuy = Int(detail.shares) else {
                    Toast.show("持股数错误")
                    return
                }
                
                let res = try await SecureNetworkManager.shared.request(api: "/api/deal/sell", method: .post, params: [
                    "id": id,
                    "canBuy": canBuy
                ])
                if let dict = res.decrypted, let retCode = dict["code"] as? Int, retCode == 1 {
                    Toast.show("卖出委托已提交")
                    self.navigationController?.popViewController(animated: true)
                } else {
                    let msg = res.decrypted?["msg"] as? String ?? "提交失败"
                    Toast.show(msg)
                }
                
            } catch {
                debugPrint(error.localizedDescription)
                Toast.show("卖出失败: \(error.localizedDescription)")
            }
        }
    }
}

