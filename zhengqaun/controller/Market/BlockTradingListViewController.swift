//
//  BlockTradingListViewController.swift
//  zhengqaun
//
//  大宗交易列表：入口为个人中心的"大宗交易"按钮
//

import UIKit

/// 大宗交易列表数据模型
struct BlockTradingListItem {
    let stockName: String      // 股票名称，如"健信超导"
    let exchange: String       // 交易所类型，如"深"、"沪"
    let stockCode: String       // 股票代码，如"688805"
    let principal: String      // 本金/数量，如"4824"
    let buyPrice: String       // 买入价，如"18.58"
    let currentPrice: String?  // 当前价（当前持仓时）或卖出价（历史持仓时），如"18.58"
    let profit: String         // 收益，如"2966.00"
    let profitRate: String     // 收益率，如"159.63%"
    let updateTime: String     // 更新时间，如"2026-01-26 20:09:09"
    let quantity: String       // 数量
    let rawData: [String: Any]  // 原始 API 数据，用于跳转详情
}

class BlockTradingListViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero)
    private let tabContainer = UIView()
    private let currentTabButton = UIButton(type: .system)
    private let historyTabButton = UIButton(type: .system)
    private let tabIndicator = UIView()
    private var selectedTab: TabType = .current
    // 指示器宽度固定 20，下方通过两个 centerX 约束在两个 tab 之间切换
    private var tabIndicatorCenterXCurrentConstraint: NSLayoutConstraint!
    private var tabIndicatorCenterXHistoryConstraint: NSLayoutConstraint!
    
    enum TabType {
        case current   // 当前持仓
        case history   // 历史持仓
    }
    
    // 数据源
    private var currentHoldings: [BlockTradingListItem] = []
    private var historyHoldings: [BlockTradingListItem] = []
    private let emptyLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTabs()
        setupTableView()
        loadData()
        loadTitle()
    }
    
    /// 对齐安卓：从后端 getConfig 获取 dz_syname 作为页面标题
    private func loadTitle() {
        SecureNetworkManager.shared.request(
            api: "/api/stock/getconfig",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                if let dict = res.decrypted,
                   let data = dict["data"] as? [String: Any],
                   let name = data["dz_syname"] as? String,
                   !name.trimmingCharacters(in: .whitespaces).isEmpty {
                    DispatchQueue.main.async {
                        self.gk_navTitle = name.trimmingCharacters(in: .whitespaces)
                    }
                }
            case .failure(_): break
            }
        }
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "大宗交易"
        gk_navLineHidden = false
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
        gk_backStyle = .black
    }
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func setupTabs() {
        tabContainer.backgroundColor = .white
        view.addSubview(tabContainer)
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 当前持仓标签
        currentTabButton.setTitle("当前持仓", for: .normal)
        currentTabButton.setTitleColor(Constants.Color.stockRise, for: .normal)
        currentTabButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
        currentTabButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        currentTabButton.addTarget(self, action: #selector(currentTabTapped), for: .touchUpInside)
        tabContainer.addSubview(currentTabButton)
        currentTabButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 历史持仓标签
        historyTabButton.setTitle("历史持仓", for: .normal)
        historyTabButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
        historyTabButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        historyTabButton.addTarget(self, action: #selector(historyTabTapped), for: .touchUpInside)
        tabContainer.addSubview(historyTabButton)
        historyTabButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 红色下划线指示器（宽度 20）
        tabIndicator.backgroundColor = Constants.Color.stockRise
        tabContainer.addSubview(tabIndicator)
        tabIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tabContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabContainer.heightAnchor.constraint(equalToConstant: 44),
            
            currentTabButton.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            currentTabButton.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            currentTabButton.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            currentTabButton.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.5),
            
            historyTabButton.leadingAnchor.constraint(equalTo: currentTabButton.trailingAnchor),
            historyTabButton.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            historyTabButton.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            historyTabButton.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.5),
            
            tabIndicator.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tabIndicator.heightAnchor.constraint(equalToConstant: 2),
            tabIndicator.widthAnchor.constraint(equalToConstant: 20)
        ])
        
        // 设置指示器初始位置：在“当前持仓”正下方
        tabIndicatorCenterXCurrentConstraint = tabIndicator.centerXAnchor.constraint(equalTo: currentTabButton.centerXAnchor)
        tabIndicatorCenterXHistoryConstraint = tabIndicator.centerXAnchor.constraint(equalTo: historyTabButton.centerXAnchor)
        tabIndicatorCenterXCurrentConstraint.isActive = true
    }
    
    @objc private func currentTabTapped() {
        selectedTab = .current
        updateTabSelection()
        tableView.reloadData()
        updateEmptyState()
    }
    
    @objc private func historyTabTapped() {
        selectedTab = .history
        updateTabSelection()
        tableView.reloadData()
        updateEmptyState()
    }
    
    private func updateTabSelection() {
        let isCurrent = selectedTab == .current
        
        currentTabButton.setTitleColor(isCurrent ? Constants.Color.stockRise : Constants.Color.textSecondary, for: .normal)
        historyTabButton.setTitleColor(!isCurrent ? Constants.Color.stockRise : Constants.Color.textSecondary, for: .normal)
        
        // 切换下划线指示器的位置
        tabIndicatorCenterXCurrentConstraint.isActive = isCurrent
        tabIndicatorCenterXHistoryConstraint.isActive = !isCurrent
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        // 注意：复用标识符不要有空格，需与 dequeue 时的字符串完全一致
        tableView.register(BlockTradingListCell.self, forCellReuseIdentifier: "BlockTradingListCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // tab 与列表之间保留 5pt 间距
            tableView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // 空状态提示
        emptyLabel.text = "暂无数据"
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    private func loadData() {
        loadCurrentHoldings()
        loadHistoryHoldings()
    }
    
    // MARK: - 大宗交易当前持仓
    private func loadCurrentHoldings() {
        SecureNetworkManager.shared.request(
            api: "/api/dzjy/getNowWarehouse",
            method: .get,
            params: ["buytype": "7", "page": "1", "size": "50", "status": "1"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else { return }
                
                DispatchQueue.main.async {
                    self.currentHoldings = list.compactMap { item in
                        self.parseItem(item, isHistory: false)
                    }
                    if self.selectedTab == .current {
                        self.tableView.reloadData()
                        self.updateEmptyState()
                    }
                }
                
            case .failure(_):
                DispatchQueue.main.async {
                    self.currentHoldings = []
                    if self.selectedTab == .current {
                        self.tableView.reloadData()
                        self.updateEmptyState()
                    }
                }
            }
        }
    }
    
    // MARK: - 大宗交易历史持仓
    private func loadHistoryHoldings() {
        SecureNetworkManager.shared.request(
            api: "/api/dzjy/getNowWarehouse_lishi",
            method: .get,
            params: ["buytype": "7", "page": "1", "size": "50", "status": "2"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else { return }
                
                DispatchQueue.main.async {
                    self.historyHoldings = list.compactMap { item in
                        self.parseItem(item, isHistory: true)
                    }
                    if self.selectedTab == .history {
                        self.tableView.reloadData()
                        self.updateEmptyState()
                    }
                }
                
            case .failure(_):
                DispatchQueue.main.async {
                    self.historyHoldings = []
                    if self.selectedTab == .history {
                        self.tableView.reloadData()
                        self.updateEmptyState()
                    }
                }
            }
        }
    }
    
    // MARK: - 解析单条持仓数据
    private func parseItem(_ item: [String: Any], isHistory: Bool) -> BlockTradingListItem {
        let title = item["title"] as? String ?? "--"
        let code = item["code"] as? String ?? "--"
        let allcode = item["allcode"] as? String ?? ""
        let buyPriceVal = item["buyprice"] as? Double ?? (Double("\(item["buyprice"] ?? 0)")) ?? 0
        let currentPriceVal = Double("\(item["cai_buy"] ?? item["newprice"] ?? 0)") ?? 0
        let numberVal = item["number"] as? Int ?? Int("\(item["number"] ?? "0")") ?? 0
        let canBuy = item["canBuy"] as? Int ?? Int("\(item["canBuy"] ?? "0")") ?? 0
        
        // 盈亏计算
        var pl = item["profitLose"] as? Double ?? (item["profitLose"] as? Int).map { Double($0) } ?? 0
        var plRateStr = item["profitLose_rate"] as? String ?? "0.00%"
        
        if pl == 0 && currentPriceVal > 0 && buyPriceVal > 0 {
            // 如果 API 返回 0，尝试本地计算 (对齐安卓逻辑)
            pl = (currentPriceVal - buyPriceVal) * Double(numberVal)
            let rate = (currentPriceVal - buyPriceVal) / buyPriceVal * 100
            plRateStr = String(format: "%.2f%%", rate)
        }
        
        let sign = pl >= 0 ? "+" : ""
        let outTime = item["outtime_name"] as? String ?? "--"
        let createTime = item["createtime_name"] as? String ?? "--"
        
        // 推导交易所
        let typeVal = item["type"] as? Int ?? 0
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
        
        return BlockTradingListItem(
            stockName: title,
            exchange: exchangeStr,
            stockCode: code,
            principal: String(format: "%.0f", buyPriceVal * Double(numberVal)),
            buyPrice: String(format: "%.2f", buyPriceVal),
            currentPrice: String(format: "%.2f", currentPriceVal),
            profit: String(format: "%@%.2f", sign, pl),
            profitRate: plRateStr.hasPrefix("+") || plRateStr.hasPrefix("-") ? plRateStr : "\(sign)\(plRateStr)",
            updateTime: isHistory ? outTime : createTime,
            quantity: "\(numberVal)", // 展示总量
            rawData: item
        )
    }
    
    private func updateEmptyState() {
        let data = selectedTab == .current ? currentHoldings : historyHoldings
        emptyLabel.isHidden = !data.isEmpty
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension BlockTradingListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedTab == .current ? currentHoldings.count : historyHoldings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockTradingListCell", for: indexPath) as! BlockTradingListCell
        let item = selectedTab == .current ? currentHoldings[indexPath.row] : historyHoldings[indexPath.row]
        cell.configure(with: item, isCurrent: selectedTab == .current)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = selectedTab == .current ? currentHoldings[indexPath.row] : historyHoldings[indexPath.row]
        let vc = HoldingDetailViewController()
        vc.holdingData = item.rawData
        vc.isHistorical = (selectedTab == .history)
        vc.hiddingButton = true // 只读模式，对齐安卓 startReadOnly
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - BlockTradingListCell
class BlockTradingListCell: UITableViewCell {
    
    // Row 1
    private let stockNameLabel = UILabel()
    private let profitLabel = UILabel() // 盈亏额 (Profit)
    
    // Row 2
    private let stockCodeLabel = UILabel()
    private let profitRateLabel = UILabel() // 盈亏率
    
    // Row 3
    private let buyPriceTitleLabel = UILabel()
    private let buyPriceLabel = UILabel()
    private let currentPriceTitleLabel = UILabel()
    private let currentPriceLabel = UILabel()
    
    // Row 4
    private let quantityTitleLabel = UILabel()
    private let quantityLabel = UILabel()
    private let buyTimeTitleLabel = UILabel()
    private let buyTimeLabel = UILabel()
    
    private let separatorLine = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        // Row 1
        stockNameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        stockNameLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(stockNameLabel)
        
        profitLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        profitLabel.textAlignment = .right
        contentView.addSubview(profitLabel)
        
        // Row 2
        stockCodeLabel.font = UIFont.systemFont(ofSize: 14)
        stockCodeLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(stockCodeLabel)
        
        profitRateLabel.font = UIFont.systemFont(ofSize: 14)
        profitRateLabel.textAlignment = .right
        contentView.addSubview(profitRateLabel)
        
        // Row 3
        buyPriceTitleLabel.text = "买入价"
        buyPriceTitleLabel.font = UIFont.systemFont(ofSize: 14)
        buyPriceTitleLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(buyPriceTitleLabel)
        
        buyPriceLabel.font = UIFont.systemFont(ofSize: 14)
        buyPriceLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(buyPriceLabel)
        
        currentPriceTitleLabel.text = "当前价"
        currentPriceTitleLabel.font = UIFont.systemFont(ofSize: 14)
        currentPriceTitleLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(currentPriceTitleLabel)
        
        currentPriceLabel.font = UIFont.systemFont(ofSize: 14)
        currentPriceLabel.textColor = Constants.Color.textPrimary
        currentPriceLabel.textAlignment = .right
        contentView.addSubview(currentPriceLabel)
        
        // Row 4
        quantityTitleLabel.text = "数量(股)"
        quantityTitleLabel.font = UIFont.systemFont(ofSize: 14)
        quantityTitleLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(quantityTitleLabel)
        
        quantityLabel.font = UIFont.systemFont(ofSize: 14)
        quantityLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(quantityLabel)
        
        buyTimeTitleLabel.text = "买入时间"
        buyTimeTitleLabel.font = UIFont.systemFont(ofSize: 14)
        buyTimeTitleLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(buyTimeTitleLabel)
        
        buyTimeLabel.font = UIFont.systemFont(ofSize: 14)
        buyTimeLabel.textColor = Constants.Color.textPrimary
        buyTimeLabel.textAlignment = .right
        contentView.addSubview(buyTimeLabel)
        
        separatorLine.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        contentView.addSubview(separatorLine)
        
        // Layout
        for v in contentView.subviews { v.translatesAutoresizingMaskIntoConstraints = false }
        
        let pad: CGFloat = 16
        let vGap: CGFloat = 8
        let col2X: CGFloat = 120
        
        NSLayoutConstraint.activate([
            // Row 1
            stockNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stockNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            
            profitLabel.centerYAnchor.constraint(equalTo: stockNameLabel.centerYAnchor),
            profitLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            // Row 2
            stockCodeLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: vGap),
            stockCodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            
            profitRateLabel.centerYAnchor.constraint(equalTo: stockCodeLabel.centerYAnchor),
            profitRateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            // Row 3
            buyPriceTitleLabel.topAnchor.constraint(equalTo: stockCodeLabel.bottomAnchor, constant: vGap),
            buyPriceTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            
            buyPriceLabel.centerYAnchor.constraint(equalTo: buyPriceTitleLabel.centerYAnchor),
            buyPriceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: col2X),
            
            currentPriceTitleLabel.centerYAnchor.constraint(equalTo: buyPriceTitleLabel.centerYAnchor),
            currentPriceTitleLabel.trailingAnchor.constraint(equalTo: currentPriceLabel.leadingAnchor, constant: -12),
            
            currentPriceLabel.centerYAnchor.constraint(equalTo: buyPriceTitleLabel.centerYAnchor),
            currentPriceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            // Row 4
            quantityTitleLabel.topAnchor.constraint(equalTo: buyPriceTitleLabel.bottomAnchor, constant: vGap),
            quantityTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            
            quantityLabel.centerYAnchor.constraint(equalTo: quantityTitleLabel.centerYAnchor),
            quantityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: col2X),
            
            buyTimeTitleLabel.centerYAnchor.constraint(equalTo: quantityTitleLabel.centerYAnchor),
            buyTimeTitleLabel.trailingAnchor.constraint(equalTo: buyTimeLabel.leadingAnchor, constant: -12),
            
            buyTimeLabel.centerYAnchor.constraint(equalTo: quantityTitleLabel.centerYAnchor),
            buyTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            separatorLine.topAnchor.constraint(equalTo: quantityTitleLabel.bottomAnchor, constant: 12),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 8), 
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with item: BlockTradingListItem, isCurrent: Bool) {
        stockNameLabel.text = item.stockName
        stockCodeLabel.text = item.stockCode
        
        buyPriceLabel.text = item.buyPrice
        currentPriceLabel.text = item.currentPrice ?? "--"
        quantityLabel.text = item.quantity
        buyTimeLabel.text = item.updateTime
        
        // Profit alignment
        profitLabel.text = item.profit
        profitRateLabel.text = item.profitRate
        
        let isRise = !item.profit.contains("-") && item.profit != "0.00" && item.profit != "+0.00"
        let color = isRise ? Constants.Color.stockRise : Constants.Color.stockFall
        profitLabel.textColor = color
        profitRateLabel.textColor = color
        
        buyTimeTitleLabel.text = isCurrent ? "买入时间" : "卖出时间"
        currentPriceTitleLabel.text = isCurrent ? "当前价" : "卖出价"
    }
}
