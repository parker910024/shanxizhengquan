//
//  MyHoldingsViewController.swift
//  zhengqaun
//
//  我的持仓：红底导航+四 Tab（当前持仓/历史持仓/新股持仓/申购记录），表头 名称/代码、市值/数量、现价/买入、盈亏/盈亏比。
//

import UIKit

class MyHoldingsViewController: ZQViewController {

    private let navRed = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var segmentContainer: UIView!
    private var tabButtons: [UIButton] = []
    private var underline: UIView!
    private var underlineLeading: NSLayoutConstraint?
    private var emptyLabel: UILabel!
    private var selectedTabIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupNavigationBar()
        setupSegment()
        setupTableView()
        setupEmptyView()
        loadHoldingsData()
        updateTabSelection(0)
    }

    private func setupNavigationBar() {
        gk_navBackgroundColor = navRed
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "我的持仓"
        gk_navLineHidden = true
        gk_statusBarStyle = .lightContent
        gk_navItemRightSpace = 15
       
    }

    @objc private func searchTapped() {
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func setupSegment() {
        let wrap = UIView()
        wrap.backgroundColor = navRed
        view.addSubview(wrap)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        segmentContainer = wrap

        let titles = ["当前持仓", "历史持仓", "新股持仓", "申购记录"]
        for (i, t) in titles.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(t, for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            btn.tag = i
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            wrap.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
            tabButtons.append(btn)
        }
        underline = UIView()
        underline.backgroundColor = .white
        wrap.addSubview(underline)
        underline.translatesAutoresizingMaskIntoConstraints = false

        let navH = Constants.Navigation.totalNavigationHeight
        let w = Constants.Screen.width / CGFloat(titles.count)
        NSLayoutConstraint.activate([
            wrap.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            wrap.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wrap.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wrap.heightAnchor.constraint(equalToConstant: 44),
            underline.heightAnchor.constraint(equalToConstant: 3),
            underline.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            underline.widthAnchor.constraint(equalToConstant: 24)
        ])
        for (i, btn) in tabButtons.enumerated() {
            NSLayoutConstraint.activate([
                btn.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: w * CGFloat(i)),
                btn.topAnchor.constraint(equalTo: wrap.topAnchor),
                btn.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
                btn.widthAnchor.constraint(equalToConstant: w)
            ])
        }
        underlineLeading = underline.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: (w - 24) / 2)
        underlineLeading?.isActive = true
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let idx = sender.tag
        if idx == selectedTabIndex { return }
        selectedTabIndex = idx
        updateTabSelection(idx)
        let w = segmentContainer.bounds.width / CGFloat(tabButtons.count)
        UIView.animate(withDuration: 0.25) {
            self.underlineLeading?.constant = (w - 24) / 2 + w * CGFloat(idx)
            self.segmentContainer.layoutIfNeeded()
        }
        tableView.reloadData()
        let hasData = (idx == 0 && !holdings.isEmpty) || (idx == 1 && !historicalHoldings.isEmpty)
        emptyLabel.isHidden = hasData
    }

    private func updateTabSelection(_ idx: Int) {
        for (i, btn) in tabButtons.enumerated() {
            btn.titleLabel?.font = i == idx ? UIFont.boldSystemFont(ofSize: 14) : UIFont.systemFont(ofSize: 14)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = segmentContainer.bounds.width / CGFloat(tabButtons.count)
        if w > 0 { underlineLeading?.constant = (w - 24) / 2 + w * CGFloat(selectedTabIndex) }
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.backgroundView = nil
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MyHoldingsHoldingCell.self, forCellReuseIdentifier: "HoldingCell")
        tableView.register(MyHoldingsHistoryRowCell.self, forCellReuseIdentifier: "MyHoldingsHistoryRowCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let navH = Constants.Navigation.totalNavigationHeight
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupEmptyView() {
        emptyLabel = UILabel()
        emptyLabel.text = "没有数据了"
        emptyLabel.font = UIFont.systemFont(ofSize: 15)
        emptyLabel.textColor = Constants.Color.textTertiary
        emptyLabel.textAlignment = .center
        tableView.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 120)
        ])
    }

    // 持仓数据模型
    struct Holding {
        let name: String
        let code: String
        let marketValue: String
        let marketValueDetail: String
        let currentPrice: String
        let currentPriceDetail: String
        let profitLoss: String
        let profitLossPercent: String
    }

    /// 历史持仓单条（左侧竖条「普通交易」+ 名称/交易所/日期左对齐 + 三列数据 + 底部详情/行情/盈利）
    struct HistoricalHolding {
        let typeLabel: String   // "普通交易"
        let name: String       // "N 至信"
        let marketLine: String // "沪 8.75"
        let date: String       // "2026-01-15"
        let marketValue: String
        let quantity: String
        let currentPrice: String
        let buyPrice: String?
        let profitLoss: String
        let profitLossPercent: String
    }
    
    private var holdings: [Holding] = []
    private var historicalHoldings: [HistoricalHolding] = []
    
    private func setupHoldingsHeader() {
        // 表头作为section header
        // 这里不需要单独设置，会在tableView的viewForHeaderInSection中处理
    }
    
    private func loadHoldingsData() {
        // 与工程内大宗/股票数据风格一致的模拟持仓
        holdings = [
            Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "18650",
                marketValueDetail: "500",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "+12820.00",
                profitLossPercent: "219.9%"
            ),
            Holding(
                name: "天润科技",
                code: "京 920564",
                marketValue: "21880",
                marketValueDetail: "1000",
                currentPrice: "21.88",
                currentPriceDetail: "18.00",
                profitLoss: "+3880.00",
                profitLossPercent: "21.56%"
            ),
            Holding(
                name: "中信证券",
                code: "沪 600030",
                marketValue: "25500",
                marketValueDetail: "1500",
                currentPrice: "17.00",
                currentPriceDetail: "16.20",
                profitLoss: "+1200.00",
                profitLossPercent: "4.94%"
            ),
            Holding(
                name: "健信超导",
                code: "沪 688805",
                marketValue: "3716",
                marketValueDetail: "200",
                currentPrice: "18.58",
                currentPriceDetail: "16.50",
                profitLoss: "+416.00",
                profitLossPercent: "12.61%"
            ),
            Holding(
                name: "山西证券",
                code: "深 002500",
                marketValue: "8820",
                marketValueDetail: "1200",
                currentPrice: "7.35",
                currentPriceDetail: "7.10",
                profitLoss: "+300.00",
                profitLossPercent: "3.52%"
            )
        ]
        loadHistoricalData()
        tableView.reloadData()
        emptyLabel.isHidden = !holdings.isEmpty
    }

    private func loadHistoricalData() {
        historicalHoldings = [
            HistoricalHolding(typeLabel: "普通交易", name: "N 至信", marketLine: "沪 8.75", date: "2026-01-15", marketValue: "8.75", quantity: "1800009.039.600.00", currentPrice: "8.75", buyPrice: nil, profitLoss: "8.75", profitLossPercent: "8.75%"),
            HistoricalHolding(typeLabel: "普通交易", name: "N 至信", marketLine: "沪 8.75", date: "2026-01-15", marketValue: "8.75", quantity: "1800009.039.600.00", currentPrice: "8.75", buyPrice: nil, profitLoss: "8.75", profitLossPercent: "8.75%"),
            HistoricalHolding(typeLabel: "普通交易", name: "N 至信", marketLine: "沪 8.75", date: "2026-01-15", marketValue: "8.75", quantity: "1800009.039.600.00", currentPrice: "8.75", buyPrice: nil, profitLoss: "8.75", profitLossPercent: "8.75%")
        ]
    }
}


