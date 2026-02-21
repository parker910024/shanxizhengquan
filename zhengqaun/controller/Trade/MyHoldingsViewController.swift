//
//  MyHoldingsViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class MyHoldingsViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = Constants.Color.backgroundMain

        setupNavigationBar()
        setupTableView()
        setupHoldingsHeader()
        loadHoldingsData()
    }

    private func setupNavigationBar() {
        gk_navBackgroundColor = Constants.Color.themeBlue
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "我的持仓"
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
        tableView.register(MyHoldingsHoldingCell.self, forCellReuseIdentifier: "HoldingCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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
extension MyHoldingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return holdings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HoldingCell", for: indexPath) as! MyHoldingsHoldingCell
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
extension MyHoldingsViewController: UITableViewDelegate {
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
    }
}

