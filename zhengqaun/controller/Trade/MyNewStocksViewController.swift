//
//  MyNewStocksViewController.swift
//  zhengqaun
//
//  我的新股：三 Tab（申购中/中签/未中签），对齐安卓 MyIpoActivity + MyIpoAdapter
//

import UIKit

/// 新股状态
enum NewStockStatus: String {
    case subscribing = "0"  // 申购中
    case successful = "1"   // 中签
    case unsuccessful = "2" // 未中签
    case abandoned = "3"    // 已弃购
}

/// 新股模型（对齐安卓 MyIpoItem）
struct NewStock {
    let id: String
    let name: String
    let code: String
    let status: NewStockStatus
    let statusText: String       // 后端 status_txt
    let issuePrice: Double       // 发行价 sg_fx_price
    let quantity: Int            // 数量(股) zq_num
    let lots: Int                // 中签手数 zq_nums
    let listingDate: String      // 上市时间 sg_ss_date
    let hasListingDate: Bool     // sg_ss_tag == 1
    let paidAmount: Double       // 中签金额 zq_money
    let remainRenjiao: Double    // 剩余认缴 sy_renjiao
    let date: String             // createtime_txt
}

class MyNewStocksViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let tabContainer = UIView()
    private var tabButtons: [UIButton] = []
    private var selectedTabIndex: Int = 0 // 对齐安卓：默认选中"申购中"
    var initialTab: Int = 0 // 外部可设置默认 Tab（0=申购中, 1=中签, 2=未中签）
    private var stocks: [NewStock] = []
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private let themeRed = UIColor(red: 226/255, green: 60/255, blue: 57/255, alpha: 1.0) // 对齐安卓 #E23C39
    private let grayColor = UIColor(red: 109/255, green: 109/255, blue: 109/255, alpha: 1.0) // 对齐安卓 #6D6D6D
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedTabIndex = initialTab
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navTitle = "我的新股"
        gk_navBackgroundColor = .white
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_statusBarStyle = .default
        gk_backStyle = .black
    }
    
    private func setupUI() {
        view.backgroundColor = Constants.Color.backgroundMain
        
        // Tab 栏（对齐安卓：白色背景 + 12dp padding + 等分按钮）
        tabContainer.backgroundColor = .white
        view.addSubview(tabContainer)
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let tabStackView = UIStackView()
        tabStackView.axis = .horizontal
        tabStackView.distribution = .fillEqually
        tabStackView.spacing = 12
        tabContainer.addSubview(tabStackView)
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let tabs = ["申购中", "中签", "未中签"]
        for (index, tabTitle) in tabs.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(tabTitle, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            button.layer.cornerRadius = 4
            button.layer.borderWidth = 1
            button.tag = index
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            tabStackView.addArrangedSubview(button)
            tabButtons.append(button)
        }
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(NewStockCell.self, forCellReuseIdentifier: "NewStockCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 空状态
        emptyLabel.text = "暂无数据"
        emptyLabel.textColor = Constants.Color.textSecondary
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tabContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabContainer.heightAnchor.constraint(equalToConstant: 56),
            
            tabStackView.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor, constant: 12),
            tabStackView.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor, constant: -12),
            tabStackView.heightAnchor.constraint(equalToConstant: 32),
            
            tableView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        updateTabSelection()
    }
    
    private func loadData() {
        let statusParam = "\(selectedTabIndex)"
        
        // 对齐安卓：加载时显示 loading
        loadingIndicator.startAnimating()
        emptyLabel.isHidden = true
        tableView.isHidden = false
        
        SecureNetworkManager.shared.request(
            api: "/api/subscribe/getsgnewgu0",
            method: .get,
            params: ["status": statusParam, "page": "1", "size": "50"]
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
            }
            
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["dxlog_list"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.stocks = []
                        self.tableView.reloadData()
                        self.tableView.isHidden = true
                        self.emptyLabel.isHidden = false
                    }
                    return
                }
                
                var newStocks: [NewStock] = []
                for item in list {
                    let idVal = "\(item["id"] ?? "")"
                    let name = item["name"] as? String ?? ""
                    let code = item["code"] as? String ?? ""
                    let statusStr = "\(item["status"] ?? "")"
                    let statusText = item["status_txt"] as? String ?? ""
                    
                    // 对齐安卓：发行价 Double
                    let issuePrice: Double
                    if let d = item["sg_fx_price"] as? Double {
                        issuePrice = d
                    } else if let n = item["sg_fx_price"] as? NSNumber {
                        issuePrice = n.doubleValue
                    } else if let s = item["sg_fx_price"] as? String, let d = Double(s) {
                        issuePrice = d
                    } else {
                        issuePrice = 0.0
                    }
                    
                    let zqNum = item["zq_num"] as? Int ?? (Int("\(item["zq_num"] ?? "0")") ?? 0)
                    let zqNums = item["zq_nums"] as? Int ?? (Int("\(item["zq_nums"] ?? "0")") ?? 0)
                    
                    let sgSsDate = item["sg_ss_date"] as? String ?? ""
                    let sgSsTag = item["sg_ss_tag"] as? Int ?? (Int("\(item["sg_ss_tag"] ?? "0")") ?? 0)
                    
                    let zqMoney: Double
                    if let d = item["zq_money"] as? Double {
                        zqMoney = d
                    } else if let n = item["zq_money"] as? NSNumber {
                        zqMoney = n.doubleValue
                    } else if let s = item["zq_money"] as? String, let d = Double(s) {
                        zqMoney = d
                    } else {
                        zqMoney = 0.0
                    }
                    
                    let syRenjiao: Double
                    if let d = item["sy_renjiao"] as? Double {
                        syRenjiao = d
                    } else if let n = item["sy_renjiao"] as? NSNumber {
                        syRenjiao = n.doubleValue
                    } else if let s = item["sy_renjiao"] as? String, let d = Double(s) {
                        syRenjiao = d
                    } else {
                        syRenjiao = 0.0
                    }
                    
                    let dateStr = item["createtime_txt"] as? String ?? ""
                    
                    // 对齐安卓：上市时间处理
                    let listingDate: String
                    if sgSsTag == 1 && !sgSsDate.isEmpty && sgSsDate != "0000-00-00" {
                        listingDate = sgSsDate
                    } else {
                        listingDate = "未公布"
                    }
                    
                    let model = NewStock(
                        id: idVal,
                        name: name,
                        code: code,
                        status: NewStockStatus(rawValue: statusStr) ?? .subscribing,
                        statusText: statusText,
                        issuePrice: issuePrice,
                        quantity: zqNum,
                        lots: zqNums,
                        listingDate: listingDate,
                        hasListingDate: sgSsTag == 1,
                        paidAmount: zqMoney,
                        remainRenjiao: syRenjiao,
                        date: dateStr
                    )
                    newStocks.append(model)
                }
                
                DispatchQueue.main.async {
                    self.stocks = newStocks
                    self.tableView.reloadData()
                    if newStocks.isEmpty {
                        self.tableView.isHidden = true
                        self.emptyLabel.isHidden = false
                    } else {
                        self.tableView.isHidden = false
                        self.emptyLabel.isHidden = true
                    }
                }
                
            case .failure(let err):
                DispatchQueue.main.async {
                    self.stocks = []
                    self.tableView.reloadData()
                    self.tableView.isHidden = true
                    self.emptyLabel.isHidden = false
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
        loadData()
    }
    
    private func updateTabSelection() {
        for (index, button) in tabButtons.enumerated() {
            if index == selectedTabIndex {
                // 对齐安卓：选中红色粗体 + 红色边框 + 淡红背景
                button.setTitleColor(themeRed, for: .normal)
                button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
                button.layer.borderColor = themeRed.cgColor
                button.backgroundColor = themeRed.withAlphaComponent(0.08)
            } else {
                // 对齐安卓：未选中灰色 + 灰色边框
                button.setTitleColor(grayColor, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
                button.layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor
                button.backgroundColor = .white
            }
        }
    }
    
    // MARK: - 认缴操作
    private func handleRenjiao(stock: NewStock) {
        let alert = UIAlertController(title: "确认认缴", message: "确定要认缴「\(stock.name)」吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "认缴", style: .default) { [weak self] _ in
            self?.performRenjiao(stockId: stock.id)
        })
        present(alert, animated: true)
    }
    
    private func performRenjiao(stockId: String) {
        loadingIndicator.startAnimating()
        SecureNetworkManager.shared.request(
            api: "/api/subscribe/renjiao_act",
            method: .post,
            params: ["id": Int(stockId) ?? 0]
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                switch result {
                case .success(let res):
                    if let dict = res.decrypted, let code = dict["code"] as? NSNumber, code == 1 {
                        Toast.show("认缴成功")
                        self.loadData()
                    } else {
                        let msg = (res.decrypted?["msg"] as? String) ?? "认缴失败，请重试"
                        Toast.show(msg)
                    }
                case .failure:
                    Toast.show("认缴失败，请重试")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension MyNewStocksViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewStockCell", for: indexPath) as! NewStockCell
        let stock = stocks[indexPath.row]
        cell.configure(with: stock)
        cell.onRenjiaoTapped = { [weak self] in
            self?.handleRenjiao(stock: stock)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
}

// MARK: - Cell（对齐安卓 item_my_ipo.xml 布局）
class NewStockCell: UITableViewCell {
    
    // Row 1 - 名称 + 状态
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    
    // Row 2 - 代码 + 日期
    private let codeLabel = UILabel()
    private let dateLabel = UILabel()
    
    // Row 3 - 发行价 + 数量(股)（4列平分）
    private let priceTitleLabel = UILabel()
    private let priceValueLabel = UILabel()
    private let qtyTitleLabel = UILabel()
    private let qtyValueLabel = UILabel()
    
    // Row 4 - 上市时间 + 已认缴（4列平分）
    private let listingTitleLabel = UILabel()
    private let listingValueLabel = UILabel()
    private let paidTitleLabel = UILabel()
    private let paidValueLabel = UILabel()
    
    // 认缴按钮
    private let renjiaoButton = UIButton(type: .system)
    
    // 分割线
    private let separator = UIView()
    
    var onRenjiaoTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        
        let textBlack = UIColor(red: 0x30/255, green: 0x30/255, blue: 0x30/255, alpha: 1.0)
        let textGray = UIColor(red: 0x99/255, green: 0x99/255, blue: 0x99/255, alpha: 1.0)
        
        // Row 1
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = .black
        contentView.addSubview(nameLabel)
        
        statusLabel.font = UIFont.systemFont(ofSize: 13)
        statusLabel.textColor = Constants.Color.stockRise
        statusLabel.textAlignment = .right
        contentView.addSubview(statusLabel)
        
        // Row 2
        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = textGray
        contentView.addSubview(codeLabel)
        
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = textGray
        dateLabel.textAlignment = .right
        contentView.addSubview(dateLabel)
        
        // Row 3 标题
        priceTitleLabel.text = "发行价"
        priceTitleLabel.font = UIFont.systemFont(ofSize: 12)
        priceTitleLabel.textColor = textGray
        contentView.addSubview(priceTitleLabel)
        
        priceValueLabel.font = UIFont.systemFont(ofSize: 12)
        priceValueLabel.textColor = .black
        contentView.addSubview(priceValueLabel)
        
        qtyTitleLabel.text = "数量(股)"
        qtyTitleLabel.font = UIFont.systemFont(ofSize: 12)
        qtyTitleLabel.textColor = textGray
        contentView.addSubview(qtyTitleLabel)
        
        qtyValueLabel.font = UIFont.systemFont(ofSize: 12)
        qtyValueLabel.textColor = .black
        qtyValueLabel.textAlignment = .right
        contentView.addSubview(qtyValueLabel)
        
        // Row 4 标题
        listingTitleLabel.text = "上市时间"
        listingTitleLabel.font = UIFont.systemFont(ofSize: 12)
        listingTitleLabel.textColor = textGray
        contentView.addSubview(listingTitleLabel)
        
        listingValueLabel.font = UIFont.systemFont(ofSize: 12)
        listingValueLabel.textColor = .black
        contentView.addSubview(listingValueLabel)
        
        paidTitleLabel.text = "已认缴"
        paidTitleLabel.font = UIFont.systemFont(ofSize: 12)
        paidTitleLabel.textColor = textGray
        contentView.addSubview(paidTitleLabel)
        
        paidValueLabel.font = UIFont.systemFont(ofSize: 12)
        paidValueLabel.textColor = .black
        paidValueLabel.textAlignment = .right
        contentView.addSubview(paidValueLabel)
        
        // 认缴按钮（对齐安卓 btn_renjiao）
        renjiaoButton.setTitle("去认缴", for: .normal)
        renjiaoButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        renjiaoButton.setTitleColor(.white, for: .normal)
        renjiaoButton.backgroundColor = UIColor(red: 226/255, green: 60/255, blue: 57/255, alpha: 1.0)
        renjiaoButton.layer.cornerRadius = 4
        renjiaoButton.isHidden = true
        renjiaoButton.addTarget(self, action: #selector(renjiaoTapped), for: .touchUpInside)
        contentView.addSubview(renjiaoButton)
        
        // 分割线
        separator.backgroundColor = UIColor(white: 0.93, alpha: 1.0)
        contentView.addSubview(separator)
        
        for v in contentView.subviews { v.translatesAutoresizingMaskIntoConstraints = false }
        
        let pad: CGFloat = 16
        let screenW = UIScreen.main.bounds.width - pad * 2
        let colW = screenW / 4
        
        NSLayoutConstraint.activate([
            // Row 1：名称(左) + 状态(右)
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
            
            statusLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            // Row 2：代码(左) + 日期(右)
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            
            dateLabel.centerYAnchor.constraint(equalTo: codeLabel.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            // Row 3：4列平分 - 发行价(标签) + 发行价(值) + 数量(标签) + 数量(值)
            priceTitleLabel.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 8),
            priceTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            priceTitleLabel.widthAnchor.constraint(equalToConstant: colW),
            
            priceValueLabel.centerYAnchor.constraint(equalTo: priceTitleLabel.centerYAnchor),
            priceValueLabel.leadingAnchor.constraint(equalTo: priceTitleLabel.trailingAnchor),
            priceValueLabel.widthAnchor.constraint(equalToConstant: colW),
            
            qtyTitleLabel.centerYAnchor.constraint(equalTo: priceTitleLabel.centerYAnchor),
            qtyTitleLabel.leadingAnchor.constraint(equalTo: priceValueLabel.trailingAnchor),
            qtyTitleLabel.widthAnchor.constraint(equalToConstant: colW),
            
            qtyValueLabel.centerYAnchor.constraint(equalTo: priceTitleLabel.centerYAnchor),
            qtyValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            // Row 4：4列平分 - 上市时间(标签) + 上市时间(值) + 已认缴(标签) + 认缴金额(值)
            listingTitleLabel.topAnchor.constraint(equalTo: priceTitleLabel.bottomAnchor, constant: 8),
            listingTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            listingTitleLabel.widthAnchor.constraint(equalToConstant: colW),
            
            listingValueLabel.centerYAnchor.constraint(equalTo: listingTitleLabel.centerYAnchor),
            listingValueLabel.leadingAnchor.constraint(equalTo: listingTitleLabel.trailingAnchor),
            listingValueLabel.widthAnchor.constraint(equalToConstant: colW),
            
            paidTitleLabel.centerYAnchor.constraint(equalTo: listingTitleLabel.centerYAnchor),
            paidTitleLabel.leadingAnchor.constraint(equalTo: listingValueLabel.trailingAnchor),
            paidTitleLabel.widthAnchor.constraint(equalToConstant: colW),
            
            paidValueLabel.centerYAnchor.constraint(equalTo: listingTitleLabel.centerYAnchor),
            paidValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            // 认缴按钮
            renjiaoButton.topAnchor.constraint(equalTo: listingTitleLabel.bottomAnchor, constant: 8),
            renjiaoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            renjiaoButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),
            renjiaoButton.heightAnchor.constraint(equalToConstant: 32),
            
            // 分割线
            separator.topAnchor.constraint(equalTo: renjiaoButton.bottomAnchor, constant: 12),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    @objc private func renjiaoTapped() {
        onRenjiaoTapped?()
    }
    
    func configure(with stock: NewStock) {
        nameLabel.text = stock.name
        codeLabel.text = stock.code
        dateLabel.text = stock.date
        
        // 对齐安卓：状态文字
        if !stock.statusText.isEmpty {
            statusLabel.text = stock.statusText
        } else {
            switch stock.status {
            case .subscribing:
                statusLabel.text = "申购中"
            case .successful:
                statusLabel.text = "中签\(stock.lots)(手)"
            case .unsuccessful:
                statusLabel.text = "未中签"
            case .abandoned:
                statusLabel.text = "已弃购"
            }
        }
        
        // 对齐安卓：状态颜色（中签红色，其他灰色）
        if stock.status == .successful {
            statusLabel.textColor = Constants.Color.stockRise
        } else {
            statusLabel.textColor = Constants.Color.textSecondary
        }
        
        // 发行价
        priceValueLabel.text = String(format: "%.2f", stock.issuePrice)
        
        // 数量(股)
        qtyValueLabel.text = "\(stock.quantity)"
        
        // 上市时间
        listingValueLabel.text = stock.listingDate
        
        // 对齐安卓：已认缴 / 剩余认缴
        if stock.remainRenjiao > 0 {
            paidTitleLabel.text = "剩余认缴"
            paidValueLabel.text = String(format: "%.2f", stock.remainRenjiao)
        } else {
            paidTitleLabel.text = "已认缴"
            paidValueLabel.text = String(format: "%.2f", stock.paidAmount)
        }
        
        // 对齐安卓：认缴按钮（中签 + 剩余认缴 > 0 时显示）
        if stock.status == .successful && stock.remainRenjiao > 0 {
            renjiaoButton.isHidden = false
        } else {
            renjiaoButton.isHidden = true
        }
    }
}
