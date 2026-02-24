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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTabs()
        setupTableView()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = Constants.Color.themeBlue
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "大宗交易"
        gk_navLineHidden = true
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
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
    }
    
    @objc private func historyTabTapped() {
        selectedTab = .history
        updateTabSelection()
        tableView.reloadData()
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
                
                self.currentHoldings = list.compactMap { item in
                    self.parseItem(item, isHistory: false)
                }
                
                if self.selectedTab == .current {
                    self.tableView.reloadData()
                }
                
            case .failure(_): break
            }
        }
    }
    
    // MARK: - 大宗交易历史持仓
    private func loadHistoryHoldings() {
        SecureNetworkManager.shared.request(
            api: "/api/dzjy/getNowWarehouse_lishi",
            method: .get,
            params: ["buytype": "1", "page": "1", "size": "50", "status": "2"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else { return }
                
                self.historyHoldings = list.compactMap { item in
                    self.parseItem(item, isHistory: true)
                }
                
                if self.selectedTab == .history {
                    self.tableView.reloadData()
                }
                
            case .failure(_): break
            }
        }
    }
    
    // MARK: - 解析单条持仓数据
    private func parseItem(_ item: [String: Any], isHistory: Bool) -> BlockTradingListItem {
        let title = item["title"] as? String ?? "--"
        let code = item["code"] as? String ?? "--"
        let allcode = item["allcode"] as? String ?? ""
        let buyPrice = item["buyprice"] as? Double ?? 0
        let caiBuy = Double("\(item["cai_buy"] ?? 0)") ?? 0
        let numberVal = item["number"] as? Int ?? Int("\(item["number"] ?? "0")") ?? 0
        let number = "\(numberVal)"
        let canBuy = item["canBuy"] as? Int ?? Int("\(item["canBuy"] ?? "0")") ?? 0
        let pl = item["profitLose"] as? Double ?? (item["profitLose"] as? Int).map { Double($0) } ?? 0
        let plRate = item["profitLose_rate"] as? String ?? "--"
        let createTime = item["createtime_name"] as? String ?? "--"
        let outTime = item["outtime_name"] as? String ?? createTime
        
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
        
        // 本金 = 买入价 * 数量
        let qty = Int(number) ?? 0
        let principal = String(format: "%.0f", buyPrice * Double(qty))
        let sign = pl >= 0 ? "+" : ""
        
        return BlockTradingListItem(
            stockName: title,
            exchange: exchangeStr,
            stockCode: code,
            principal: principal,
            buyPrice: String(format: "%.2f", buyPrice),
            currentPrice: String(format: "%.2f", caiBuy),
            profit: String(format: "%@%.2f", sign, pl),
            profitRate: plRate,
            updateTime: isHistory ? outTime : createTime,
            quantity: "\(canBuy)"
        )
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
        cell.onSell = { [weak self] in
            guard let self = self else { return }
            let vc = AccountTradeViewController()
            vc.stockName = item.stockName
            vc.stockCode = item.stockCode
            vc.exchange = item.exchange
            vc.currentPrice = item.currentPrice ?? item.buyPrice
            vc.sellBuyPrice = item.buyPrice
            vc.sellHoldingQty = item.quantity
            vc.useProvidedHoldings = true
            vc.tradeType = .sell
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = BlockTradingListHeaderView()
        header.configure(isCurrent: selectedTab == .current)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: 处理点击事件
    }
}

// MARK: - BlockTradingListHeaderView (表头)
class BlockTradingListHeaderView: UITableViewHeaderFooterView {
    
    private let stockCodeLabel = UILabel()
    private let principalLabel = UILabel()
    private let priceLabel = UILabel()
    private let profitLabel = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        let pad: CGFloat = 16
        
        stockCodeLabel.text = "股票代码"
        stockCodeLabel.font = UIFont.systemFont(ofSize: 10)
        stockCodeLabel.textColor = Constants.Color.textSecondary
        stockCodeLabel.textAlignment = .left
        contentView.addSubview(stockCodeLabel)
        stockCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        principalLabel.text = "本金/数量"
        principalLabel.font = UIFont.systemFont(ofSize: 10)
        principalLabel.textColor = Constants.Color.textSecondary
        principalLabel.textAlignment = .center
        contentView.addSubview(principalLabel)
        principalLabel.translatesAutoresizingMaskIntoConstraints = false
        
        priceLabel.text = "买入价/当前价"
        priceLabel.font = UIFont.systemFont(ofSize: 10)
        priceLabel.textColor = Constants.Color.textSecondary
        priceLabel.textAlignment = .center
        contentView.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        profitLabel.text = "收益/收益率"
        profitLabel.font = UIFont.systemFont(ofSize: 10)
        profitLabel.textColor = Constants.Color.textSecondary
        profitLabel.textAlignment = .right
        contentView.addSubview(profitLabel)
        profitLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stockCodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            stockCodeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stockCodeLabel.widthAnchor.constraint(equalToConstant: 80),
            
            principalLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -60),
            principalLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            principalLabel.widthAnchor.constraint(equalToConstant: 80),
            
            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 20),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            priceLabel.widthAnchor.constraint(equalToConstant: 100),
            
            profitLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            profitLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profitLabel.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configure(isCurrent: Bool) {
        priceLabel.text = isCurrent ? "买入价/当前价" : "买入价/卖出价"
    }
}

