//
//  HistoricalHoldingDetailViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// 历史持仓详情数据模型
struct HistoricalHoldingDetail {
    let stockCode: String
    let buyLots: Int
    let buyQuantity: Int
    let closingFee: Double
    let stampDuty: Double
    let buyTime: Date
    let sellType: String?
    let sellPrice: Double?
    let profit: Double?
    let sellTime: Date?
}

class HistoricalHoldingDetailViewController: ZQViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 详情列表容器
    private let detailContainer = UIView()
    
    // 返回按钮
    private let returnButton = UIButton(type: .system)
    
    // 数据
    var holdingDetail: HistoricalHoldingDetail?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "历史持仓详情"
        gk_navLineHidden = false
        gk_backStyle = .black
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 先设置返回按钮，确保在视图层级中
        setupReturnButton()
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: returnButton.topAnchor, constant: -20),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupDetailList()
    }
    
    // MARK: - 详情列表
    private func setupDetailList() {
        detailContainer.backgroundColor = .white
        contentView.addSubview(detailContainer)
        detailContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            detailContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            detailContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            detailContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            detailContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func createDetailRow(label: String, value: String, valueColor: UIColor = Constants.Color.textPrimary) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 15)
        labelView.textColor = Constants.Color.textSecondary
        container.addSubview(labelView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        let valueView = UILabel()
        valueView.text = value
        valueView.font = UIFont.systemFont(ofSize: 15)
        valueView.textColor = valueColor
        valueView.textAlignment = .right
        container.addSubview(valueView)
        valueView.translatesAutoresizingMaskIntoConstraints = false
        
        let separator = UIView()
        separator.backgroundColor = Constants.Color.separator
        container.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            valueView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueView.leadingAnchor.constraint(greaterThanOrEqualTo: labelView.trailingAnchor, constant: 16),
            
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        
        return container
    }
    
    // MARK: - 返回按钮
    private func setupReturnButton() {
        returnButton.setTitle("返回", for: .normal)
        returnButton.setTitleColor(.white, for: .normal)
        returnButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        returnButton.backgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        returnButton.layer.cornerRadius = 8
        returnButton.addTarget(self, action: #selector(returnButtonTapped), for: .touchUpInside)
        view.addSubview(returnButton)
        returnButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            returnButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            returnButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            returnButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            returnButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Data
    private func loadData() {
        guard let detail = holdingDetail else {
            // 如果没有数据，使用模拟数据
            loadMockData()
            return
        }
        
        displayDetail(detail)
    }
    
    private func loadMockData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let mockDetail = HistoricalHoldingDetail(
            stockCode: "688108",
            buyLots: 1,
            buyQuantity: 100,
            closingFee: 1.23,
            stampDuty: 1.23,
            buyTime: formatter.date(from: "2026-01-02 12:23:23") ?? Date(),
            sellType: "平仓",
            sellPrice: 22.4,
            profit: -19.0,
            sellTime: formatter.date(from: "2026-01-02 12:23:23") ?? Date()
        )
        
        displayDetail(mockDetail)
    }
    
    private func displayDetail(_ detail: HistoricalHoldingDetail) {
        // 清除之前的子视图
        detailContainer.subviews.forEach { $0.removeFromSuperview() }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 创建所有行
        let stockRow = createDetailRow(label: "股票", value: "沪 \(detail.stockCode)")
        let buyLotsRow = createDetailRow(label: "买入手数", value: "\(detail.buyLots)")
        let buyQuantityRow = createDetailRow(label: "买入数量(股)", value: "\(detail.buyQuantity)")
        let closingFeeRow = createDetailRow(label: "平仓手续费", value: String(format: "%.2f", detail.closingFee))
        let stampDutyRow = createDetailRow(label: "印花税", value: String(format: "%.2f", detail.stampDuty))
        let buyTimeRow = createDetailRow(label: "买入时间", value: formatter.string(from: detail.buyTime))
        
        var rows: [UIView] = [stockRow, buyLotsRow, buyQuantityRow, closingFeeRow, stampDutyRow, buyTimeRow]
        
        // 卖出类型
        if let sellType = detail.sellType {
            let sellTypeRow = createDetailRow(label: "卖出类型", value: sellType)
            rows.append(sellTypeRow)
        }
        
        // 卖出价格
        if let sellPrice = detail.sellPrice {
            let sellPriceRow = createDetailRow(label: "卖出价格", value: String(format: "%.2f", sellPrice))
            rows.append(sellPriceRow)
        }
        
        // 盈亏（绿色显示亏损）
        if let profit = detail.profit {
            let profitRow = createDetailRow(
                label: "盈亏",
                value: String(format: "%.0f", profit),
                valueColor: Constants.Color.stockFall // 绿色表示亏损
            )
            rows.append(profitRow)
        }
        
        // 卖出时间
        if let sellTime = detail.sellTime {
            let sellTimeRow = createDetailRow(label: "卖出时间", value: formatter.string(from: sellTime))
            rows.append(sellTimeRow)
        }
        
        // 添加所有行到容器
        rows.forEach { row in
            detailContainer.addSubview(row)
            row.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // 设置约束
        for (index, row) in rows.enumerated() {
            if index == 0 {
                NSLayoutConstraint.activate([
                    row.topAnchor.constraint(equalTo: detailContainer.topAnchor),
                    row.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor),
                    row.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    row.topAnchor.constraint(equalTo: rows[index - 1].bottomAnchor),
                    row.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor),
                    row.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor)
                ])
            }
            
            // 最后一个行的底部约束
            if index == rows.count - 1 {
                NSLayoutConstraint.activate([
                    row.bottomAnchor.constraint(equalTo: detailContainer.bottomAnchor)
                ])
            }
        }
    }
    
    // MARK: - Actions
    @objc private func returnButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

