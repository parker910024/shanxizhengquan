//
//  MarketViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class MarketViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // 数据源 (名称, 指数值, 涨跌额, 涨跌幅, 是否上涨)
    private var indices: [(String, String, String, String, Bool)] = [
        ("上证指数", "3968.84", "+3.72", "+0.09%", true),
        ("上证380", "3968.84", "+3.72", "+0.09%", true),
        ("上证180", "10015.86", "-15.97", "-0.16%", false),
        ("深证成指", "12542.30", "-12.50", "-0.10%", false),
        ("创业板指", "2685.20", "+8.30", "+0.31%", true),
        ("科创50", "1025.60", "-5.20", "-0.50%", false)
    ]
    
    private let tabs = ["自选", "沪深", "创业", "科创", "北证"]
    private var selectedTabIndex: Int = 0
    
    // 股票数据: (名称, 交易所 代码, 最新价, 涨幅, 是否上涨) 涨幅需含正负号
    private var stockData: [[(String, String, String, String, Bool)]] = [
        [
            ("舒泰神", "深 300204", "27.32", "-0.98%", false),
            ("中钢天源", "深 002057", "8.65", "-0.92%", false),
            ("芭薇股份", "京 837023", "6.28", "-0.63%", false),
            ("兴图新科", "沪 688081", "18.52", "+1.61%", true)
        ],
        [
            ("贵州茅台", "沪 600519", "1685.00", "+0.85%", true),
            ("宁德时代", "深 300750", "185.20", "-0.50%", false)
        ],
        [
            ("创业板A", "创 300001", "20.10", "+2.30%", true),
            ("创业板B", "创 300002", "18.50", "-1.10%", false)
        ],
        [
            ("科创板A", "科 688001", "50.20", "+3.50%", true),
            ("科创板B", "科 688002", "45.80", "-0.80%", false)
        ],
        [
            ("北交所A", "京 430001", "8.50", "+1.50%", true),
            ("北交所B", "京 430002", "9.20", "-0.30%", false)
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    /// 外部调用：切换到指定行情分组（例如首页“沪深行情”入口）
    func switchToTab(index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        selectedTabIndex = index
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.backgroundColor = Constants.Color.backgroundMain
        
        setupNavigationBar()
        setupTableView()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = Constants.Color.themeBlue
        gk_navTintColor = .white
        // 先设置 Font 再设置 Color，避免 GKNavigationBar 在构建 titleTextAttributes 时因 fallback 为 nil 崩溃
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "行情"
        gk_navLineHidden = true
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
        
        // 左侧: IPO 与 新股申购 上下结构，整体左间距 15（由 gk_navItemLeftSpace 控制）
        let ipoView = UIView()
        let ipoBadge = UILabel()
        ipoBadge.text = "IPO"
        ipoBadge.font = UIFont.boldSystemFont(ofSize: 11)
        ipoBadge.textColor = .white
        ipoBadge.backgroundColor = .clear
        ipoBadge.layer.cornerRadius = 4
        ipoBadge.layer.borderWidth = 1
        ipoBadge.layer.borderColor = UIColor.white.cgColor
        ipoBadge.textAlignment = .center
        ipoBadge.clipsToBounds = true
        ipoView.addSubview(ipoBadge)
        ipoBadge.translatesAutoresizingMaskIntoConstraints = false
        
        let ipoLabel = UILabel()
        ipoLabel.text = "新股申购"
        ipoLabel.font = UIFont.systemFont(ofSize: 12)
        ipoLabel.textColor = .white
        ipoView.addSubview(ipoLabel)
        ipoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let ipoTap = UITapGestureRecognizer(target: self, action: #selector(ipoViewTapped))
        ipoView.addGestureRecognizer(ipoTap)
        ipoView.isUserInteractionEnabled = true
        
        ipoLabel.textAlignment = .center
        NSLayoutConstraint.activate([
            ipoBadge.topAnchor.constraint(equalTo: ipoView.topAnchor),
            ipoBadge.centerXAnchor.constraint(equalTo: ipoView.centerXAnchor),
            ipoBadge.widthAnchor.constraint(equalToConstant: 36),
            ipoBadge.heightAnchor.constraint(equalToConstant: 22),
            ipoLabel.topAnchor.constraint(equalTo: ipoBadge.bottomAnchor, constant: 2),
            ipoLabel.centerXAnchor.constraint(equalTo: ipoView.centerXAnchor),
            ipoLabel.bottomAnchor.constraint(equalTo: ipoView.bottomAnchor),
            ipoView.widthAnchor.constraint(equalToConstant: 56),
            ipoView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        gk_navLeftBarButtonItem = UIBarButtonItem(customView: ipoView)
        
        let searchBtn = UIButton(type: .system)
        searchBtn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchBtn.tintColor = .white
        searchBtn.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        gk_navRightBarButtonItem = UIBarButtonItem(customView: searchBtn)
    }
    
    @objc private func ipoViewTapped() {
        // TODO: 跳转新股申购
    }
    
    @objc private func searchTapped() {
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        
        // 注册cell
        tableView.register(IndexScrollTableViewCell.self, forCellReuseIdentifier: "IndexScrollCell")
        tableView.register(TabScrollTableViewCell.self, forCellReuseIdentifier: "TabScrollCell")
        tableView.register(StockListTableViewCell.self, forCellReuseIdentifier: "StockListCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight+15),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension MarketViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3 // IndexScroll, TabScroll, StockList
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            // 指数横向滚动
            let cell = tableView.dequeueReusableCell(withIdentifier: "IndexScrollCell", for: indexPath) as! IndexScrollTableViewCell
            cell.configure(with: indices)
            cell.onCardTapped = { [weak self] name, code in
                guard let self = self else { return }
                let detailVC = StockDetailViewController()
                detailVC.stockName = name
                detailVC.stockCode = code
                detailVC.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(detailVC, animated: true)
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TabScrollCell", for: indexPath) as! TabScrollTableViewCell
            cell.configure(with: tabs, selectedIndex: selectedTabIndex)
            cell.onTabSelected = { [weak self] index in
                guard let self = self else { return }
                self.selectedTabIndex = index
                self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
            }
            return cell
        case 2:
            // 股票列表
            let cell = tableView.dequeueReusableCell(withIdentifier: "StockListCell", for: indexPath) as! StockListTableViewCell
            cell.configure(with: stockData[selectedTabIndex])
            cell.onStockTapped = { [weak self] name, code, exchange in
                guard let self = self else { return }
                let detailVC = StockDetailViewController()
                detailVC.stockName = name
                detailVC.stockCode = code
                detailVC.exchange = exchange
                detailVC.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(detailVC, animated: true)
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate
extension MarketViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 108  // 指数卡片区：上下 16pt + 卡片 76pt
        case 1:
            return 44   // Tab 高度
        case 2:
            return UITableView.automaticDimension
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 2:
            return 300
        default:
            return 100
        }
    }
}

// MARK: - Index Scroll Cell (指数横向滚动)
class IndexScrollTableViewCell: UITableViewCell {
    private let scrollView = UIScrollView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 16)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    var onCardTapped: ((String, String) -> Void)? // (name, code)
    private var indicesData: [(String, String, String, String, Bool)] = []
    
    func configure(with indices: [(String, String, String, String, Bool)]) {
        self.indicesData = indices
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let cardWidth: CGFloat = 124
        let cardHeight: CGFloat = 76
        let spacing: CGFloat = 12
        let leftInset: CGFloat = 10
        
        for (index, indexData) in indices.enumerated() {
            let cardView = createIndexCard(
                title: indexData.0,
                value: indexData.1,
                change: indexData.2,
                changePercent: indexData.3,
                isRising: indexData.4
            )
            scrollView.addSubview(cardView)
            cardView.translatesAutoresizingMaskIntoConstraints = false
            
            // 添加点击手势
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
            cardView.addGestureRecognizer(tapGesture)
            cardView.isUserInteractionEnabled = true
            cardView.tag = index
            
            NSLayoutConstraint.activate([
                cardView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: leftInset + CGFloat(index) * (cardWidth + spacing)),
                cardView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                cardView.widthAnchor.constraint(equalToConstant: cardWidth),
                cardView.heightAnchor.constraint(equalToConstant: cardHeight)
            ])
        }
        
        let totalWidth = leftInset + CGFloat(indices.count) * (cardWidth + spacing) - spacing + 16
        scrollView.contentSize = CGSize(width: totalWidth, height: cardHeight)
    }
    
    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let cardView = gesture.view else { return }
        let index = cardView.tag
        if index < indicesData.count {
            let indexData = indicesData[index]
            // 使用指数名称作为股票名称，指数值作为代码（实际项目中应该使用真实的股票代码）
            onCardTapped?(indexData.0, indexData.1)
        }
    }
    
    private func createIndexCard(title: String, value: String, change: String, changePercent: String, isRising: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 8
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 3
        card.layer.shadowOpacity = 0.08
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = Constants.Color.textSecondary
        card.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.boldSystemFont(ofSize: 18)
        valueLabel.textColor = isRising ? Constants.Color.stockRise : Constants.Color.stockFall
        card.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 涨跌额 + 涨跌幅 同一行，如 "+3.72 +0.09%"
        let changeText = "\(change) \(changePercent)"
        let subLabel = UILabel()
        subLabel.text = changeText
        subLabel.font = UIFont.systemFont(ofSize: 11)
        subLabel.textColor = isRising ? Constants.Color.stockRise : Constants.Color.stockFall
        card.addSubview(subLabel)
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            valueLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            subLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            subLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            subLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -10)
        ])
        
        return card
    }
}

