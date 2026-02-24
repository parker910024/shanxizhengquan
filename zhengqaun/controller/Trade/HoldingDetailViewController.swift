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
    let exchange: String // 交易所标识，如"深"、"沪"
    let shares: String // 持股数
    let purchasePrice: String // 买入价格
    let purchaseValue: String // 买入市值
    let transactionFee: String // 手续费
    let profitLoss: String // 盈亏
    let profitLossPercent: String // 盈亏比例
    let purchaseTime: String // 买入时间
}

class HoldingDetailViewController: ZQViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let closePositionButton = UIButton(type: .system)
    private var detail: HoldingDetail?
    
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
        gk_navTitle = "持仓详情"
        gk_navBackgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // #1976D2
        gk_navTitleColor = .white
        gk_statusBarStyle = .lightContent
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
        
        // 平仓按钮
        closePositionButton.setTitle("平仓", for: .normal)
        closePositionButton.setTitleColor(.white, for: .normal)
        closePositionButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        closePositionButton.backgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // #1976D2
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
        let number = holdingData["number"] as? String ?? "\(holdingData["number"] as? Int ?? 0)"
        let buyPrice = holdingData["buyprice"] as? Double ?? 0
        let citycc = holdingData["citycc"] as? Double ?? (holdingData["citycc"] as? Int).map { Double($0) } ?? 0
        let allMoney = holdingData["allMoney"] as? String ?? "0"
        let profitLose = holdingData["profitLose"] as? String ?? "0"
        let plRate = holdingData["profitLose_rate"] as? String ?? "--"
        let createTime = holdingData["createtime_name"] as? String ?? "--"
        
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
            purchaseValue: String(format: "%.2f", citycc),
            transactionFee: allMoney,
            profitLoss: profitLose,
            profitLossPercent: plRate,
            purchaseTime: createTime
        )
        setupDetailContent()
    }
    
    private func setupDetailContent() {
        guard let detail = detail else { return }
        
        // 清除旧内容
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        var previousView: UIView?
        let items: [(String, String, Bool)] = [
            ("股票", "\(detail.exchange) \(detail.stockCode)", false),
            ("股票名称", detail.stockName, false),
            ("持股数", detail.shares, false),
            ("买入价格", detail.purchasePrice, false),
            ("买入市值", detail.purchaseValue, false),
            ("手续费", detail.transactionFee, false),
            ("盈亏", detail.profitLoss, true), // 红色
            ("盈亏比例", detail.profitLossPercent, true), // 红色
            ("买入时间", detail.purchaseTime, false)
        ]
        
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

