//
//  AllotmentRecordsViewController.swift
//  zhengqaun
//
//  配售记录：入口为个人中心的"配售记录"按钮
//

import UIKit

/// 配售记录数据模型
struct AllotmentRecord {
    let exchange: String  // "深"、"沪"等
    let stockName: String // 公司名
    let stockCode: String // 代码
    let issuePrice: String // 发行价格 "¥ 21.93"
    let allotmentRate: String // 中签率 "0.00%"
    let totalIssued: String // 发行总数 "3671.6万股"
}

class AllotmentRecordsViewController: ZQViewController {
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
        gk_navTitle = "配售记录"
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
            api: "/api/subscribe/getsgnewgu",
            method: .get,
            params: ["status": statusParam,"page": "1", "size": "50"]
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
extension AllotmentRecordsViewController: UITableViewDataSource {
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
extension AllotmentRecordsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
}
