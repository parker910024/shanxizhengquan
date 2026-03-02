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
    private var selectedTabIndex: Int = 0 // 默认选中"申购中"
    private var stocks: [NewStock] = []
    private let emptyLabel = UILabel()
    
    private let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    private let grayColor = Constants.Color.textSecondary
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navTitle = "配售记录"
        gk_navBackgroundColor = .white
        gk_navTitleColor = Constants.Color.textPrimary
        gk_statusBarStyle = .default
        gk_backStyle = .black
    }
    
    private let indicatorView = UIView()
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    
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
        tabStackView.spacing = 10
        tabContainer.addSubview(tabStackView)
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for (index, tabTitle) in tabs.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(tabTitle, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            button.layer.cornerRadius = 4
            button.layer.borderWidth = 1 / UIScreen.main.scale
            button.tag = index
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            tabStackView.addArrangedSubview(button)
            tabButtons.append(button)
        }
        
        // 底部细线
        let bottomLine = UIView()
        bottomLine.backgroundColor = Constants.Color.separator
        tabContainer.addSubview(bottomLine)
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = Constants.Color.backgroundMain
        tableView.register(MyPlacementCell.self, forCellReuseIdentifier: "MyPlacementCell")
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
        
        indicatorLeadingConstraint = indicatorView.centerXAnchor.constraint(equalTo: tabButtons[selectedTabIndex].centerXAnchor)
        
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tabContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabContainer.heightAnchor.constraint(equalToConstant: 44),
            
            tabStackView.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor, constant: 16),
            tabStackView.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor, constant: -16),
            tabStackView.heightAnchor.constraint(equalToConstant: 28),
            
            bottomLine.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            
            tableView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
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
                    DispatchQueue.main.async {
                        self.stocks = []
                        self.tableView.reloadData()
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
                    
                    // 对齐新模型字段类型
                    let issuePrice: Double
                    if let d = item["sg_fx_price"] as? Double { issuePrice = d }
                    else if let n = item["sg_fx_price"] as? NSNumber { issuePrice = n.doubleValue }
                    else if let s = item["sg_fx_price"] as? String, let d = Double(s) { issuePrice = d }
                    else { issuePrice = 0.0 }
                    
                    let zqNum = item["zq_num"] as? Int ?? (Int("\(item["zq_num"] ?? "0")") ?? 0)
                    let zqNums = item["zq_nums"] as? Int ?? (Int("\(item["zq_nums"] ?? "0")") ?? 0)
                    
                    let sgSsDate = item["sg_ss_date"] as? String ?? ""
                    let sgSsTag = item["sg_ss_tag"] as? Int ?? (Int("\(item["sg_ss_tag"] ?? "0")") ?? 0)
                    let listingDate = (sgSsTag == 1 && !sgSsDate.isEmpty && sgSsDate != "0000-00-00") ? sgSsDate : "未公布"
                    
                    let zqMoney: Double
                    if let d = item["money"] as? Double { zqMoney = d }
                    else if let n = item["money"] as? NSNumber { zqMoney = n.doubleValue }
                    else if let s = item["money"] as? String, let d = Double(s) { zqMoney = d }
                    else { zqMoney = 0.0 }
                    
                    let syRenjiao: Double
                    if let d = item["sy_renjiao"] as? Double { syRenjiao = d }
                    else if let n = item["sy_renjiao"] as? NSNumber { syRenjiao = n.doubleValue }
                    else if let s = item["sy_renjiao"] as? String, let d = Double(s) { syRenjiao = d }
                    else { syRenjiao = 0.0 }
                    
                    let dateStr = item["createtime_txt"] as? String ?? ""
                    
                    let model = NewStock(
                        id: idVal,
                        name: name,
                        code: code,
                        status: NewStockStatus(rawValue: statusStr) ?? .successful,
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
                    self.emptyLabel.isHidden = !newStocks.isEmpty
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
        loadData()
    }
    
    private func updateTabSelection() {
        for (index, button) in tabButtons.enumerated() {
            if index == selectedTabIndex {
                button.setTitleColor(themeRed, for: .normal)
                button.layer.borderColor = themeRed.cgColor
                button.backgroundColor = themeRed.withAlphaComponent(0.08)
            } else {
                button.setTitleColor(grayColor, for: .normal)
                button.layer.borderColor = Constants.Color.separator.cgColor
                button.backgroundColor = .clear
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension AllotmentRecordsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyPlacementCell", for: indexPath) as! MyPlacementCell
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

// MARK: - 自定义配售记录 Cell (对齐安卓 MyPlacementAdapter)
class MyPlacementCell: UITableViewCell {
    
    // UI Elements
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let statusLabel = UILabel()
    
    private let priceTitleLabel = UILabel()
    private let priceValueLabel = UILabel()
    
    private let qtyTitleLabel = UILabel()
    private let qtyValueLabel = UILabel()
    
    private let listingTitleLabel = UILabel()
    private let listingValueLabel = UILabel()
    
    private let moneyTitleLabel = UILabel()
    private let moneyValueLabel = UILabel()
    
    private let dateLabel = UILabel()
    private let separator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white
        
        let grayColor = Constants.Color.textSecondary
        let valueColor = UIColor.black
        let titleFont = UIFont.systemFont(ofSize: 13)
        let valueFont = UIFont.boldSystemFont(ofSize: 14)
        
        // --- Row 1: Name + Code (Left), Status (Right) ---
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(nameLabel)
        
        codeLabel.font = UIFont.systemFont(ofSize: 13)
        codeLabel.textColor = grayColor
        contentView.addSubview(codeLabel)
        
        statusLabel.font = UIFont.boldSystemFont(ofSize: 14)
        statusLabel.textColor = Constants.Color.stockRise
        statusLabel.textAlignment = .right
        contentView.addSubview(statusLabel)
        
        // --- Row 2: 发行价 (Left Half), 数量(股) (Right Half) ---
        let row2Left = UIStackView()
        row2Left.axis = .vertical
        row2Left.spacing = 2
        
        priceTitleLabel.text = "发行价"
        priceTitleLabel.font = titleFont
        priceTitleLabel.textColor = grayColor
        
        priceValueLabel.font = valueFont
        priceValueLabel.textColor = valueColor
        
        row2Left.addArrangedSubview(priceTitleLabel)
        row2Left.addArrangedSubview(priceValueLabel)
        contentView.addSubview(row2Left)
        
        let row2Right = UIStackView()
        row2Right.axis = .vertical
        row2Right.spacing = 2
        
        qtyTitleLabel.text = "数量(股)"
        qtyTitleLabel.font = titleFont
        qtyTitleLabel.textColor = grayColor
        
        qtyValueLabel.font = valueFont
        qtyValueLabel.textColor = valueColor
        
        row2Right.addArrangedSubview(qtyTitleLabel)
        row2Right.addArrangedSubview(qtyValueLabel)
        contentView.addSubview(row2Right)
        
        // --- Row 3: 上市时间 (Left Half), 占用金额 (Right Half) ---
        let row3Left = UIStackView()
        row3Left.axis = .vertical
        row3Left.spacing = 2
        
        listingTitleLabel.text = "上市时间"
        listingTitleLabel.font = titleFont
        listingTitleLabel.textColor = grayColor
        
        listingValueLabel.font = valueFont
        listingValueLabel.textColor = valueColor
        
        row3Left.addArrangedSubview(listingTitleLabel)
        row3Left.addArrangedSubview(listingValueLabel)
        contentView.addSubview(row3Left)
        
        let row3Right = UIStackView()
        row3Right.axis = .vertical
        row3Right.spacing = 2
        
        moneyTitleLabel.text = "占用金额"
        moneyTitleLabel.font = titleFont
        moneyTitleLabel.textColor = grayColor
        
        moneyValueLabel.font = valueFont
        moneyValueLabel.textColor = valueColor
        
        row3Right.addArrangedSubview(moneyTitleLabel)
        row3Right.addArrangedSubview(moneyValueLabel)
        contentView.addSubview(row3Right)
        
        // --- Row 4: Bottom Date ---
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = grayColor
        contentView.addSubview(dateLabel)
        
        separator.backgroundColor = Constants.Color.separator
        contentView.addSubview(separator)
        
        // Disable autoresizing masks
        [nameLabel, codeLabel, statusLabel, row2Left, row2Right, row3Left, row3Right, dateLabel, separator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Row 1 constraints
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            codeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            statusLabel.centerYAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Row 2 constraints
            row2Left.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 12),
            row2Left.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row2Left.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -16),
            
            row2Right.topAnchor.constraint(equalTo: row2Left.topAnchor),
            row2Right.leadingAnchor.constraint(equalTo: row2Left.trailingAnchor),
            row2Right.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Row 3 constraints
            row3Left.topAnchor.constraint(equalTo: row2Left.bottomAnchor, constant: 10),
            row3Left.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row3Left.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -16),
            
            row3Right.topAnchor.constraint(equalTo: row3Left.topAnchor),
            row3Right.leadingAnchor.constraint(equalTo: row3Left.trailingAnchor),
            row3Right.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Row 4 constraints
            dateLabel.topAnchor.constraint(equalTo: row3Left.bottomAnchor, constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            separator.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }
    
    func configure(with model: NewStock) {
        nameLabel.text = model.name
        codeLabel.text = model.code
        statusLabel.text = model.statusText.isEmpty ? "" : model.statusText
        
        priceValueLabel.text = String(format: "%.2f", model.issuePrice)
        qtyValueLabel.text = "\(model.quantity)"
        listingValueLabel.text = model.listingDate.isEmpty ? "—" : model.listingDate
        // paidAmount 现被强转记录 money
        let moneyStr = String(format: "%.2f", model.paidAmount)
        moneyValueLabel.text = (moneyStr == "0.00" || moneyStr == "0") ? "0" : moneyStr
        dateLabel.text = model.date
    }
}
