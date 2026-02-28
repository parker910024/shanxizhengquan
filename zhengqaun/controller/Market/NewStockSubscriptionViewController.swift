//
//  NewStockSubscriptionViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// 新股申购数据模型
struct NewStockSubscription {
    let id: String
    let stockName: String      // 股票名称，如"舒泰神"
    let stockCode: String      // 股票代码，如"300204"
    let exchange: String        // 交易所标识，如"深"、"沪"
    let issuePrice: String      // 发行价格，如"¥21.93"
    let winningRate: String     // 中签率，如"0.00%"
    let totalIssued: String    // 发行总数，如"3671.6万股"
}

class NewStockSubscriptionViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let navBlue = UIColor(red: 26/255, green: 81/255, blue: 185/255, alpha: 1.0) // #1A51B9
    
    // 数据源
    private var stocks: [NewStockSubscription] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTableView()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "新股申购"
        gk_navLineHidden = false
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
        gk_backStyle = .black
        
        // 右侧"申购记录"按钮
        let recordButton = UIButton(type: .system)
        recordButton.setTitle("申购记录", for: .normal)
        recordButton.setTitleColor(Constants.Color.textPrimary, for: .normal)
        recordButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        gk_navRightBarButtonItem = UIBarButtonItem(customView: recordButton)
    }
    
    @objc private func recordButtonTapped() {
        // 跳转到申购记录页面（我的新股页面）
        let vc = MyNewStocksViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor,constant: Constants.Navigation.totalNavigationHeight + 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 注册Cell
        tableView.register(NewStockSubscriptionCell.self, forCellReuseIdentifier: "NewStockSubscriptionCell")
    }
    
    private func loadData() {
        SecureNetworkManager.shared.request(
            api: Api.subscribe_api,
            method: .get,
            params: ["page": "1", "type": "0"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.stocks = []
                        self.tableView.reloadData()
                    }
                    return
                }
                
                var newStocks: [NewStockSubscription] = []
                for item in list {
                    // 真实数据可能包在 sub_info 的第一项里，也可能直接在 item 中
                    let realItem: [String: Any]
                    if let subInfoArr = item["sub_info"] as? [[String: Any]],
                       let first = subInfoArr.first {
                        realItem = first
                    } else {
                        // 容错：直接从 item 中解析
                        realItem = item
                    }
                    
                    let idStr = "\(realItem["id"] ?? "")"
                    let name = realItem["name"] as? String ?? (realItem["title"] as? String ?? "")
                    let code = realItem["sgcode"] as? String ?? (realItem["code"] as? String ?? "")
                    
                    // 跳过无效数据
                    guard !name.isEmpty || !code.isEmpty else { continue }
                    
                    let fx_price = realItem["fx_price"]
                    let cai_buy  = realItem["cai_buy"]
                    let priceVal = fx_price != nil ? "\(fx_price!)" : (cai_buy != nil ? "\(cai_buy!)" : "0")
                    
                    let winningRate = "\(realItem["zq_rate"] ?? "0.00")%"
                    
                    // 发行总数
                    let fxNum = realItem["fx_num"]
                    var fxNumStr = "0万股"
                    if let fxNumInt = fxNum as? Int {
                        fxNumStr = String(format: "%.1f万股", Double(fxNumInt) / 10000.0)
                    } else if let fxNumStrVal = fxNum as? String, let doubleVal = Double(fxNumStrVal) {
                        fxNumStr = String(format: "%.1f万股", doubleVal / 10000.0)
                    } else if fxNum != nil {
                        fxNumStr = "\(fxNum!)"
                    }
                    
                    let sgTypeStr: String
                    if let typeInt = realItem["sg_type"] as? Int {
                        sgTypeStr = "\(typeInt)"
                    } else if let typeStr = realItem["sg_type"] as? String {
                        sgTypeStr = typeStr
                    } else {
                        sgTypeStr = "\(realItem["type"] ?? "")"
                    }
                    
                    let market: String = {
                        switch sgTypeStr { case "1": return "沪"; case "2": return "深"; case "3": return "创"; case "4": return "北"; case "5": return "科"; default: return "沪" }
                    }()
                    
                    let model = NewStockSubscription(
                        id: idStr,
                        stockName: name,
                        stockCode: code,
                        exchange: market,
                        issuePrice: "¥\(priceVal)",
                        winningRate: winningRate,
                        totalIssued: fxNumStr
                    )
                    newStocks.append(model)
                }
                
                DispatchQueue.main.async {
                    self.stocks = newStocks
                    self.tableView.reloadData()
                    Toast.show("加载成功")
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    Toast.show("加载数据失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension NewStockSubscriptionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewStockSubscriptionCell", for: indexPath) as! NewStockSubscriptionCell
        cell.configure(with: stocks[indexPath.row])
        cell.onDetailTapped = { [weak self] stock in
            let detailVC = NewStockDetailViewController()
            detailVC.stockId = stock.id
            self?.navigationController?.pushViewController(detailVC, animated: true)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension NewStockSubscriptionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - NewStockSubscriptionCell
class NewStockSubscriptionCell: UITableViewCell {
    
    private let cardView = UIView()
    private let exchangeIcon = UIView()
    private let exchangeLabel = UILabel()
    private let stockNameLabel = UILabel()
    private let stockCodeLabel = UILabel()
    private let detailButton = UIButton(type: .system)
    
    private let priceContainer = UIView()
    private let priceLabel = UILabel()
    private let priceDescLabel = UILabel()
    
    private let rateContainer = UIView()
    private let rateLabel = UILabel()
    private let rateDescLabel = UILabel()
    
    private let totalContainer = UIView()
    private let totalLabel = UILabel()
    private let totalDescLabel = UILabel()
    
    var onDetailTapped: ((NewStockSubscription) -> Void)?
    private var stock: NewStockSubscription?
    
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
        contentView.backgroundColor = .white
        
        // 卡片容器
        cardView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.5) // 浅灰色背景
        cardView.layer.cornerRadius = 8
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // 交易所图标（蓝色方块）
        exchangeIcon.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // 蓝色
        exchangeIcon.layer.cornerRadius = 4
        cardView.addSubview(exchangeIcon)
        exchangeIcon.translatesAutoresizingMaskIntoConstraints = false
        
        exchangeLabel.text = "深"
        exchangeLabel.font = UIFont.boldSystemFont(ofSize: 12)
        exchangeLabel.textColor = .white
        exchangeLabel.textAlignment = .center
        exchangeIcon.addSubview(exchangeLabel)
        exchangeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票名称和代码
        stockNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        stockNameLabel.textColor = .black
        cardView.addSubview(stockNameLabel)
        stockNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stockCodeLabel.font = UIFont.systemFont(ofSize: 13)
        stockCodeLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        cardView.addSubview(stockCodeLabel)
        stockCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 详情按钮
        detailButton.setTitle("详情+", for: .normal)
        detailButton.setTitleColor(Constants.Color.stockRise, for: .normal)
        detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        detailButton.addTarget(self, action: #selector(detailButtonTapped), for: .touchUpInside)
        cardView.addSubview(detailButton)
        detailButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 价格容器
        setupDataContainer(priceContainer, valueLabel: priceLabel, descLabel: priceDescLabel, in: cardView)
        priceDescLabel.text = "发行价格"
        
        // 中签率容器
        setupDataContainer(rateContainer, valueLabel: rateLabel, descLabel: rateDescLabel, in: cardView)
        rateDescLabel.text = "中签率"
        
        // 发行总数容器
        setupDataContainer(totalContainer, valueLabel: totalLabel, descLabel: totalDescLabel, in: cardView)
        totalDescLabel.text = "发行总数"
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 卡片
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // 交易所图标
            exchangeIcon.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            exchangeIcon.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            exchangeIcon.widthAnchor.constraint(equalToConstant: 24),
            exchangeIcon.heightAnchor.constraint(equalToConstant: 24),
            
            exchangeLabel.centerXAnchor.constraint(equalTo: exchangeIcon.centerXAnchor),
            exchangeLabel.centerYAnchor.constraint(equalTo: exchangeIcon.centerYAnchor),
            
            // 股票名称
            stockNameLabel.leadingAnchor.constraint(equalTo: exchangeIcon.trailingAnchor, constant: 8),
            stockNameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            
            // 股票代码
            stockCodeLabel.leadingAnchor.constraint(equalTo: stockNameLabel.leadingAnchor),
            stockCodeLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: 4),
            
            // 详情按钮
            detailButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            detailButton.centerYAnchor.constraint(equalTo: exchangeIcon.centerYAnchor),
            
            // 价格容器
            priceContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            priceContainer.topAnchor.constraint(equalTo: stockCodeLabel.bottomAnchor, constant: 16),
            priceContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            // 中签率容器
            rateContainer.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            rateContainer.topAnchor.constraint(equalTo: priceContainer.topAnchor),
            rateContainer.bottomAnchor.constraint(equalTo: priceContainer.bottomAnchor),
            
            // 发行总数容器
            totalContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            totalContainer.topAnchor.constraint(equalTo: priceContainer.topAnchor),
            totalContainer.bottomAnchor.constraint(equalTo: priceContainer.bottomAnchor),
            
            // 三个容器等宽
            priceContainer.widthAnchor.constraint(equalTo: rateContainer.widthAnchor),
            rateContainer.widthAnchor.constraint(equalTo: totalContainer.widthAnchor)
        ])
    }
    
    private func setupDataContainer(_ container: UIView, valueLabel: UILabel, descLabel: UILabel, in parent: UIView) {
        parent.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        valueLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        valueLabel.textColor = .black
        valueLabel.textAlignment = .center
        container.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        descLabel.textAlignment = .center
        container.addSubview(descLabel)
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            descLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 6),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            descLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    func configure(with stock: NewStockSubscription) {
        self.stock = stock
        
        exchangeLabel.text = stock.exchange
        stockNameLabel.text = stock.stockName
        stockCodeLabel.text = stock.stockCode
        priceLabel.text = stock.issuePrice
        rateLabel.text = stock.winningRate
        totalLabel.text = stock.totalIssued
    }
    
    @objc private func detailButtonTapped() {
        guard let stock = stock else { return }
        onDetailTapped?(stock)
    }
}