// MARK: - UITableViewDataSource
extension MyHoldingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        switch selectedTabIndex {
        case 0: return 1
        case 1: return historicalHoldings.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedTabIndex == 0 { return holdings.count }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedTabIndex == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyHoldingsHistoryRowCell", for: indexPath) as! MyHoldingsHistoryRowCell
            cell.configure(with: historicalHoldings[indexPath.section])
            cell.onDetail = { [weak self] in
                let vc = HoldingDetailViewController()
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            cell.onMarket = { [weak self] in
                // 行情
            }
            cell.onProfit = { [weak self] in
                // 盈利
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "HoldingCell", for: indexPath) as! MyHoldingsHoldingCell
        cell.configure(with: holdings[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if selectedTabIndex == 1 {
            if section == 0 {
                return makeColumnHeaderView()
            }
            let spacer = UIView()
            spacer.backgroundColor = .white
            return spacer
        }
        return makeColumnHeaderView()
    }

    private func makeColumnHeaderView() -> UIView {
        let pad = Constants.Spacing.lg
        let header = UIView()
        header.backgroundColor = .white
        
        let gray = Constants.Color.textSecondary
        let nameHeader = UILabel()
        nameHeader.text = "名称/代码"
        nameHeader.font = UIFont.systemFont(ofSize: 14)
        nameHeader.textColor = gray
        nameHeader.textAlignment = .left
        header.addSubview(nameHeader)
        nameHeader.translatesAutoresizingMaskIntoConstraints = false
        
        let marketValueHeader = UILabel()
        marketValueHeader.text = "市值/数量"
        marketValueHeader.font = UIFont.systemFont(ofSize: 14)
        marketValueHeader.textColor = gray
        marketValueHeader.textAlignment = .center
        header.addSubview(marketValueHeader)
        marketValueHeader.translatesAutoresizingMaskIntoConstraints = false
        
        let currentPriceHeader = UILabel()
        currentPriceHeader.text = "现价/买入"
        currentPriceHeader.font = UIFont.systemFont(ofSize: 14)
        currentPriceHeader.textColor = gray
        currentPriceHeader.textAlignment = .center
        header.addSubview(currentPriceHeader)
        currentPriceHeader.translatesAutoresizingMaskIntoConstraints = false
        
        let profitLossHeader = UILabel()
        profitLossHeader.text = "盈亏/盈亏比"
        profitLossHeader.font = UIFont.systemFont(ofSize: 14)
        profitLossHeader.textColor = gray
        profitLossHeader.textAlignment = .right
        header.addSubview(profitLossHeader)
        profitLossHeader.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameHeader.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: pad + 16),
            nameHeader.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            nameHeader.widthAnchor.constraint(equalToConstant: 80),
            
            marketValueHeader.centerXAnchor.constraint(equalTo: header.centerXAnchor, constant: -60),
            marketValueHeader.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            marketValueHeader.widthAnchor.constraint(equalToConstant: 80),
            
            currentPriceHeader.centerXAnchor.constraint(equalTo: header.centerXAnchor, constant: 20),
            currentPriceHeader.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            currentPriceHeader.widthAnchor.constraint(equalToConstant: 80),
            
            profitLossHeader.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -(pad + 16)),
            profitLossHeader.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            profitLossHeader.widthAnchor.constraint(equalToConstant: 80)
        ])
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if selectedTabIndex == 1 {
            return section == 0 ? 44 : 10
        }
        return 44
    }
}

