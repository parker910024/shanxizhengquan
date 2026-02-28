//
//  HistoricalHoldingsViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// 历史持仓数据模型
struct HistoricalHolding {
    let stockName: String
    let stockCode: String
    let principal: Double
    let quantity: Int
    let buyPrice: Double
    let sellPrice: Double?
    let profit: Double?
    let sellType: String?
    let transactionTime: Date
}

class HistoricalHoldingsViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // 筛选区域
    private let filterContainer = UIView()
    private let periodButton = UIButton(type: .system)
    private let dateRangeLabel = UILabel()
    private let calendarButton = UIButton(type: .system)
    
    // 数据源
    private var holdings: [HistoricalHolding] = []
    private var selectedPeriod: TimePeriod = .thisWeek
    private var startDate: Date = Date()
    private var endDate: Date = Date()
    
    enum TimePeriod: String, CaseIterable {
        case thisWeek = "本周"
        case lastWeek = "上周"
        case thisMonth = "本月"
        case lastMonth = "上月"
        case custom = "自定义"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeDates()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    private func initializeDates() {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7
        startDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: now) ?? now
        endDate = now
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "历史持仓"
        gk_navLineHidden = false
        gk_backStyle = .black
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        setupFilterSection()
        setupTableView()
    }
    
    // MARK: - Filter Section
    private func setupFilterSection() {
        filterContainer.backgroundColor = .white
        view.addSubview(filterContainer)
        filterContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 周期选择按钮
        periodButton.setTitle("本周 ▼", for: .normal)
        periodButton.setTitleColor(Constants.Color.textPrimary, for: .normal)
        periodButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        periodButton.addTarget(self, action: #selector(periodButtonTapped), for: .touchUpInside)
        filterContainer.addSubview(periodButton)
        periodButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 日期范围标签
        updateDateRangeLabel()
        dateRangeLabel.font = UIFont.systemFont(ofSize: 14)
        dateRangeLabel.textColor = Constants.Color.textSecondary
        filterContainer.addSubview(dateRangeLabel)
        dateRangeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 日历按钮
        calendarButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        calendarButton.tintColor = Constants.Color.textSecondary
        calendarButton.addTarget(self, action: #selector(calendarButtonTapped), for: .touchUpInside)
        filterContainer.addSubview(calendarButton)
        calendarButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 分割线
        let separator = UIView()
        separator.backgroundColor = Constants.Color.separator
        filterContainer.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            filterContainer.topAnchor.constraint(equalTo: view.topAnchor,constant: Constants.Navigation.totalNavigationHeight + 10),
            filterContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterContainer.heightAnchor.constraint(equalToConstant: 50),
            
            periodButton.leadingAnchor.constraint(equalTo: filterContainer.leadingAnchor, constant: 16),
            periodButton.centerYAnchor.constraint(equalTo: filterContainer.centerYAnchor),
            
            // 日期label和日历图标紧靠在一起，居右显示
            calendarButton.trailingAnchor.constraint(equalTo: filterContainer.trailingAnchor, constant: -16),
            calendarButton.centerYAnchor.constraint(equalTo: filterContainer.centerYAnchor),
            calendarButton.widthAnchor.constraint(equalToConstant: 20),
            calendarButton.heightAnchor.constraint(equalToConstant: 20),
            
            dateRangeLabel.trailingAnchor.constraint(equalTo: calendarButton.leadingAnchor, constant: -4),
            dateRangeLabel.centerYAnchor.constraint(equalTo: filterContainer.centerYAnchor),
            
            separator.bottomAnchor.constraint(equalTo: filterContainer.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: filterContainer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: filterContainer.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }
    
    private func updateDateRangeLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        dateRangeLabel.text = "\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))"
    }
    
    @objc private func periodButtonTapped() {
        let alert = UIAlertController(title: "选择时间周期", message: nil, preferredStyle: .actionSheet)
        
        for period in TimePeriod.allCases {
            alert.addAction(UIAlertAction(title: period.rawValue, style: .default) { [weak self] _ in
                self?.selectPeriod(period)
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // iPad支持
        if let popover = alert.popoverPresentationController {
            popover.sourceView = periodButton
            popover.sourceRect = periodButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func selectPeriod(_ period: TimePeriod) {
        selectedPeriod = period
        periodButton.setTitle("\(period.rawValue) ▼", for: .normal)
        
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .thisWeek:
            let weekday = calendar.component(.weekday, from: now)
            let daysFromMonday = (weekday + 5) % 7
            startDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: now) ?? now
            endDate = now
        case .lastWeek:
            let weekday = calendar.component(.weekday, from: now)
            let daysFromMonday = (weekday + 5) % 7
            let thisWeekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: now) ?? now
            startDate = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) ?? now
            endDate = calendar.date(byAdding: .day, value: -1, to: thisWeekStart) ?? now
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            startDate = calendar.date(from: components) ?? now
            endDate = now
        case .lastMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            if let thisMonthStart = calendar.date(from: components),
               let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: thisMonthStart),
               let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) {
                startDate = lastMonthStart
                endDate = lastMonthEnd
            }
        case .custom:
            // 自定义时打开日期选择器
            calendarButtonTapped()
            return
        }
        
        updateDateRangeLabel()
        loadData()
    }
    
    @objc private func calendarButtonTapped() {
        let datePickerVC = DateRangePickerViewController()
        datePickerVC.startDate = startDate
        datePickerVC.endDate = endDate
        datePickerVC.onDateSelected = { [weak self] start, end in
            self?.startDate = start
            self?.endDate = end
            self?.selectedPeriod = .custom
            self?.periodButton.setTitle("自定义 ▼", for: .normal)
            self?.updateDateRangeLabel()
            self?.loadData()
        }
        let navController = UINavigationController(rootViewController: datePickerVC)
        present(navController, animated: true)
    }
    
    // MARK: - TableView
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(HistoricalHoldingCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Data
    private func loadData() {
        // 模拟数据
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        holdings = [
            HistoricalHolding(
                stockName: "赛诺医疗",
                stockCode: "688108",
                principal: 2259.23,
                quantity: 100,
                buyPrice: 22.59,
                sellPrice: 22.59,
                profit: -19.0,
                sellType: "平仓",
                transactionTime: formatter.date(from: "2026-01-06 13:21:11") ?? Date()
            ),
            HistoricalHolding(
                stockName: "沪688108",
                stockCode: "688108",
                principal: 100.0,
                quantity: 100,
                buyPrice: 22.59,
                sellPrice: 22.59,
                profit: 19.0,
                sellType: "平仓",
                transactionTime: formatter.date(from: "2026-01-06 13:21:11") ?? Date()
            )
        ]
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension HistoricalHoldingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return holdings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! HistoricalHoldingCell
        let holding = holdings[indexPath.row]
        cell.configure(with: holding)
        cell.onDetailButtonTapped = { [weak self] in
            self?.showDetail(for: holding)
        }
        return cell
    }
    
    private func showDetail(for holding: HistoricalHolding) {
        let detailVC = HistoricalHoldingDetailViewController()
        
        // 转换数据模型
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let detail = HistoricalHoldingDetail(
            stockCode: holding.stockCode,
            buyLots: holding.quantity / 100, // 假设1手=100股
            buyQuantity: holding.quantity,
            closingFee: 1.23, // 模拟数据
            stampDuty: 1.23, // 模拟数据
            buyTime: holding.transactionTime,
            sellType: holding.sellType,
            sellPrice: holding.sellPrice,
            profit: holding.profit,
            sellTime: holding.sellPrice != nil ? holding.transactionTime : nil
        )
        
        detailVC.holdingDetail = detail
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160 // 包含表头、数据、时间和按钮的高度
    }
}

// MARK: - HistoricalHoldingCell
class HistoricalHoldingCell: UITableViewCell {
    
    // 表头标签
    private let headerStockLabel = UILabel()
    private let headerPrincipalLabel = UILabel()
    private let headerPriceLabel = UILabel()
    private let headerProfitLabel = UILabel()
    
    // 数据标签
    private let stockNameLabel = UILabel()
    private let stockCodeLabel = UILabel()
    private let principalLabel = UILabel()
    private let quantityLabel = UILabel()
    private let buyPriceLabel = UILabel() // 买入价（第一行）
    private let sellPriceLabel = UILabel() // 卖出价（第二行，可能与买入价相同）
    private let profitContainer = UIView() // 收益/卖出类型容器
    private let profitLabel = UILabel()
    private let sellTypeLabel = UILabel() // 卖出类型（如"平仓"）
    private let timeLabelLeft = UILabel() // 左侧时间
    private let timeLabelRight = UILabel() // 右侧时间
    private let detailButton = UIButton(type: .system)
    
    var onDetailButtonTapped: (() -> Void)?
    
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
        
        // 表头背景
        let headerContainer = UIView()
        headerContainer.backgroundColor = Constants.Color.backgroundMain
        contentView.addSubview(headerContainer)
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 表头标签
        headerStockLabel.text = "股票/代码"
        headerStockLabel.font = UIFont.systemFont(ofSize: 13)
        headerStockLabel.textColor = Constants.Color.textSecondary
        headerContainer.addSubview(headerStockLabel)
        headerStockLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerPrincipalLabel.text = "本金|数量"
        headerPrincipalLabel.font = UIFont.systemFont(ofSize: 13)
        headerPrincipalLabel.textColor = Constants.Color.textSecondary
        headerPrincipalLabel.textAlignment = .center
        headerContainer.addSubview(headerPrincipalLabel)
        headerPrincipalLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerPriceLabel.text = "买入卖出价"
        headerPriceLabel.font = UIFont.systemFont(ofSize: 13)
        headerPriceLabel.textColor = Constants.Color.textSecondary
        headerPriceLabel.textAlignment = .center
        headerContainer.addSubview(headerPriceLabel)
        headerPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerProfitLabel.text = "收益/卖出类型"
        headerProfitLabel.font = UIFont.systemFont(ofSize: 13)
        headerProfitLabel.textColor = Constants.Color.textSecondary
        headerProfitLabel.textAlignment = .right
        headerContainer.addSubview(headerProfitLabel)
        headerProfitLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票名称
        stockNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        stockNameLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(stockNameLabel)
        stockNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票代码
        stockCodeLabel.font = UIFont.systemFont(ofSize: 12)
        stockCodeLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(stockCodeLabel)
        stockCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 本金容器
        let principalContainer = UIView()
        contentView.addSubview(principalContainer)
        principalContainer.translatesAutoresizingMaskIntoConstraints = false
        
        principalLabel.font = UIFont.systemFont(ofSize: 14)
        principalLabel.textColor = Constants.Color.textPrimary
        principalLabel.textAlignment = .center
        principalContainer.addSubview(principalLabel)
        principalLabel.translatesAutoresizingMaskIntoConstraints = false
        
        quantityLabel.font = UIFont.systemFont(ofSize: 12)
        quantityLabel.textColor = Constants.Color.textSecondary
        quantityLabel.textAlignment = .center
        principalContainer.addSubview(quantityLabel)
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 买入价（第一行）
        buyPriceLabel.font = UIFont.systemFont(ofSize: 14)
        buyPriceLabel.textColor = Constants.Color.textPrimary
        buyPriceLabel.textAlignment = .center
        contentView.addSubview(buyPriceLabel)
        buyPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 卖出价（第二行）
        sellPriceLabel.font = UIFont.systemFont(ofSize: 14)
        sellPriceLabel.textColor = Constants.Color.textPrimary
        sellPriceLabel.textAlignment = .center
        contentView.addSubview(sellPriceLabel)
        sellPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 收益/卖出类型容器（右侧列，上下排列）
        contentView.addSubview(profitContainer)
        profitContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 收益（上，右侧列）
        profitLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        profitLabel.textAlignment = .right
        profitContainer.addSubview(profitLabel)
        profitLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 卖出类型（下，右侧列）
        sellTypeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        sellTypeLabel.textAlignment = .right
        profitContainer.addSubview(sellTypeLabel)
        sellTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 时间标签（左侧）
        timeLabelLeft.font = UIFont.systemFont(ofSize: 11)
        timeLabelLeft.textColor = Constants.Color.textTertiary
        timeLabelLeft.textAlignment = .left
        contentView.addSubview(timeLabelLeft)
        timeLabelLeft.translatesAutoresizingMaskIntoConstraints = false
        
        // 时间标签（右侧）
        timeLabelRight.font = UIFont.systemFont(ofSize: 11)
        timeLabelRight.textColor = Constants.Color.textTertiary
        timeLabelRight.textAlignment = .right
        contentView.addSubview(timeLabelRight)
        timeLabelRight.translatesAutoresizingMaskIntoConstraints = false
        
        // 查看详情按钮
        detailButton.setTitle("查看详情", for: .normal)
        detailButton.setTitleColor(Constants.Color.themeBlue, for: .normal)
        detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        detailButton.layer.borderWidth = 1
        detailButton.layer.borderColor = Constants.Color.themeBlue.cgColor
        detailButton.layer.cornerRadius = 4
        detailButton.addTarget(self, action: #selector(detailButtonTapped), for: .touchUpInside)
        contentView.addSubview(detailButton)
        detailButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 分割线
        let separator = UIView()
        separator.backgroundColor = Constants.Color.separator
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 表头容器
            headerContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 36),
            
            // 表头标签
            headerStockLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            headerStockLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            headerPrincipalLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 100),
            headerPrincipalLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            headerPrincipalLabel.widthAnchor.constraint(equalToConstant: 80),
            
            headerPriceLabel.leadingAnchor.constraint(equalTo: headerPrincipalLabel.trailingAnchor, constant: 8),
            headerPriceLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            headerPriceLabel.widthAnchor.constraint(equalToConstant: 80),
            
            headerProfitLabel.leadingAnchor.constraint(equalTo: headerPriceLabel.trailingAnchor, constant: 8),
            headerProfitLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            headerProfitLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            // 股票名称和代码（左侧）
            stockNameLabel.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 10),
            stockNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stockNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
            
            stockCodeLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: 4),
            stockCodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // 本金|数量（中间左）
            principalContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 10),
            principalContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 100),
            principalContainer.widthAnchor.constraint(equalToConstant: 80),
            principalContainer.heightAnchor.constraint(equalToConstant: 40),
            
            principalLabel.topAnchor.constraint(equalTo: principalContainer.topAnchor),
            principalLabel.leadingAnchor.constraint(equalTo: principalContainer.leadingAnchor),
            principalLabel.trailingAnchor.constraint(equalTo: principalContainer.trailingAnchor),
            
            quantityLabel.topAnchor.constraint(equalTo: principalLabel.bottomAnchor, constant: 4),
            quantityLabel.leadingAnchor.constraint(equalTo: principalContainer.leadingAnchor),
            quantityLabel.trailingAnchor.constraint(equalTo: principalContainer.trailingAnchor),
            quantityLabel.bottomAnchor.constraint(equalTo: principalContainer.bottomAnchor),
            
            // 买入价（第一行，中间列）- 与股票名称和本金对齐
            buyPriceLabel.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 10),
            buyPriceLabel.leadingAnchor.constraint(equalTo: principalContainer.trailingAnchor, constant: 8),
            buyPriceLabel.widthAnchor.constraint(equalToConstant: 80),
            buyPriceLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // 卖出价（第二行，中间列）- 与股票代码和数量对齐
            sellPriceLabel.topAnchor.constraint(equalTo: stockCodeLabel.topAnchor),
            sellPriceLabel.leadingAnchor.constraint(equalTo: principalContainer.trailingAnchor, constant: 8),
            sellPriceLabel.widthAnchor.constraint(equalToConstant: 80),
            sellPriceLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // 收益/卖出类型容器（右侧列，上下排列）
            profitContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 10),
            profitContainer.leadingAnchor.constraint(equalTo: buyPriceLabel.trailingAnchor, constant: 8),
            profitContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            profitContainer.heightAnchor.constraint(equalToConstant: 40),
            
            // 收益（上，第一行）- 与股票名称、本金、买入价对齐
            profitLabel.topAnchor.constraint(equalTo: profitContainer.topAnchor),
            profitLabel.leadingAnchor.constraint(equalTo: profitContainer.leadingAnchor),
            profitLabel.trailingAnchor.constraint(equalTo: profitContainer.trailingAnchor),
            profitLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // 卖出类型（下，第二行）- 与股票代码、数量、卖出价对齐
            sellTypeLabel.topAnchor.constraint(equalTo: profitLabel.bottomAnchor, constant: 4),
            sellTypeLabel.leadingAnchor.constraint(equalTo: profitContainer.leadingAnchor),
            sellTypeLabel.trailingAnchor.constraint(equalTo: profitContainer.trailingAnchor),
            sellTypeLabel.heightAnchor.constraint(equalToConstant: 20),
            sellTypeLabel.bottomAnchor.constraint(equalTo: profitContainer.bottomAnchor),
            
            // 时间标签（底部左右两个，同一行）
            // 使用profitContainer.bottomAnchor作为参考，确保两个时间标签在同一行
            timeLabelLeft.topAnchor.constraint(equalTo: profitContainer.bottomAnchor, constant: 8),
            timeLabelLeft.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabelLeft.heightAnchor.constraint(equalToConstant: 16),
            
            timeLabelRight.topAnchor.constraint(equalTo: profitContainer.bottomAnchor, constant: 8),
            timeLabelRight.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabelRight.heightAnchor.constraint(equalToConstant: 16),
            
            // 查看详情按钮（左右间距15，在时间下方）
            detailButton.topAnchor.constraint(equalTo: timeLabelLeft.bottomAnchor, constant: 10),
            detailButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            detailButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            detailButton.heightAnchor.constraint(equalToConstant: 32),
            
            // 分割线
            separator.topAnchor.constraint(equalTo: detailButton.bottomAnchor, constant: 10),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }
    
    func configure(with holding: HistoricalHolding) {
        stockNameLabel.text = holding.stockName
        stockCodeLabel.text = "沪 \(holding.stockCode)"
        principalLabel.text = String(format: "%.2f", holding.principal)
        quantityLabel.text = "\(holding.quantity)"
        
        // 买入价和卖出价（根据UI图，两行都显示价格）
        buyPriceLabel.text = String(format: "%.2f", holding.buyPrice)
        if let sellPrice = holding.sellPrice {
            sellPriceLabel.text = String(format: "%.2f", sellPrice)
        } else {
            sellPriceLabel.text = String(format: "%.2f", holding.buyPrice) // 如果没有卖出价，显示买入价
        }
        
        // 收益（第一行，右侧）- 可以同时显示收益和卖出类型
        if let profit = holding.profit {
            profitLabel.text = String(format: "%.0f", profit)
            // 根据UI图，亏损显示绿色（-19显示为绿色）
            profitLabel.textColor = profit < 0 ? Constants.Color.stockFall : Constants.Color.stockRise
            profitLabel.isHidden = false
        } else {
            profitLabel.text = ""
            profitLabel.isHidden = true
        }
        
        // 卖出类型（第二行，右侧）- 可以同时显示收益和卖出类型
        if let sellType = holding.sellType {
            sellTypeLabel.text = sellType
            sellTypeLabel.textColor = Constants.Color.stockFall // 平仓显示绿色
            sellTypeLabel.isHidden = false
        } else {
            sellTypeLabel.text = ""
            sellTypeLabel.isHidden = true
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = formatter.string(from: holding.transactionTime)
        timeLabelLeft.text = timeString
        timeLabelRight.text = timeString
    }
    
    @objc private func detailButtonTapped() {
        onDetailButtonTapped?()
    }
}