// MARK: - Tab Scroll Cell (Tab横向滚动)
class TabScrollTableViewCell: UITableViewCell {
    private let scrollView = UIScrollView()
    private var tabButtons: [UIButton] = []
    var onTabSelected: ((Int) -> Void)?
    private var selectedIndex: Int = 0
    
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
        contentView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with tabs: [String], selectedIndex: Int) {
        self.selectedIndex = selectedIndex
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()
        
        let buttonWidth: CGFloat = 56
        let spacing: CGFloat = 12
        let leftInset: CGFloat = 20
        
        for (index, tabTitle) in tabs.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(tabTitle, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            scrollView.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            tabButtons.append(button)
            
            let x = leftInset + CGFloat(index) * (buttonWidth + spacing)
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: x),
                button.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: buttonWidth),
                button.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        let totalWidth = leftInset + CGFloat(tabs.count) * (buttonWidth + spacing) - spacing + 16
        scrollView.contentSize = CGSize(width: totalWidth, height: 44)
        updateTabSelection()
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let newIndex = sender.tag
        guard newIndex != selectedIndex else { return }
        selectedIndex = newIndex
        updateTabSelection()
        onTabSelected?(selectedIndex)
    }
    
    private func updateTabSelection() {
        for (index, button) in tabButtons.enumerated() {
            let selected = (index == selectedIndex)
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = selected ? UIFont.boldSystemFont(ofSize: 15) : UIFont.systemFont(ofSize: 14)
        }
    }
}

