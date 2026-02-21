//
//  TradeViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class TradeViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var accountCard: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 更新tableHeaderView的宽度和高度
        if let headerView = tableView.tableHeaderView {
            let width = tableView.bounds.width
            if width > 0 && headerView.frame.size.width != width {
                headerView.frame.size.width = width
                headerView.layoutIfNeeded()
                let size = headerView.systemLayoutSizeFitting(
                    CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                )
                if headerView.frame.size.height != size.height {
                    headerView.frame.size.height = size.height
                    tableView.tableHeaderView = headerView
                }
            }
        }
    }

    private func setupUI() {
        view.backgroundColor = Constants.Color.backgroundMain

        setupNavigationBar()
        setupTableView()
        setupAccountCard()
        setupHoldingsHeader()
        loadHoldingsData()
    }

    private func setupNavigationBar() {
        gk_navBackgroundColor = Constants.Color.themeBlue
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "交易账户"
        gk_navLineHidden = true
        gk_navItemRightSpace = 15

        let searchBtn = UIButton(type: .system)
        searchBtn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchBtn.tintColor = .white
        searchBtn.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        gk_navRightBarButtonItem = UIBarButtonItem(customView: searchBtn)
    }

    @objc private func searchTapped() {
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = Constants.Color.backgroundMain
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(HoldingCell.self, forCellReuseIdentifier: "HoldingCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight + 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupAccountCard() {
        let card = UIView()
        card.backgroundColor = Constants.Color.backgroundWhite
        card.layer.cornerRadius = 12
        if #available(iOS 11.0, *) {
            card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        accountCard = card

        let pad = Constants.Spacing.lg
        let padLg: CGFloat = 20

        // 总资产 (元)
        let titleLabel = UILabel()
        titleLabel.text = "总资产 (元)"
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = Constants.Color.textSecondary
        card.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // ¥ 6946.39
        let amountLabel = UILabel()
        amountLabel.text = "¥ 6946.39"
        amountLabel.font = UIFont.boldSystemFont(ofSize: 30)
        amountLabel.textColor = Constants.Color.textPrimary
        card.addSubview(amountLabel)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        // 5 项网格：3 列，第 1 行 3 个，第 2 行 2 个与前列对齐
        // 列1: 现金可用、交易市值 | 列2: 持仓盈亏、交易盈亏 | 列3: 现金可取（与持仓盈亏整体等高，底部加占位）
        let metrics: [(String, String)] = [
            ("现金可用", "¥ 6946.39"),
            ("持仓盈亏", "¥ 0.00"),
            ("现金可取", "¥ 6946.39"),
            ("交易市值", "¥ 0.00"),
            ("交易盈亏", "¥ 0.00")
        ]
        let col1 = makeMetricColumn(items: [(metrics[0].0, metrics[0].1), (metrics[3].0, metrics[3].1)])
        let col2 = makeMetricColumn(items: [(metrics[1].0, metrics[1].1), (metrics[4].0, metrics[4].1)])
        let col3 = makeMetricColumnWithSpacer(topItem: (metrics[2].0, metrics[2].1), spacing: 12)

        let grid = UIStackView(arrangedSubviews: [col1, col2, col3])
        grid.axis = .horizontal
        grid.distribution = .fillEqually
        grid.spacing = 0
        card.addSubview(grid)
        grid.translatesAutoresizingMaskIntoConstraints = false

        // 设置card内部的约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: padLg),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: padLg),

            amountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: padLg),

            grid.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: padLg),
            grid.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: padLg),
            grid.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -padLg),
            grid.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -padLg)
        ])
        
        // 创建一个包装视图作为headerView，card作为子视图
        let headerContainer = UIView()
        headerContainer.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            card.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: pad),
            card.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -pad),
            card.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor)
        ])
        
        // 设置初始frame并计算高度
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        headerContainer.layoutIfNeeded()
        
        let headerHeight = headerContainer.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        
        headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: headerHeight)
        tableView.tableHeaderView = headerContainer
    }

    private func makeMetricColumn(items: [(String, String)]) -> UIView {
        let col = UIStackView()
        col.axis = .vertical
        col.spacing = 12
        col.alignment = .leading

        for (t, v) in items {
            let vw = makeMetricItem(title: t, value: v)
            col.addArrangedSubview(vw)
        }
        return col
    }

    /// 单行指标列 + 底部占位，使整列高度与「持仓盈亏」两行模块一致，上下对齐
    private func makeMetricColumnWithSpacer(topItem: (String, String), spacing: CGFloat) -> UIView {
        let col = UIStackView()
        col.axis = .vertical
        col.spacing = spacing
        col.alignment = .leading

        col.addArrangedSubview(makeMetricItem(title: topItem.0, value: topItem.1))

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        // 占位高度 ≈ 一个 makeMetricItem（与「交易盈亏」单行等高），使整列与「持仓盈亏」两行模块同高
        spacer.heightAnchor.constraint(equalToConstant: 36).isActive = true
        col.addArrangedSubview(spacer)

        return col
    }

    private func makeMetricItem(title: String, value: String) -> UIView {
        let c = UIView()
        let tl = UILabel()
        tl.text = title
        tl.font = UIFont.systemFont(ofSize: 13)
        tl.textColor = Constants.Color.textSecondary
        c.addSubview(tl)
        tl.translatesAutoresizingMaskIntoConstraints = false

        let vl = UILabel()
        vl.text = value
        vl.font = UIFont.systemFont(ofSize: 15)
        vl.textColor = Constants.Color.textPrimary
        c.addSubview(vl)
        vl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tl.topAnchor.constraint(equalTo: c.topAnchor),
            tl.leadingAnchor.constraint(equalTo: c.leadingAnchor),
            vl.topAnchor.constraint(equalTo: tl.bottomAnchor, constant: 4),
            vl.leadingAnchor.constraint(equalTo: c.leadingAnchor),
            vl.bottomAnchor.constraint(equalTo: c.bottomAnchor)
        ])
        return c
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
    
    private var holdings: [Holding] = []
    
    private func setupHoldingsHeader() {
        // 表头作为section header
        // 这里不需要单独设置，会在tableView的viewForHeaderInSection中处理
    }
    
    private func loadHoldingsData() {
        // 模拟数据
        holdings = [
            Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "219.9%"
            ),
            Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "219.9%"
            ),Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "219.9%"
            ),
            Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "219.9%"
            ),Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "219.9%"
            ),
            Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "219.9%"
            ),Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "219.9%"
            ),
            Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "219.9%"
            ),Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "219.9%"
            ),
            Holding(
                name: "科马材料",
                code: "北 920086",
                marketValue: "500",
                marketValueDetail: "18650",
                currentPrice: "37.30",
                currentPriceDetail: "11.66",
                profitLoss: "12820.00",
                profitLossPercent: "300.9%"
            )
        ]
        tableView.reloadData()
        
    }
    
}

