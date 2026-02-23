//
//  MyNewStocksViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// 新股状态
enum NewStockStatus: String {
    case subscribing = "0"  // 申购中
    case successful = "1"   // 中签
    case unsuccessful = "2" // 未中签
}

/// 新股模型
struct NewStock {
    let id: String
    let name: String
    let code: String
    let status: NewStockStatus
    let statusText: String  // 后端返回的明确状态文本
    let issuePrice: String
    let quantity: String // 数量(股)
    let lots: String? // 中签手数
    let listingTime: String // 上市时间
    let paidAmount: String? // 已认缴金额/中签金额
    let date: String
}

class MyNewStocksViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let tabContainer = UIView()
    private var tabButtons: [UIButton] = []
    private let indicatorView = UIView()
    private var selectedTabIndex: Int = 1 // 默认选中"中签"
    private var stocks: [NewStock] = []
    private var indicatorCenterXConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navTitle = "我的新股"
        gk_navBackgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // #1976D2
        gk_navTitleColor = .white
        gk_statusBarStyle = .lightContent
    }
    
    private func setupUI() {
        view.backgroundColor = Constants.Color.backgroundMain
        
        // Tab栏
        tabContainer.backgroundColor = .white
        view.addSubview(tabContainer)
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let tabs = ["申购中", "中签", "未中签"]
        let tabStackView = UIStackView()
        tabStackView.axis = .horizontal
        tabStackView.distribution = .fillEqually
        tabStackView.spacing = 0
        tabContainer.addSubview(tabStackView)
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for (index, tabTitle) in tabs.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(tabTitle, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            button.tag = index
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            tabStackView.addArrangedSubview(button)
            tabButtons.append(button)
        }
        
        // 指示器
        indicatorView.backgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // 蓝色
        tabContainer.addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = Constants.Color.backgroundMain
        tableView.register(NewStockCell.self, forCellReuseIdentifier: "NewStockCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tabContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabContainer.heightAnchor.constraint(equalToConstant: 44),
            
            tabStackView.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            tabStackView.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
            tabStackView.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            
            indicatorView.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: 2),
            indicatorView.widthAnchor.constraint(equalToConstant: 20),
            
            tableView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // 设置指示器初始位置（确保tabButtons已经填充）
        guard !tabButtons.isEmpty && selectedTabIndex < tabButtons.count else {
            return
        }
        indicatorCenterXConstraint = indicatorView.centerXAnchor.constraint(equalTo: tabButtons[selectedTabIndex].centerXAnchor)
        indicatorCenterXConstraint.isActive = true
        
        updateTabSelection()
    }
    
    private func loadData() {
        let statusParam: String
        switch selectedTabIndex {
        case 0: statusParam = "0"
        case 1: statusParam = "1"
        case 2: statusParam = "2"
        default: statusParam = "1"
        }
        
        SecureNetworkManager.shared.request(
            api: "/api/subscribe/getsgnewgu0",
            method: .get,
            params: ["status": statusParam]
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["dxlog_list"] as? [[String: Any]] else {
                    if let dict = res.decrypted {
                        print("==== 我的新股接口响应数据 ====\n\(dict)\n====================")
                    }
                    DispatchQueue.main.async {
                        self.stocks = []
                        self.tableView.reloadData()
                    }
                    return
                }
                
                print("==== 我的新股接口响应数据 ====\n\(dict)\n====================")
                
                var newStocks: [NewStock] = []
                for item in list {
                    let idVal = "\(item["id"] ?? "")"
                    let name = item["name"] as? String ?? ""
                    let code = item["code"] as? String ?? ""
                    let statusStr = "\(item["status"] ?? "")"
                    let statusText = item["status_txt"] as? String ?? ""
                    let issuePrice = "\(item["sg_fx_price"] ?? "0")"
                    let quantity = "\(item["zq_num"] ?? "0")"
                    let lots = "\(item["zq_nums"] ?? "0")"
                    var listingTime = item["sg_ss_date"] as? String ?? "未公布"
                    if listingTime.isEmpty { listingTime = "未公布" }
                    let zqMoney = "\(item["zq_money"] ?? "0")"
                    let dateStr = item["createtime_txt"] as? String ?? ""
                    
                    let model = NewStock(
                        id: idVal,
                        name: name,
                        code: code,
                        status: NewStockStatus(rawValue: statusStr) ?? .successful,
                        statusText: statusText,
                        issuePrice: issuePrice,
                        quantity: quantity,
                        lots: lots,
                        listingTime: listingTime,
                        paidAmount: zqMoney,
                        date: dateStr
                    )
                    newStocks.append(model)
                }
                
                DispatchQueue.main.async {
                    self.stocks = newStocks
                    self.tableView.reloadData()
                }
                
            case .failure(let err):
                DispatchQueue.main.async {
                    Toast.show("获取记录失败: \(err.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let newIndex = sender.tag
        guard newIndex != selectedTabIndex else { return }
        
        selectedTabIndex = newIndex
        updateTabSelection()
        
        // 重新调用接口拉取数据
        loadData()
    }
    
    private func updateTabSelection() {
        // 安全检查
        guard !tabButtons.isEmpty && selectedTabIndex < tabButtons.count else {
            return
        }
        
        for (index, button) in tabButtons.enumerated() {
            if index == selectedTabIndex {
                button.setTitleColor(UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0), for: .normal)
                // 去掉边框
                button.layer.borderWidth = 0
            } else {
                button.setTitleColor(Constants.Color.textSecondary, for: .normal)
                button.layer.borderWidth = 0
            }
        }
        
        // 更新指示器位置
        if indicatorCenterXConstraint != nil {
            indicatorCenterXConstraint.isActive = false
        }
        indicatorCenterXConstraint = indicatorView.centerXAnchor.constraint(equalTo: tabButtons[selectedTabIndex].centerXAnchor)
        indicatorCenterXConstraint.isActive = true
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource
extension MyNewStocksViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewStockCell", for: indexPath) as! NewStockCell
        cell.configure(with: stocks[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MyNewStocksViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
}

// MARK: - NewStockCell
class NewStockCell: UITableViewCell {
    
    private let containerView = UIView()
    private let stockNameLabel = UILabel()
    private let stockCodeLabel = UILabel()
    private let statusLabel = UILabel()
    private let issuePriceLabel = UILabel()
    private let issuePriceValueLabel = UILabel()
    private let quantityLabel = UILabel()
    private let quantityValueLabel = UILabel()
    private let listingTimeLabel = UILabel()
    private let listingTimeValueLabel = UILabel()
    private let paidLabel = UILabel()
    private let paidValueLabel = UILabel()
    private let separatorLine = UIView()
    private let dateLabel = UILabel()
    
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
        
        // 第一行：股票名称 + 代码 + 状态
        stockNameLabel.font = UIFont.boldSystemFont(ofSize: 17)
        stockNameLabel.textColor = Constants.Color.textPrimary
        containerView.addSubview(stockNameLabel)
        stockNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stockCodeLabel.font = UIFont.systemFont(ofSize: 13)
        stockCodeLabel.textColor = Constants.Color.textSecondary
        containerView.addSubview(stockCodeLabel)
        stockCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusLabel.font = UIFont.systemFont(ofSize: 13)
        statusLabel.textColor = UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0) // 橙色
        statusLabel.textAlignment = .right
        containerView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 第二行：发行价 + 数量
        issuePriceLabel.text = "发行价"
        issuePriceLabel.font = UIFont.systemFont(ofSize: 13)
        issuePriceLabel.textColor = Constants.Color.textSecondary
        containerView.addSubview(issuePriceLabel)
        issuePriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        issuePriceValueLabel.font = UIFont.boldSystemFont(ofSize: 17)
        issuePriceValueLabel.textColor = Constants.Color.textPrimary
        containerView.addSubview(issuePriceValueLabel)
        issuePriceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        quantityLabel.text = "数量(股)"
        quantityLabel.font = UIFont.systemFont(ofSize: 13)
        quantityLabel.textColor = Constants.Color.textSecondary
        quantityLabel.textAlignment = .right
        containerView.addSubview(quantityLabel)
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        quantityValueLabel.font = UIFont.boldSystemFont(ofSize: 17)
        quantityValueLabel.textColor = Constants.Color.textPrimary
        quantityValueLabel.textAlignment = .right
        containerView.addSubview(quantityValueLabel)
        quantityValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 第三行：上市时间 + 已认缴
        listingTimeLabel.text = "上市时间"
        listingTimeLabel.font = UIFont.systemFont(ofSize: 13)
        listingTimeLabel.textColor = Constants.Color.textSecondary
        containerView.addSubview(listingTimeLabel)
        listingTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        listingTimeValueLabel.font = UIFont.systemFont(ofSize: 13)
        listingTimeValueLabel.textColor = Constants.Color.textSecondary
        containerView.addSubview(listingTimeValueLabel)
        listingTimeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        paidLabel.text = "已认缴"
        paidLabel.font = UIFont.systemFont(ofSize: 13)
        paidLabel.textColor = Constants.Color.textSecondary
        paidLabel.textAlignment = .right
        containerView.addSubview(paidLabel)
        paidLabel.translatesAutoresizingMaskIntoConstraints = false
        
        paidValueLabel.font = UIFont.boldSystemFont(ofSize: 17)
        paidValueLabel.textColor = Constants.Color.textPrimary
        paidValueLabel.textAlignment = .right
        containerView.addSubview(paidValueLabel)
        paidValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 分隔线
        separatorLine.backgroundColor = Constants.Color.separator
        containerView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 日期
        dateLabel.font = UIFont.systemFont(ofSize: 11)
        dateLabel.textColor = Constants.Color.textSecondary
        containerView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // 第一行：股票名称 + 代码 + 状态
            stockNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stockNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            stockCodeLabel.leadingAnchor.constraint(equalTo: stockNameLabel.trailingAnchor, constant: 6),
            stockCodeLabel.centerYAnchor.constraint(equalTo: stockNameLabel.centerYAnchor),
            
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: stockNameLabel.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: stockCodeLabel.trailingAnchor, constant: 12),
            
            // 第二行：发行价 + 数量(股)
            issuePriceLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: 16),
            issuePriceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            issuePriceValueLabel.topAnchor.constraint(equalTo: issuePriceLabel.bottomAnchor, constant: 6),
            issuePriceValueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            quantityLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: 16),
            quantityLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            quantityValueLabel.topAnchor.constraint(equalTo: quantityLabel.bottomAnchor, constant: 6),
            quantityValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // 第三行：上市时间 + 已认缴
            listingTimeLabel.topAnchor.constraint(equalTo: issuePriceValueLabel.bottomAnchor, constant: 16),
            listingTimeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            listingTimeValueLabel.topAnchor.constraint(equalTo: listingTimeLabel.bottomAnchor, constant: 6),
            listingTimeValueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            paidLabel.topAnchor.constraint(equalTo: quantityValueLabel.bottomAnchor, constant: 16),
            paidLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            paidValueLabel.topAnchor.constraint(equalTo: paidLabel.bottomAnchor, constant: 6),
            paidValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // 分隔线
            separatorLine.topAnchor.constraint(equalTo: listingTimeValueLabel.bottomAnchor, constant: 16),
            separatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            separatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separatorLine.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            
            // 日期
            dateLabel.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            dateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with stock: NewStock) {
        stockNameLabel.text = stock.name
        stockCodeLabel.text = stock.code
        
        statusLabel.text = stock.statusText.isEmpty ? (stock.status == .subscribing ? "申购中" : (stock.status == .successful ? "中签" : "未中签")) : stock.statusText
        
        // 未中签不展示深色高亮状态
        if stock.status == .unsuccessful {
            statusLabel.textColor = Constants.Color.textSecondary
        } else {
            statusLabel.textColor = UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0)
        }
        
        issuePriceValueLabel.text = stock.issuePrice
        quantityValueLabel.text = stock.quantity
        listingTimeValueLabel.text = stock.listingTime
        
        if let paidAmount = stock.paidAmount, !paidAmount.isEmpty && paidAmount != "0" {
            paidValueLabel.text = paidAmount
            paidLabel.isHidden = false
            paidValueLabel.isHidden = false
        } else {
            paidLabel.isHidden = true
            paidValueLabel.isHidden = true
        }
        
        dateLabel.text = stock.date
    }
}