// MARK: - Stock List Cell (股票列表)
class StockListTableViewCell: UITableViewCell {
    private let containerView = UIView()
    private let headerView = UIView()
    private let stockStackView = UIStackView()
    var onStockTapped: ((String, String, String) -> Void)? // (name, code, exchange)
    private var stocksData: [(String, String, String, String, Bool)] = []
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        containerView.backgroundColor = .white
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 表头
        headerView.backgroundColor = Constants.Color.backgroundMain
        containerView.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = "名称"
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textColor = Constants.Color.textSecondary
        headerView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let priceLabel = UILabel()
        priceLabel.text = "最新价"
        priceLabel.font = UIFont.systemFont(ofSize: 15)
        priceLabel.textColor = Constants.Color.textSecondary
        headerView.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let changeContainer = UIView()
        headerView.addSubview(changeContainer)
        changeContainer.translatesAutoresizingMaskIntoConstraints = false
        let sortIcon = UIImageView(image: UIImage(systemName: "arrowtriangle.up"))
        sortIcon.tintColor = Constants.Color.orange
        sortIcon.contentMode = .scaleAspectFit
        changeContainer.addSubview(sortIcon)
        sortIcon.translatesAutoresizingMaskIntoConstraints = false
        let changeLabel = UILabel()
        changeLabel.text = "涨幅"
        changeLabel.font = UIFont.systemFont(ofSize: 15)
        changeLabel.textColor = Constants.Color.textSecondary
        changeContainer.addSubview(changeLabel)
        changeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sortIcon.leadingAnchor.constraint(equalTo: changeContainer.leadingAnchor),
            sortIcon.centerYAnchor.constraint(equalTo: changeContainer.centerYAnchor),
            sortIcon.widthAnchor.constraint(equalToConstant: 10),
            sortIcon.heightAnchor.constraint(equalToConstant: 10),
            changeLabel.leadingAnchor.constraint(equalTo: sortIcon.trailingAnchor, constant: 2),
            changeLabel.centerYAnchor.constraint(equalTo: changeContainer.centerYAnchor),
            changeLabel.trailingAnchor.constraint(equalTo: changeContainer.trailingAnchor)
        ])
        
        // 股票列表
        stockStackView.axis = .vertical
        stockStackView.spacing = 0
        containerView.addSubview(stockStackView)
        stockStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: Constants.Spacing.lg),
            nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            priceLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            priceLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            changeContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -Constants.Spacing.lg),
            changeContainer.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            stockStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            stockStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stockStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stockStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with stocks: [(String, String, String, String, Bool)]) {
        self.stocksData = stocks
        // 清除旧的股票行
        stockStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, stock) in stocks.enumerated() {
            let stockRow = createStockRow(
                name: stock.0,
                code: stock.1,
                price: stock.2,
                change: stock.3,
                isRising: stock.4,
                index: index
            )
            stockStackView.addArrangedSubview(stockRow)
        }
        
        let endLabel = UILabel()
        endLabel.text = "--END--"
        endLabel.font = UIFont.systemFont(ofSize: 12)
        endLabel.textColor = Constants.Color.textTertiary
        endLabel.textAlignment = .center
        stockStackView.addArrangedSubview(endLabel)
    }
    
    /// 交易所徽章颜色: 深-浅蓝, 京-浅紫, 沪-浅橙, 创-浅绿, 科-浅粉
    private static func badgeColor(for exchange: String) -> UIColor {
        switch exchange {
        case "深": return UIColor(red: 0.26, green: 0.65, blue: 0.96, alpha: 1.0)   // #42A5F5
        case "京": return UIColor(red: 0.67, green: 0.28, blue: 0.74, alpha: 1.0)   // #AB47BC
        case "沪": return UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)      // #FF9800
        case "创": return UIColor(red: 0.4, green: 0.73, blue: 0.42, alpha: 1.0)    // #66BB6A
        case "科": return UIColor(red: 0.93, green: 0.25, blue: 0.48, alpha: 1.0)   // #EC407A
        default:  return Constants.Color.textTertiary
        }
    }
    
    private func createStockRow(name: String, code: String, price: String, change: String, isRising: Bool, index: Int) -> UIView {
        let row = UIView()
        row.backgroundColor = .white
        row.tag = index
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(stockRowTapped(_:)))
        row.addGestureRecognizer(tapGesture)
        row.isUserInteractionEnabled = true
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = Constants.Color.textPrimary
        row.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 解析 "深 300204" -> 交易所 + 代码
        let parts = code.split(separator: " ", maxSplits: 1).map(String.init)
        let exchange = parts.first ?? ""
        let codeNum = parts.count > 1 ? parts[1] : code
        
        let badge = UILabel()
        badge.text = exchange
        badge.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        badge.textColor = .white
        badge.backgroundColor = Self.badgeColor(for: exchange)
        badge.layer.cornerRadius = 3
        badge.clipsToBounds = true
        badge.textAlignment = .center
        row.addSubview(badge)
        badge.translatesAutoresizingMaskIntoConstraints = false
        
        let codeLabel = UILabel()
        codeLabel.text = codeNum
        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = Constants.Color.textTertiary
        row.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.font = UIFont.systemFont(ofSize: 15)
        priceLabel.textColor = isRising ? Constants.Color.stockRise : Constants.Color.stockFall
        priceLabel.textAlignment = .center
        row.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let changeLabel = UILabel()
        changeLabel.text = change.hasPrefix("+") || change.hasPrefix("-") ? change : (isRising ? "+\(change)" : change)
        changeLabel.font = UIFont.systemFont(ofSize: 15)
        changeLabel.textColor = isRising ? Constants.Color.stockRise : Constants.Color.stockFall
        changeLabel.textAlignment = .right
        row.addSubview(changeLabel)
        changeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 行底细横线
        let line = UIView()
        line.backgroundColor = Constants.Color.separator
        row.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: Constants.Spacing.lg),
            nameLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),
            badge.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: Constants.Spacing.lg),
            badge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            badge.widthAnchor.constraint(equalToConstant: 20),
            badge.heightAnchor.constraint(equalToConstant: 16),
            codeLabel.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 4),
            codeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            codeLabel.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor, constant: -10),
            priceLabel.centerXAnchor.constraint(equalTo: row.centerXAnchor),
            priceLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            changeLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -Constants.Spacing.lg),
            changeLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            line.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: Constants.Spacing.lg),
            line.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -Constants.Spacing.lg),
            line.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            row.heightAnchor.constraint(equalToConstant: 62)
        ])
        
        return row
    }
    
    @objc private func stockRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view else { return }
        let index = row.tag
        if index < stocksData.count {
            let stock = stocksData[index]
            // 解析 "深 300204" -> 交易所 + 代码
            let parts = stock.1.split(separator: " ", maxSplits: 1).map(String.init)
            let exchange = parts.first ?? ""
            let codeNum = parts.count > 1 ? parts[1] : stock.1
            onStockTapped?(stock.0, codeNum, exchange)
        }
    }
}