// MARK: - UITableViewDataSource
extension TradeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return holdings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HoldingCell", for: indexPath) as! HoldingCell
        cell.configure(with: holdings[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let pad = Constants.Spacing.lg
        let header = UIView()
        header.backgroundColor = Constants.Color.backgroundMain
        
        let nameHeader = UILabel()
        nameHeader.text = "名称"
        nameHeader.font = UIFont.systemFont(ofSize: 14)
        nameHeader.textColor = Constants.Color.textPrimary
        nameHeader.textAlignment = .left
        header.addSubview(nameHeader)
        nameHeader.translatesAutoresizingMaskIntoConstraints = false
        
        let marketValueHeader = UILabel()
        marketValueHeader.text = "持仓市值"
        marketValueHeader.font = UIFont.systemFont(ofSize: 14)
        marketValueHeader.textColor = Constants.Color.textPrimary
        marketValueHeader.textAlignment = .center
        header.addSubview(marketValueHeader)
        marketValueHeader.translatesAutoresizingMaskIntoConstraints = false
        
        let currentPriceHeader = UILabel()
        currentPriceHeader.text = "现价成本"
        currentPriceHeader.font = UIFont.systemFont(ofSize: 14)
        currentPriceHeader.textColor = Constants.Color.textPrimary
        currentPriceHeader.textAlignment = .center
        header.addSubview(currentPriceHeader)
        currentPriceHeader.translatesAutoresizingMaskIntoConstraints = false
        
        let profitLossHeader = UILabel()
        profitLossHeader.text = "盈亏涨幅"
        profitLossHeader.font = UIFont.systemFont(ofSize: 14)
        profitLossHeader.textColor = Constants.Color.textPrimary
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
        return 44
    }
}

// MARK: - UITableViewDelegate
extension TradeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 跳转到持仓详情页面
        let vc = HoldingDetailViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - HoldingCell
class HoldingCell: UITableViewCell {
    
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
    
    func configure(with holding: TradeViewController.Holding) {
        nameLabel.text = holding.name
        codeLabel.text = holding.code
        marketValueLabel.text = holding.marketValue
        marketValueDetailLabel.text = holding.marketValueDetail
        currentPriceLabel.text = holding.currentPrice
        currentPriceDetailLabel.text = holding.currentPriceDetail
        profitLossLabel.text = holding.profitLoss
        profitLossPercentLabel.text = holding.profitLossPercent
    }
}
