//
//  SecuritiesTransferRecordViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// 银证转账记录数据模型
struct TransferRecord {
    let type: TransferType
    let status: TransferStatus
    let amount: Double
    let timestamp: Date
    
    enum TransferType: String {
        case transferIn = "银证转入"
        case transferOut = "银证转出"
    }
    
    enum TransferStatus: String {
        case success = "处理成功"
        case failed = "处理失败"
        case processing = "处理中"
    }
}

class SecuritiesTransferRecordViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // 标签页
    private let tabContainer = UIView()
    private let transferInTab = UIButton(type: .system)
    private let transferOutTab = UIButton(type: .system)
    private let tabIndicator = UIView()
    private var selectedTab: TransferRecord.TransferType = .transferIn
    private var indicatorCenterXConstraint: NSLayoutConstraint!
    
    // 数据源
    private var transferInRecords: [TransferRecord] = []
    private var transferOutRecords: [TransferRecord] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "银证转账记录"
        gk_navLineHidden = true
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        setupTabs()
        setupTableView()
    }
    
    // MARK: - 标签页
    private func setupTabs() {
        tabContainer.backgroundColor = .white
        view.addSubview(tabContainer)
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 转入标签
        transferInTab.setTitle("银证转入记录", for: .normal)
        transferInTab.setTitleColor(Constants.Color.themeBlue, for: .normal)
        transferInTab.setTitleColor(Constants.Color.textSecondary, for: .selected)
        transferInTab.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        transferInTab.addTarget(self, action: #selector(transferInTabTapped), for: .touchUpInside)
        tabContainer.addSubview(transferInTab)
        transferInTab.translatesAutoresizingMaskIntoConstraints = false
        
        // 转出标签
        transferOutTab.setTitle("银证转出记录", for: .normal)
        transferOutTab.setTitleColor(Constants.Color.textSecondary, for: .normal)
        transferOutTab.setTitleColor(Constants.Color.themeBlue, for: .selected)
        transferOutTab.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        transferOutTab.addTarget(self, action: #selector(transferOutTabTapped), for: .touchUpInside)
        tabContainer.addSubview(transferOutTab)
        transferOutTab.translatesAutoresizingMaskIntoConstraints = false
        
        // 指示器
        tabIndicator.backgroundColor = Constants.Color.themeBlue
        tabContainer.addSubview(tabIndicator)
        tabIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // 分割线
        let separator = UIView()
        separator.backgroundColor = Constants.Color.separator
        tabContainer.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tabContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabContainer.heightAnchor.constraint(equalToConstant: 44),
            
            transferInTab.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            transferInTab.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            transferInTab.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            transferInTab.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.5),
            
            transferOutTab.leadingAnchor.constraint(equalTo: transferInTab.trailingAnchor),
            transferOutTab.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            transferOutTab.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            transferOutTab.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.5),
            
            tabIndicator.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tabIndicator.heightAnchor.constraint(equalToConstant: 2),
            tabIndicator.widthAnchor.constraint(equalToConstant: 20),
            
            separator.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        
        // 指示器居中约束（宽度20，居中显示）
        indicatorCenterXConstraint = tabIndicator.centerXAnchor.constraint(equalTo: transferInTab.centerXAnchor)
        indicatorCenterXConstraint.isActive = true
    }
    
    @objc private func transferInTabTapped() {
        switchToTab(.transferIn)
    }
    
    @objc private func transferOutTabTapped() {
        switchToTab(.transferOut)
    }
    
    private func switchToTab(_ tab: TransferRecord.TransferType) {
        selectedTab = tab
        
        // 更新指示器位置
        indicatorCenterXConstraint.isActive = false
        if tab == .transferIn {
            indicatorCenterXConstraint = tabIndicator.centerXAnchor.constraint(equalTo: transferInTab.centerXAnchor)
            transferInTab.setTitleColor(Constants.Color.themeBlue, for: .normal)
            transferOutTab.setTitleColor(Constants.Color.textSecondary, for: .normal)
        } else {
            indicatorCenterXConstraint = tabIndicator.centerXAnchor.constraint(equalTo: transferOutTab.centerXAnchor)
            transferInTab.setTitleColor(Constants.Color.textSecondary, for: .normal)
            transferOutTab.setTitleColor(Constants.Color.themeBlue, for: .normal)
        }
        indicatorCenterXConstraint.isActive = true
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        
        tableView.reloadData()
    }
    
    // MARK: - TableView
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(TransferRecordCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Data
    private func loadData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 模拟转入记录
        transferInRecords = [
            TransferRecord(
                type: .transferIn,
                status: .failed,
                amount: 1000.00,
                timestamp: formatter.date(from: "2025-12-10 10:14:07") ?? Date()
            ),
            TransferRecord(
                type: .transferIn,
                status: .failed,
                amount: 1000.00,
                timestamp: formatter.date(from: "2025-12-10 10:14:07") ?? Date()
            ),
            TransferRecord(
                type: .transferIn,
                status: .failed,
                amount: 1000.00,
                timestamp: formatter.date(from: "2025-12-10 10:14:07") ?? Date()
            ),
            TransferRecord(
                type: .transferIn,
                status: .failed,
                amount: 1000.00,
                timestamp: formatter.date(from: "2025-12-10 10:14:07") ?? Date()
            ),
            TransferRecord(
                type: .transferIn,
                status: .failed,
                amount: 1000.00,
                timestamp: formatter.date(from: "2025-12-10 10:14:07") ?? Date()
            )
        ]
        
        // 模拟转出记录（与转入记录样式相同）
        transferOutRecords = [
            TransferRecord(
                type: .transferOut,
                status: .success,
                amount: 500.00,
                timestamp: formatter.date(from: "2025-12-09 14:30:15") ?? Date()
            ),
            TransferRecord(
                type: .transferOut,
                status: .success,
                amount: 1000.00,
                timestamp: formatter.date(from: "2025-12-08 09:20:33") ?? Date()
            ),
            TransferRecord(
                type: .transferOut,
                status: .failed,
                amount: 2000.00,
                timestamp: formatter.date(from: "2025-12-07 16:45:22") ?? Date()
            ),
            TransferRecord(
                type: .transferOut,
                status: .processing,
                amount: 1500.00,
                timestamp: formatter.date(from: "2025-12-06 11:15:08") ?? Date()
            )
        ]
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SecuritiesTransferRecordViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedTab == .transferIn ? transferInRecords.count : transferOutRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TransferRecordCell
        let records = selectedTab == .transferIn ? transferInRecords : transferOutRecords
        cell.configure(with: records[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - TransferRecordCell
class TransferRecordCell: UITableViewCell {
    
    private let typeLabel = UILabel()
    private let statusLabel = UILabel()
    private let amountLabel = UILabel()
    private let timeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        
        // 交易类型
        typeLabel.font = UIFont.systemFont(ofSize: 15)
        typeLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(typeLabel)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 状态
        statusLabel.font = UIFont.systemFont(ofSize: 13)
        statusLabel.textColor = Constants.Color.stockRise // 红色
        contentView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 金额（右对齐）
        amountLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 时间（右对齐）
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = Constants.Color.textTertiary
        timeLabel.textAlignment = .right
        contentView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 分割线
        let separator = UIView()
        separator.backgroundColor = Constants.Color.separator
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 左侧：交易类型和状态
            typeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            statusLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // 右侧：金额和时间
            amountLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: typeLabel.trailingAnchor, constant: 16),
            
            timeLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 6),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: statusLabel.trailingAnchor, constant: 16),
            
            // 分割线
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }
    
    func configure(with record: TransferRecord) {
        typeLabel.text = record.type.rawValue
        statusLabel.text = record.status.rawValue
        
        // 金额格式：转入显示+，转出显示-
        let sign = record.type == .transferIn ? "+" : "-"
        amountLabel.text = "\(sign)\(String(format: "%.2f", record.amount))"
        
        // 状态颜色：失败显示红色，成功显示绿色
        if record.status == .failed {
            statusLabel.textColor = Constants.Color.stockRise // 红色
            amountLabel.textColor = Constants.Color.stockRise // 红色
        } else if record.status == .success {
            statusLabel.textColor = Constants.Color.stockFall // 绿色
            amountLabel.textColor = Constants.Color.stockFall // 绿色
        } else {
            statusLabel.textColor = Constants.Color.textSecondary // 灰色
            amountLabel.textColor = Constants.Color.textPrimary // 黑色
        }
        
        // 时间格式
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        timeLabel.text = formatter.string(from: record.timestamp)
    }
}