// MARK: - UITableViewDelegate
extension MyHoldingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return selectedTabIndex == 1 ? 88 : 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedTabIndex == 1 { return }
        if selectedTabIndex == 0 {
            let vc = HoldingDetailViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - MyHoldingsHoldingCell
class MyHoldingsHoldingCell: UITableViewCell {
    
    private let containerView = UIView()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let marketValueLabel = UILabel()
    private let marketValueDetailLabel = UILabel()
    private let currentPriceLabel = UILabel()
    private let currentPriceDetailLabel = UILabel()
    private let profitLossLabel = UILabel()
    private let profitLossPercentLabel = UILabel()
    private let separatorLine = UIView()
    
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
        
        containerView.backgroundColor = Constants.Color.backgroundWhite
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 名称列（左对齐）- 缩小字体
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = Constants.Color.textPrimary
        nameLabel.textAlignment = .left
        containerView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = Constants.Color.textSecondary
        codeLabel.textAlignment = .left
        containerView.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 持仓市值列（居中）- 缩小字体
        marketValueLabel.font = UIFont.systemFont(ofSize: 15)
        marketValueLabel.textColor = Constants.Color.textPrimary
        marketValueLabel.textAlignment = .center
        containerView.addSubview(marketValueLabel)
        marketValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        marketValueDetailLabel.font = UIFont.systemFont(ofSize: 12)
        marketValueDetailLabel.textColor = Constants.Color.textSecondary
        marketValueDetailLabel.textAlignment = .center
        containerView.addSubview(marketValueDetailLabel)
        marketValueDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 现价成本列（居中）- 缩小字体
        currentPriceLabel.font = UIFont.systemFont(ofSize: 15)
        currentPriceLabel.textColor = Constants.Color.textPrimary
        currentPriceLabel.textAlignment = .center
        containerView.addSubview(currentPriceLabel)
        currentPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        currentPriceDetailLabel.font = UIFont.systemFont(ofSize: 12)
        currentPriceDetailLabel.textColor = Constants.Color.textSecondary
        currentPriceDetailLabel.textAlignment = .center
        containerView.addSubview(currentPriceDetailLabel)
        currentPriceDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 盈亏涨幅列（右对齐）- 缩小字体
        profitLossLabel.font = UIFont.boldSystemFont(ofSize: 15)
        profitLossLabel.textColor = Constants.Color.stockRise // 红色
        profitLossLabel.textAlignment = .right
        containerView.addSubview(profitLossLabel)
        profitLossLabel.translatesAutoresizingMaskIntoConstraints = false
        
        profitLossPercentLabel.font = UIFont.systemFont(ofSize: 12)
        profitLossPercentLabel.textColor = Constants.Color.stockRise // 红色
        profitLossPercentLabel.textAlignment = .right
        containerView.addSubview(profitLossPercentLabel)
        profitLossPercentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 分隔线
        separatorLine.backgroundColor = Constants.Color.separator
        containerView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // 第一行 - 缩小间距
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.widthAnchor.constraint(equalToConstant: 80),
            
            marketValueLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            marketValueLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -60),
            marketValueLabel.widthAnchor.constraint(equalToConstant: 80),
            
            currentPriceLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            currentPriceLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 20),
            currentPriceLabel.widthAnchor.constraint(equalToConstant: 80),
            
            profitLossLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            profitLossLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            profitLossLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // 第二行 - 缩小间距
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            codeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            codeLabel.widthAnchor.constraint(equalToConstant: 80),
            
            marketValueDetailLabel.topAnchor.constraint(equalTo: marketValueLabel.bottomAnchor, constant: 4),
            marketValueDetailLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -60),
            marketValueDetailLabel.widthAnchor.constraint(equalToConstant: 80),
            
            currentPriceDetailLabel.topAnchor.constraint(equalTo: currentPriceLabel.bottomAnchor, constant: 4),
            currentPriceDetailLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 20),
            currentPriceDetailLabel.widthAnchor.constraint(equalToConstant: 80),
            
            profitLossPercentLabel.topAnchor.constraint(equalTo: profitLossLabel.bottomAnchor, constant: 4),
            profitLossPercentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            profitLossPercentLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // 分隔线 - 缩小间距
            separatorLine.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 8),
            separatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            separatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separatorLine.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separatorLine.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with holding: MyHoldingsViewController.Holding) {
        nameLabel.text = holding.name
        codeLabel.text = holding.code
        marketValueLabel.text = holding.marketValue
        marketValueDetailLabel.text = holding.marketValueDetail
        currentPriceLabel.text = holding.currentPrice
        currentPriceDetailLabel.text = holding.currentPriceDetail
        profitLossLabel.text = holding.profitLoss
        profitLossPercentLabel.text = holding.profitLossPercent
        let isRise = holding.profitLoss.hasPrefix("+") || (!holding.profitLoss.hasPrefix("-") && Double(holding.profitLoss.replacingOccurrences(of: ",", with: "")) ?? 0 >= 0)
        let plColor = isRise ? Constants.Color.stockRise : Constants.Color.stockFall
        profitLossLabel.textColor = plColor
        profitLossPercentLabel.textColor = plColor
    }
}