// MARK: - DateRangePickerViewController
class DateRangePickerViewController: UIViewController {
    
    var startDate: Date = Date()
    var endDate: Date = Date()
    var onDateSelected: ((Date, Date) -> Void)?
    
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "选择日期范围"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "确定", style: .done, target: self, action: #selector(confirmTapped))
        
        let startLabel = UILabel()
        startLabel.text = "开始日期"
        startLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        startLabel.textColor = Constants.Color.textPrimary
        view.addSubview(startLabel)
        startLabel.translatesAutoresizingMaskIntoConstraints = false
        
        startDatePicker.datePickerMode = .date
        startDatePicker.date = startDate
        if #available(iOS 13.4, *) {
            startDatePicker.preferredDatePickerStyle = .wheels
        }
        view.addSubview(startDatePicker)
        startDatePicker.translatesAutoresizingMaskIntoConstraints = false
        
        let endLabel = UILabel()
        endLabel.text = "结束日期"
        endLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        endLabel.textColor = Constants.Color.textPrimary
        view.addSubview(endLabel)
        endLabel.translatesAutoresizingMaskIntoConstraints = false
        
        endDatePicker.datePickerMode = .date
        endDatePicker.date = endDate
        if #available(iOS 13.4, *) {
            endDatePicker.preferredDatePickerStyle = .wheels
        }
        view.addSubview(endDatePicker)
        endDatePicker.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            startLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            startLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            startDatePicker.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 12),
            startDatePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            startDatePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            startDatePicker.heightAnchor.constraint(equalToConstant: 200),
            
            endLabel.topAnchor.constraint(equalTo: startDatePicker.bottomAnchor, constant: 20),
            endLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            endDatePicker.topAnchor.constraint(equalTo: endLabel.bottomAnchor, constant: 12),
            endDatePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            endDatePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            endDatePicker.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func confirmTapped() {
        onDateSelected?(startDatePicker.date, endDatePicker.date)
        dismiss(animated: true)
    }
}