// MARK: - BlockTradingListCell
class BlockTradingListCell: UITableViewCell {
    
    private let stockNameLabel = UILabel()
    private let stockCodeLabel = UILabel()
    private let principalLabel = UILabel()
    private let buyPriceLabel = UILabel()
    private let currentPriceLabel = UILabel()
    private let profitLabel = UILabel()
    private let profitRateLabel = UILabel()
    private let dateLabel = UILabel()
    private let sellButton = UIButton(type: .system)
    private let separatorLine = UIView()
    
    /// 卖出按钮回调
    var onSell: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        let pad: CGFloat = 16
        
        // 股票名称（第一行）
        stockNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        stockNameLabel.textColor = Constants.Color.textPrimary
        stockNameLabel.textAlignment = .left
        contentView.addSubview(stockNameLabel)
        stockNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票代码（第二行，包含交易所）
        stockCodeLabel.font = UIFont.systemFont(ofSize: 13)
        stockCodeLabel.textColor = Constants.Color.textSecondary
        stockCodeLabel.textAlignment = .left
        contentView.addSubview(stockCodeLabel)
        stockCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 本金/数量（居中）
        principalLabel.font = UIFont.systemFont(ofSize: 15)
        principalLabel.textColor = Constants.Color.textPrimary
        principalLabel.textAlignment = .center
        contentView.addSubview(principalLabel)
        principalLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 买入价（居中，第一行）
        buyPriceLabel.font = UIFont.systemFont(ofSize: 15)
        buyPriceLabel.textColor = Constants.Color.textPrimary
        buyPriceLabel.textAlignment = .center
        contentView.addSubview(buyPriceLabel)
        buyPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 当前价/卖出价（居中，第二行）
        currentPriceLabel.font = UIFont.systemFont(ofSize: 13)
        currentPriceLabel.textColor = Constants.Color.textSecondary
        currentPriceLabel.textAlignment = .center
        contentView.addSubview(currentPriceLabel)
        currentPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 收益（右对齐，第一行，红色）
        profitLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        profitLabel.textColor = Constants.Color.stockRise
        profitLabel.textAlignment = .right
        contentView.addSubview(profitLabel)
        profitLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 收益率（右对齐，第二行，红色）
        profitRateLabel.font = UIFont.systemFont(ofSize: 13)
        profitRateLabel.textColor = Constants.Color.stockRise
        profitRateLabel.textAlignment = .right
        contentView.addSubview(profitRateLabel)
        profitRateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 底部日期（左对齐）
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = Constants.Color.textSecondary
        dateLabel.textAlignment = .left
        contentView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 底部卖出按钮（右对齐，仅当前持仓时显示）
        sellButton.setTitle("卖出", for: .normal)
        sellButton.setTitleColor(.white, for: .normal)
        sellButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        sellButton.backgroundColor = Constants.Color.stockRise
        sellButton.layer.cornerRadius = 8
        sellButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
        sellButton.addTarget(self, action: #selector(sellTapped), for: .touchUpInside)
        contentView.addSubview(sellButton)
        sellButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 分隔线
        separatorLine.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        contentView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 第一行
            stockNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            stockNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stockNameLabel.widthAnchor.constraint(equalToConstant: 80),
            
            principalLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -60),
            principalLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            principalLabel.widthAnchor.constraint(equalToConstant: 80),
            
            buyPriceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 20),
            buyPriceLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            buyPriceLabel.widthAnchor.constraint(equalToConstant: 100),
            
            profitLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            profitLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            profitLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // 第二行
            stockCodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            stockCodeLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: 6),
            stockCodeLabel.widthAnchor.constraint(equalToConstant: 80),
            
            currentPriceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 20),
            currentPriceLabel.topAnchor.constraint(equalTo: buyPriceLabel.bottomAnchor, constant: 6),
            currentPriceLabel.widthAnchor.constraint(equalToConstant: 100),
            
            profitRateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            profitRateLabel.topAnchor.constraint(equalTo: profitLabel.bottomAnchor, constant: 6),
            profitRateLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // 底部日期 + 卖出按钮
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            dateLabel.topAnchor.constraint(equalTo: stockCodeLabel.bottomAnchor, constant: 10),
            
            sellButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            sellButton.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            
            // 分隔线
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            separatorLine.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }
    
    func configure(with item: BlockTradingListItem, isCurrent: Bool) {
        stockNameLabel.text = item.stockName
        stockCodeLabel.text = "\(item.exchange) \(item.stockCode)"
        principalLabel.text = item.principal
        buyPriceLabel.text = item.buyPrice
        
        if isCurrent {
            // 当前持仓：显示当前价
            currentPriceLabel.text = item.currentPrice ?? "-"
        } else {
            // 历史持仓：显示卖出价
            currentPriceLabel.text = item.currentPrice ?? "-"
        }
        
        profitLabel.text = item.profit.isEmpty ? "" : item.profit
        profitRateLabel.text = item.profitRate.isEmpty ? "" : item.profitRate
        
        // 底部日期
        dateLabel.text = item.updateTime
        
        // 卖出按钮：当前持仓显示，历史持仓隐藏
        sellButton.isHidden = !isCurrent
    }
    
    @objc private func sellTapped() {
        onSell?()
    }
}