// MARK: - 历史持仓行 Cell：左侧竖条与 cell 同高、文字从上往下；右侧三行上中下排列且整体垂直居中
class MyHoldingsHistoryRowCell: UITableViewCell {

    private let typeTagView = UIView()
    private let typeTagLabel = UILabel()
    private let contentBlock = UIView()
    private let nameLabel = UILabel()
    private let exchangeBadge = UILabel()
    private let marketPriceLabel = UILabel()
    private let dateLabel = UILabel()
    private let marketValueLabel = UILabel()
    private let quantityLabel = UILabel()
    private let currentPriceLabel = UILabel()
    private let buyPriceLabel = UILabel()
    private let profitLossLabel = UILabel()
    private let profitLossPercentLabel = UILabel()
    private let detailButton = UIButton(type: .system)
    private let marketButton = UIButton(type: .system)
    private let profitButton = UIButton(type: .system)

    var onDetail: (() -> Void)?
    var onMarket: (() -> Void)?
    var onProfit: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white

        // 左侧竖条：高度与 cell 一致，文字从上往下（普→通→交→易）
        typeTagView.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        typeTagView.layer.cornerRadius = 2
        contentView.addSubview(typeTagView)
        typeTagView.translatesAutoresizingMaskIntoConstraints = false

        typeTagLabel.text = "普通交易"
        typeTagLabel.font = UIFont.systemFont(ofSize: 12)
        typeTagLabel.textColor = .white
        typeTagLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        typeTagView.addSubview(typeTagLabel)
        typeTagLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentBlock)
        contentBlock.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = Constants.Color.textPrimary
        contentBlock.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        exchangeBadge.font = UIFont.systemFont(ofSize: 10)
        exchangeBadge.textColor = .white
        exchangeBadge.backgroundColor = Constants.Color.stockRise
        exchangeBadge.layer.cornerRadius = 2
        exchangeBadge.clipsToBounds = true
        exchangeBadge.textAlignment = .center
        contentBlock.addSubview(exchangeBadge)
        exchangeBadge.translatesAutoresizingMaskIntoConstraints = false

        marketPriceLabel.font = UIFont.systemFont(ofSize: 12)
        marketPriceLabel.textColor = Constants.Color.textPrimary
        contentBlock.addSubview(marketPriceLabel)
        marketPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = Constants.Color.textTertiary
        contentBlock.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        marketValueLabel.font = UIFont.boldSystemFont(ofSize: 14)
        marketValueLabel.textColor = Constants.Color.textPrimary
        marketValueLabel.textAlignment = .left
        contentBlock.addSubview(marketValueLabel)
        marketValueLabel.translatesAutoresizingMaskIntoConstraints = false

        quantityLabel.font = UIFont.systemFont(ofSize: 12)
        quantityLabel.textColor = Constants.Color.textSecondary
        quantityLabel.textAlignment = .left
        contentBlock.addSubview(quantityLabel)
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false

        currentPriceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        currentPriceLabel.textColor = Constants.Color.textPrimary
        currentPriceLabel.textAlignment = .left
        contentBlock.addSubview(currentPriceLabel)
        currentPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        buyPriceLabel.font = UIFont.systemFont(ofSize: 12)
        buyPriceLabel.textColor = Constants.Color.textSecondary
        buyPriceLabel.textAlignment = .left
        contentBlock.addSubview(buyPriceLabel)
        buyPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        profitLossLabel.font = UIFont.boldSystemFont(ofSize: 14)
        profitLossLabel.textColor = Constants.Color.stockRise
        profitLossLabel.textAlignment = .right
        contentBlock.addSubview(profitLossLabel)
        profitLossLabel.translatesAutoresizingMaskIntoConstraints = false

        profitLossPercentLabel.font = UIFont.systemFont(ofSize: 12)
        profitLossPercentLabel.textColor = Constants.Color.stockRise
        profitLossPercentLabel.textAlignment = .right
        contentBlock.addSubview(profitLossPercentLabel)
        profitLossPercentLabel.translatesAutoresizingMaskIntoConstraints = false

        detailButton.setTitle("详情", for: .normal)
        detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        detailButton.setTitleColor(UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0), for: .normal)
        detailButton.backgroundColor = .white
        detailButton.layer.cornerRadius = 4
        detailButton.layer.borderWidth = 1
        detailButton.layer.borderColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0).cgColor
        detailButton.addTarget(self, action: #selector(detailTapped), for: .touchUpInside)
        contentBlock.addSubview(detailButton)
        detailButton.translatesAutoresizingMaskIntoConstraints = false

        marketButton.setTitle("行情", for: .normal)
        marketButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        marketButton.setTitleColor(UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0), for: .normal)
        marketButton.backgroundColor = .white
        marketButton.layer.cornerRadius = 4
        marketButton.layer.borderWidth = 1
        marketButton.layer.borderColor = UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0).cgColor
        marketButton.addTarget(self, action: #selector(marketTapped), for: .touchUpInside)
        contentBlock.addSubview(marketButton)
        marketButton.translatesAutoresizingMaskIntoConstraints = false

        profitButton.setTitle("盈利", for: .normal)
        profitButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        profitButton.setTitleColor(UIColor(red: 0.7, green: 0.35, blue: 0.2, alpha: 1.0), for: .normal)
        profitButton.backgroundColor = .white
        profitButton.layer.cornerRadius = 4
        profitButton.layer.borderWidth = 1
        profitButton.layer.borderColor = UIColor(red: 0.7, green: 0.35, blue: 0.2, alpha: 1.0).cgColor
        profitButton.addTarget(self, action: #selector(profitTapped), for: .touchUpInside)
        contentBlock.addSubview(profitButton)
        profitButton.translatesAutoresizingMaskIntoConstraints = false

        let rowGap: CGFloat = 6
        let col1Leading: CGFloat = 0
        let col2CenterX: CGFloat = -58
        let col3CenterX: CGFloat = 22
        let colWidth: CGFloat = 70
        let vPadding: CGFloat = 4
        let row2Height: CGFloat = 14

        NSLayoutConstraint.activate([
            typeTagView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            typeTagView.topAnchor.constraint(equalTo: contentView.topAnchor),
            typeTagView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            typeTagView.widthAnchor.constraint(equalToConstant: 26),

            typeTagLabel.centerXAnchor.constraint(equalTo: typeTagView.centerXAnchor),
            typeTagLabel.centerYAnchor.constraint(equalTo: typeTagView.centerYAnchor),
            typeTagLabel.widthAnchor.constraint(equalToConstant: 52),
            typeTagLabel.heightAnchor.constraint(equalToConstant: 20),

            contentBlock.leadingAnchor.constraint(equalTo: typeTagView.trailingAnchor, constant: 10),
            contentBlock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentBlock.topAnchor.constraint(equalTo: contentView.topAnchor, constant: vPadding),
            contentBlock.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -vPadding),

            // 第一行：名称、市值、现价、盈亏 — 顶对齐
            nameLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor, constant: col1Leading),

            marketValueLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            marketValueLabel.centerXAnchor.constraint(equalTo: contentBlock.centerXAnchor, constant: col2CenterX),
            marketValueLabel.widthAnchor.constraint(equalToConstant: colWidth),

            currentPriceLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            currentPriceLabel.centerXAnchor.constraint(equalTo: contentBlock.centerXAnchor, constant: col3CenterX),
            currentPriceLabel.widthAnchor.constraint(equalToConstant: colWidth),

            profitLossLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            profitLossLabel.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            profitLossLabel.widthAnchor.constraint(equalToConstant: colWidth),

            // 第二行：交易所+市价、数量、买入价、盈亏% — 统一顶对齐到 nameLabel.bottom + rowGap
            exchangeBadge.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor, constant: col1Leading),
            exchangeBadge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: rowGap),
            exchangeBadge.widthAnchor.constraint(equalToConstant: 16),
            exchangeBadge.heightAnchor.constraint(equalToConstant: row2Height),

            marketPriceLabel.leadingAnchor.constraint(equalTo: exchangeBadge.trailingAnchor, constant: 4),
            marketPriceLabel.centerYAnchor.constraint(equalTo: exchangeBadge.centerYAnchor),

            quantityLabel.topAnchor.constraint(equalTo: exchangeBadge.topAnchor),
            quantityLabel.centerXAnchor.constraint(equalTo: marketValueLabel.centerXAnchor),
            quantityLabel.widthAnchor.constraint(equalTo: marketValueLabel.widthAnchor),

            buyPriceLabel.topAnchor.constraint(equalTo: exchangeBadge.topAnchor),
            buyPriceLabel.centerXAnchor.constraint(equalTo: currentPriceLabel.centerXAnchor),
            buyPriceLabel.widthAnchor.constraint(equalTo: currentPriceLabel.widthAnchor),

            profitLossPercentLabel.topAnchor.constraint(equalTo: exchangeBadge.topAnchor),
            profitLossPercentLabel.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            profitLossPercentLabel.widthAnchor.constraint(equalTo: profitLossLabel.widthAnchor),
            profitLossPercentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: row2Height),

            // 第三行：日期 + 详情/行情/盈利 — 统一顶对齐到第二行下方 rowGap
            detailButton.leadingAnchor.constraint(equalTo: contentBlock.trailingAnchor, constant: -(56*3 + 10*2)),
            detailButton.topAnchor.constraint(equalTo: exchangeBadge.bottomAnchor, constant: rowGap),
            detailButton.topAnchor.constraint(greaterThanOrEqualTo: profitLossPercentLabel.bottomAnchor, constant: rowGap),
            detailButton.widthAnchor.constraint(equalToConstant: 52),
            detailButton.heightAnchor.constraint(equalToConstant: 22),

            dateLabel.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor, constant: col1Leading),
            dateLabel.centerYAnchor.constraint(equalTo: detailButton.centerYAnchor),
            dateLabel.topAnchor.constraint(greaterThanOrEqualTo: exchangeBadge.bottomAnchor, constant: rowGap),

            marketButton.leadingAnchor.constraint(equalTo: detailButton.trailingAnchor, constant: 10),
            marketButton.centerYAnchor.constraint(equalTo: detailButton.centerYAnchor),
            marketButton.widthAnchor.constraint(equalToConstant: 52),
            marketButton.heightAnchor.constraint(equalToConstant: 22),

            profitButton.leadingAnchor.constraint(equalTo: marketButton.trailingAnchor, constant: 10),
            profitButton.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            profitButton.centerYAnchor.constraint(equalTo: detailButton.centerYAnchor),
            profitButton.widthAnchor.constraint(equalToConstant: 52),
            profitButton.heightAnchor.constraint(equalToConstant: 22),

            contentBlock.bottomAnchor.constraint(equalTo: detailButton.bottomAnchor),

            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: marketValueLabel.leadingAnchor, constant: -8),
            marketPriceLabel.trailingAnchor.constraint(lessThanOrEqualTo: quantityLabel.leadingAnchor, constant: -8)
        ])
    }

    @objc private func detailTapped() { onDetail?() }
    @objc private func marketTapped() { onMarket?() }
    @objc private func profitTapped() { onProfit?() }

    func configure(with item: MyHoldingsViewController.HistoricalHolding) {
        typeTagLabel.text = item.typeLabel
        nameLabel.text = item.name
        let parts = item.marketLine.split(separator: " ", maxSplits: 1)
        if parts.count >= 2 {
            exchangeBadge.text = String(parts[0])
            marketPriceLabel.text = String(parts[1])
        } else {
            exchangeBadge.text = ""
            marketPriceLabel.text = item.marketLine
        }
        dateLabel.text = item.date
        marketValueLabel.text = item.marketValue
        quantityLabel.text = item.quantity
        currentPriceLabel.text = item.currentPrice
        buyPriceLabel.text = item.buyPrice ?? ""
        profitLossLabel.text = item.profitLoss
        profitLossPercentLabel.text = item.profitLossPercent
    }
}

